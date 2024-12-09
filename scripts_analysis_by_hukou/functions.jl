## ------------------------------------------------------------------------
##
## Script name: functions.jl
## Purpose: Functions for cleaning the raw data
## Author: Yanwen Wang
## Date Created: 2024-12-09
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

#=
Function for restricting samples
=#

# Women's sample
function restrict_sample_women(df)
    n_original = nrow(df)
    n_previous = n_original
    stages = String[]
    drops = Float64[]

    # Step 1: Gender
    df_gender = filter(row -> begin
            !ismissing(row.female) && row.female == 1
        end, df)
    n_current = nrow(df_gender)
    push!(
        stages,
        "Gender restriction"
    )
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    # Step 2: Age restriction
    df_age = filter(row -> begin
            row.year == 2000 && !ismissing(row.age) && 25 <= row.age <= 34 ||
                row.year == 2010 && !ismissing(row.age) && 25 <= row.age <= 34
        end, df_gender)
    n_current = nrow(df_age)
    push!(
        stages,
        "Respondent not born in cohorts between 1966 and 1985 (non-overlapping)"
    )
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    # Step 3: Respondent education information
    df_edu_marst = filter(row -> begin
            !ismissing(row.edu) && !ismissing(row.marst) && !ismissing(row.urban)
        end, df_age)
    n_current = nrow(df_edu_marst)
    push!(stages, "Missing respondent's education, urban, or marital status")
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    # Step 4: Missing spousal education or urban status when married
    df_edu_sp = filter(row -> begin
            !(row.marst == "married" && (ismissing(row.edu_sp) || ismissing(row.urban_sp)))
        end, df_edu_marst)
    n_current = nrow(df_edu_sp)
    push!(stages, "Missing spousal education when married")
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    # Step 5: Mistmacthed urban status when married
    df_urban_match = filter(row -> begin
            !(row.marst == "married" && row.urban != row.urban_sp)
        end, df_edu_sp)
    n_current = nrow(df_urban_match)
    push!(stages, "Mismatched urban status when married")
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    df_final = df_urban_match
    n_current = nrow(df_final)

    # Print sample restriction summary
    println("Sample Restriction Summary:")
    println("Original sample size: ", n_original)
    for (i, stage) in enumerate(stages)
        println("Dropped due to ", stage, ": ", round(drops[i], digits=3), "%")
    end
    println("\nFinal analysis sample: ", n_current,
        " (", round(n_current / n_original * 100, digits=3), "% of original sample)")

    return df_final
end

# Men's sample
function restrict_sample_men(df)
    n_original = nrow(df)
    n_previous = n_original
    stages = String[]
    drops = Float64[]

    # Step 1: Gender
    df_gender = filter(row -> begin
            !ismissing(row.female) && row.female == 0
        end, df)
    n_current = nrow(df_gender)
    push!(
        stages,
        "Gender restriction"
    )
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    # Step 2: Age restriction
    df_age = filter(row -> begin
            row.year == 2000 && !ismissing(row.age) && 27 <= row.age <= 36 ||
                row.year == 2010 && !ismissing(row.age) && 27 <= row.age <= 36
        end, df_gender)
    n_current = nrow(df_age)
    push!(
        stages,
        "Respondent not born in cohorts between 1964 and 1983 (non-overlapping)"
    )
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    # Step 3: Respondent education information
    df_edu_marst = filter(row -> begin
            !ismissing(row.edu) && !ismissing(row.marst) && !ismissing(row.urban)
        end, df_age)
    n_current = nrow(df_edu_marst)
    push!(stages, "Missing respondent's education, urban, or marital status")
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    # Step 4: Missing spousal education or urban status when married
    df_edu_sp = filter(row -> begin
            !(row.marst == "married" && (ismissing(row.edu_sp) || ismissing(row.urban_sp)))
        end, df_edu_marst)
    n_current = nrow(df_edu_sp)
    push!(stages, "Missing spousal education when married")
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    # Step 5: Mistmacthed urban status when married
    df_urban_match = filter(row -> begin
            !(row.marst == "married" && row.urban != row.urban_sp)
        end, df_edu_sp)
    n_current = nrow(df_urban_match)
    push!(stages, "Mismatched urban status when married")
    push!(drops, (n_previous - n_current) / n_original * 100)
    n_previous = n_current

    df_final = df_urban_match
    n_current = nrow(df_final)

    # Print sample restriction summary
    println("Sample Restriction Summary:")
    println("Original sample size: ", n_original)
    for (i, stage) in enumerate(stages)
        println("Dropped due to ", stage, ": ", round(drops[i], digits=3), "%")
    end
    println("\nFinal analysis sample: ", n_current,
        " (", round(n_current / n_original * 100, digits=3), "% of original sample)")

    return df_final
end

#=
Function for assigning 5-year cohorts
=#
function assign_cohort(year)
    for (range, label) in cohort_ranges
        if year >= range[1] && year <= range[1] + 4
            return label
        end
    end
    return missing
end

#=
Function for calculating structural patterns under random matching
=#
function calculate_expected_proportion(group)
    # Remove missing values and count frequencies
    f_counts = countmap(skipmissing(group.edu_f))
    m_counts = countmap(skipmissing(group.edu_m))

    # Check if data is valid
    if isempty(f_counts) || isempty(m_counts)
        return (homo=missing, hyper=missing, hypo=missing)
    end

    # Calculate total observations for proportions
    f_total = sum(values(f_counts))
    m_total = sum(values(m_counts))

    # Convert to proportions
    f_prop = Dict(k => v / f_total for (k, v) in f_counts)
    m_prop = Dict(k => v / m_total for (k, v) in m_counts)

    # Calculate expected proportions
    Homogamy = sum(get(f_prop, i, 0) * get(m_prop, i, 0)
                   for i in union(keys(f_prop), keys(m_prop)))

    Hypergamy = sum(get(f_prop, i, 0) *
                    sum(get(m_prop, j, 0) for j in keys(m_prop) if j > i; init=0.0)
                    for i in keys(f_prop))

    Hypogamy = sum(get(f_prop, i, 0) *
                   sum(get(m_prop, j, 0) for j in keys(m_prop) if j < i; init=0.0)
                   for i in keys(f_prop))

    return (
        Homogamy=Homogamy,
        Hypergamy=Hypergamy,
        Hypogamy=Hypogamy
    )
end