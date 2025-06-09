## ------------------------------------------------------------------------
##
## Script name: functions.jl
## Purpose: Functions for cleaning the raw data
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Data cleaning -----------------------------------------------------------

"""
    vcat_complete_columns(dfs...) -> DataFrame

Concatenate multiple DataFrames vertically, ensuring all columns are present in the result.

For DataFrames missing certain columns, adds those columns filled with missing values.
Prints information about which DataFrames are missing which columns.

# Arguments
- `dfs...`: Two or more DataFrames to concatenate vertically

# Returns
A new DataFrame containing all rows from input DataFrames with a complete set of columns.
Missing values are used for columns not present in original DataFrames.
"""
function vcat_complete_columns(dfs...)
    # Get all unique column names across all DataFrames
    all_cols = union([names(df) for df in dfs]...)

    # Store missing columns information
    missing_cols_info = []

    # For each DataFrame, add missing columns filled with missing values
    aligned_dfs = map(enumerate(dfs)) do (idx, df)
        missing_cols = setdiff(all_cols, names(df))

        # Record missing columns for this DataFrame
        if !isempty(missing_cols)
            push!(missing_cols_info, (idx, missing_cols))

            # Print missing columns information
            println("DataFrame $idx is missing columns: ", join(missing_cols, ", "))

            return hcat(
                df,
                DataFrame(Dict(col => fill(missing, nrow(df)) for col in missing_cols))
            )
        end
        return df
    end

    # Print summary if no missing columns were found
    if isempty(missing_cols_info)
        println("All DataFrames have the same columns.")
    end

    # Vcat the aligned DataFrames
    result = vcat(aligned_dfs...)

    return result
end

"""
    create_parent_matches(sdf::DataFrame) -> DataFrame

Create matches between pairs of parents, parents-in-law, or grandparents within each household.

Takes a DataFrame `sdf` containing person records from a single household and marriage year group.
Pairs adjacent people in sorted order of their person numbers (pernum).

Returns a DataFrame with columns:
- `hhid`: Household ID
- `pernum`: Person number
- `sploc`: Person number of matched spouse

For odd numbers of people, the last person remains unmatched (sploc is missing).
"""
function create_parent_matches(sdf)
    pernums = sort(sdf.pernum)
    num_pairs = div(length(pernums), 2)
    hhid = sdf.hhid[1]
    maryr = sdf.maryr[1]
    matches = DataFrame(hhid=String[], pernum=Int[], sploc=Int[])
    for i in 1:num_pairs
        # Pair pernums[2i - 1] with pernums[2i]
        gp1 = pernums[2i-1]
        gp2 = pernums[2i]
        # Assign sploc for both parents
        push!(matches, (hhid=hhid, pernum=gp1, sploc=gp2))
        push!(matches, (hhid=hhid, pernum=gp2, sploc=gp1))
    end
    # If there's an unmatched grandparent (odd number), their 'sploc' remains missing
    return matches
end

"""
    create_children_matches(sdf::DataFrame) -> DataFrame

Create matches between children and children-in-law within each household.

Takes a DataFrame `sdf` containing person records from a single household and marriage year group.
Pairs children with children-in-law in sorted order of their person numbers (pernum).

Returns a DataFrame with columns:
- `hhid`: Household ID 
- `pernum`: Person number
- `sploc`: Person number of matched spouse

The number of matches is limited by the minimum of the number of children and children-in-law.
Any unmatched children or children-in-law will not appear in the output.
"""
function create_children_matches(sdf)
    # Extract `pernum` of children and children-in-law
    children = sort(sdf[sdf.role.=="child", :pernum])
    children_in_law = sort(sdf[sdf.role.=="child_in_law", :pernum])
    num_pairs = min(length(children), length(children_in_law))
    hhid = sdf.hhid[1]
    maryr = sdf.maryr[1]
    matches = DataFrame(hhid=String[], pernum=Int[], sploc=Int[])
    for i in 1:num_pairs
        child_pernum = children[i]
        child_in_law_pernum = children_in_law[i]
        # Assign sploc for child
        push!(matches, (hhid=hhid, pernum=child_pernum, sploc=child_in_law_pernum))
        # Assign sploc for child-in-law
        push!(matches, (hhid=hhid, pernum=child_in_law_pernum, sploc=child_pernum))
    end
    return matches
end

# Migration status in the 2000 census -------------------------------------

"""
    classify_urban(residence_type_code)
Classifies a residence type code as urban (1), rural (0), or missing.
This works for BOTH current_res_type and cn2000a_typeprev.
"""
function classify_urban(residence_type_code::Union{Int,Float64,Missing})
    # Urban: Residents' committee in town, Neighborhood in city
    residence_type_code in (2, 4) && return 2
    # Rural: Township, Village's committee in town
    residence_type_code in (1, 3) && return 1
    # Unknown or NIU
    return missing
end

"""
    get_move_year(migyr_code)
Converts the categorical migration year code from the 2000 census to a numerical year.
Returns `missing` if the code is invalid.
"""
function get_move_year(migyr_code::Union{Int,Float64,Missing})
    migyr_code == 1 && return 0       # "Since birth", effectively always lived here.
    migyr_code in (2, 3) && return 1995
    migyr_code == 4 && return 1996
    migyr_code == 5 && return 1997
    migyr_code == 6 && return 1998
    migyr_code == 7 && return 1999
    migyr_code == 8 && return 2000
    return missing # Should not happen with clean data
end

"""
    determine_urban_2000(peak_yr, migyr_code, typeprev, current_urban) -> Union{Int, Missing}
A single, universal function to determine the urban context based on a peak year.
"""
function determine_urban_2000(peak_yr, migyr_code, typeprev, current_urban)
    # If any essential piece is missing, we cannot proceed.
    (ismissing(peak_yr) || ismissing(current_urban)) && return missing

    Y_move = get_move_year(migyr_code)
    ismissing(Y_move) && return missing

    # Case 1: Relevant year is AFTER or DURING the move (or never moved).
    # Context is the CURRENT residence.
    if peak_yr >= Y_move
        return current_urban

        # Case 2: Relevant year is BEFORE the move.
        # Context is the PREVIOUS residence.
    else # peak_yr < Y_move
        # This will correctly return missing if `typeprev` is NIU (9) or Unknown (8),
        # especially for moves before Nov 1995 (migyr=2).
        return classify_urban(typeprev)
    end
end

# Migration status in the 2010 census -------------------------------------

"""
    get_years_away(code)
Converts the '离开户口登记地时间' code to a numerical duration in years.
We use the upper bound of the interval for a conservative estimate of the move year.
(e.g., "1-2 years" away means they left at most 2 years ago).
"""
function get_years_away(code::Union{Int,Float64,Missing})
    code == 1 && return 0.0  # Never left
    code == 2 && return 0.5
    code == 3 && return 1.0
    code == 4 && return 2.0
    code == 5 && return 3.0
    code == 6 && return 4.0
    code == 7 && return 5.0
    code == 8 && return 6.0
    code == 9 && return 6.0  # "6 years or more", we use 6 as the minimum duration
    return missing
end

"""
    determine_urban_2010(census_year, peak_yr, current_urban, time_away_code, hukou_type) -> Union{Int, Missing}
A single, universal function for the 2010 census data.
"""
function determine_urban_2010(census_year, peak_yr, current_urban, time_away_code, hukou_type)
    # Check for missing essential data
    (ismissing(peak_yr) || ismissing(current_urban) || ismissing(time_away_code)) && return missing

    # Case 1: Never left hukou location. Context is always the current residence.
    if time_away_code == 1
        return current_urban
    end

    # Estimate the year of departure from hukou location
    years_away = get_years_away(time_away_code)
    ismissing(years_away) && return missing
    Y_left_hukou = census_year - years_away

    # Case 2: Peak year is AFTER or DURING departure. Context is current residence.
    if peak_yr >= Y_left_hukou
        return current_urban
        # Case 3: Peak year is BEFORE departure. Context is the hukou location.
    else # peak_yr < Y_left_hukou
        return classify_urban(hukou_type)
    end
end
