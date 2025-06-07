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
