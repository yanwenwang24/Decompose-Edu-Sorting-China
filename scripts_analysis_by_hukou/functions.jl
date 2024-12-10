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

#=
Functions for decomposition analysis
=#
"""
    ComponentSet

Struct to store the three components of educational pairing analysis
- margins: Educational distribution (f_totals, m_totals)
- weights: Educational gradients in marriage rates
- pattern: Assortative mating pattern relative to random sorting
"""
struct ComponentSet
    margins::Tuple{Vector{Float64},Vector{Float64}}
    weights::Matrix{Float64}
    pattern::Matrix{Float64}
end

"""
    extract_components(df)

Extract all three components from a single group's data.
Returns a ComponentSet containing margins, weights, and pattern components.
"""
function extract_components(df::DataFrame)
    max_edu = maximum(df.edu_f) - 1
    full_matrix = zeros(Float64, max_edu + 1, max_edu + 1)

    # Fill marriage table and margins
    for row in eachrow(df)
        if row.edu_f ≤ max_edu && row.edu_m ≤ max_edu
            full_matrix[row.edu_f, row.edu_m] = row.n
        elseif row.edu_m == max_edu + 1 && row.edu_f ≤ max_edu
            full_matrix[row.edu_f, end] = row.n
        elseif row.edu_f == max_edu + 1 && row.edu_m ≤ max_edu
            full_matrix[end, row.edu_m] = row.n
        end
    end

    # Standardize components separately
    marriage_sum = sum(@view full_matrix[1:max_edu, 1:max_edu])

    # Create margins
    f_totals = full_matrix[1:max_edu, end] ./ sum(full_matrix[1:max_edu, end])
    m_totals = full_matrix[end, 1:max_edu] ./ sum(full_matrix[end, 1:max_edu])
    margins = (f_totals, m_totals)

    # Calculate marriage gradients
    f_married = vec(sum(full_matrix[1:max_edu, 1:max_edu], dims=2))
    m_married = vec(sum(full_matrix[1:max_edu, 1:max_edu], dims=1))
    weights = (f_married ./ full_matrix[1:max_edu, end]) .*
              (m_married ./ full_matrix[end, 1:max_edu])'
    weights ./= sum(weights)

    # Calculate assortative mating pattern using odds ratios
    pattern = ones(max_edu, max_edu)
    marriage_table = full_matrix[1:max_edu, 1:max_edu] ./ marriage_sum
    for r in 2:max_edu, c in 2:max_edu
        pattern[r, c] = (marriage_table[r, c] / marriage_table[r, 1]) *
                        (marriage_table[1, 1] / marriage_table[1, c])
    end

    return ComponentSet(margins, weights, pattern)
end

"""
    extract_components_by_group(df, group_col::Symbol)

Extract components for all groups in the DataFrame.
Returns a dictionary mapping group values to their respective ComponentSets.
"""
function extract_components_by_group(df, group_col::Symbol)
    grouped = groupby(df, group_col)
    return Dict(first(g[!, group_col]) => extract_components(g) for g in grouped)
end

"""
    get_marriage_totals(margins::Tuple{Vector{Float64}, Vector{Float64}}, 
                       weights::Matrix{Float64})

Calculate marriage margins using population totals and marriage gradients.
Returns vectors of married individuals by education level for females and males.
"""
function get_marriage_totals(margins::Tuple{Vector{Float64},Vector{Float64}},
    weights::Matrix{Float64})
    f_totals, m_totals = margins
    married_matrix = weights .* (f_totals * m_totals')
    f_married = vec(sum(married_matrix, dims=2))
    m_married = vec(sum(married_matrix, dims=1))
    return f_married, m_married
end

"""
    normalize_margins(f_married::Vector{Float64}, m_married::Vector{Float64})

Ensure margin consistency by normalizing to the average total.
"""
function normalize_margins(f_married::Vector{Float64}, m_married::Vector{Float64})
    f_sum = sum(f_married)
    m_sum = sum(m_married)
    avg_sum = (f_sum + m_sum) / 2

    return f_married * (avg_sum / f_sum), m_married * (avg_sum / m_sum)
end

"""
    reconstruct(components::ComponentSet)

Reconstruct marriage matrix from components using Iterative Proportional Fitting.
Returns the reconstructed matrix and the actual margins after fitting.
"""
function reconstruct(components::ComponentSet)
    # Get marriage margins and normalize them
    f_married, m_married = get_marriage_totals(components.margins, components.weights)
    f_married_norm, m_married_norm = normalize_margins(f_married, m_married)

    # Initialize matrix with pattern
    initial_matrix = copy(components.pattern)

    # Apply IPF
    factors = ipf(initial_matrix, [f_married_norm, m_married_norm])

    # Create final matrix
    reconstructed = Array(factors) .* initial_matrix

    # Calculate final margins
    final_row_margins = vec(sum(reconstructed, dims=2))
    final_col_margins = vec(sum(reconstructed, dims=1))

    return reconstructed, (
        row_margins=final_row_margins,
        col_margins=final_col_margins,
        target_row_margins=f_married_norm,
        target_col_margins=m_married_norm
    )
end

"""
    calculate_mating_patterns(matrix::Matrix{Float64})

Calculate proportions of homogamy, hypergamy, and hypogamy from a marriage matrix.
"""
function calculate_mating_patterns(matrix::Matrix{Float64})
    n = size(matrix, 1)
    total = sum(matrix)

    homogamy = sum(matrix[i, i] for i in 1:n) / total
    hypergamy = sum(matrix[i, j] for i in 1:n, j in 1:n if j > i) / total
    hypogamy = sum(matrix[i, j] for i in 1:n, j in 1:n if j < i) / total

    return (homogamy=homogamy, hypergamy=hypergamy, hypogamy=hypogamy)
end

"""
    decompose_differences(comp1::ComponentSet, comp2::ComponentSet)

Decompose differences in mating patterns between two groups.
Returns contributions of educational expansion, gradient, and assortative mating preference.
"""
function decompose_differences(comp1::ComponentSet, comp2::ComponentSet)
    # Create all matrices using different component combinations
    Y = Dict{Tuple{Int,Int,Int},NamedTuple}()

    for (i, j, k) in Iterators.product(1:2, 1:2, 1:2)
        components = ComponentSet(
            i == 1 ? comp1.margins : comp2.margins,
            j == 1 ? comp1.weights : comp2.weights,
            k == 1 ? comp1.pattern : comp2.pattern
        )
        matrix, _ = reconstruct(components)
        Y[(i, j, k)] = calculate_mating_patterns(matrix)
    end

    contributions = Dict{Symbol,Dict{String,Float64}}()

    for pattern in [:homogamy, :hypergamy, :hypogamy]
        # Assortative mating preference (pattern effect)
        pattern_effect = 0.5 * (
            (Y[(2, 2, 2)][pattern] - Y[(2, 2, 1)][pattern]) +
            (Y[(1, 1, 2)][pattern] - Y[(1, 1, 1)][pattern])
        )

        # Educational expansion
        expansion_effect = 0.25 * (
            Y[(2, 2, 1)][pattern] - Y[(1, 2, 1)][pattern] +
            Y[(2, 1, 1)][pattern] - Y[(1, 1, 1)][pattern] +
            Y[(2, 2, 2)][pattern] - Y[(1, 2, 2)][pattern] +
            Y[(2, 1, 2)][pattern] - Y[(1, 1, 2)][pattern]
        )

        # Educational gradient
        gradient_effect = 0.25 * (
            Y[(1, 2, 1)][pattern] - Y[(1, 1, 1)][pattern] +
            Y[(2, 2, 1)][pattern] - Y[(2, 1, 1)][pattern] +
            Y[(1, 2, 2)][pattern] - Y[(1, 1, 2)][pattern] +
            Y[(2, 2, 2)][pattern] - Y[(2, 1, 2)][pattern]
        )

        contributions[pattern] = Dict(
            "total" => Y[(2, 2, 2)][pattern] - Y[(1, 1, 1)][pattern],
            "expansion" => expansion_effect,
            "gradient" => gradient_effect,
            "pattern" => pattern_effect
        )
    end

    return (matrices=Y, contributions=contributions)
end

"""
    bootstrap_decomposition(comp1::ComponentSet, comp2::ComponentSet, df::DataFrame;
                          n_bootstrap::Int=1000, seed::Int=42)

Perform bootstrap analysis of decomposition results. Uses the original ComponentSets
for point estimates and generates bootstrap samples for standard errors.

Returns a structured result containing point estimates and bootstrap statistics.
"""
function bootstrap_decomposition(comp1::ComponentSet, comp2::ComponentSet, df::DataFrame;
    n_bootstrap::Int=1000, seed::Int=42)
    Random.seed!(seed)

    # Get point estimates from original data
    point_estimates = decompose_differences(comp1, comp2)

    # Identify the grouping variable and values
    # We assume the first non-numeric, non-n column is the grouping variable
    group_col = names(df)[findfirst(col -> col ∉ ["edu_f", "edu_m", "n", "n_unrounded"], names(df))]
    group_vals = unique(df[:, group_col])

    # Remove rows with missing values and prepare for bootstrap
    valid_df = filter(row -> !ismissing(row.n), df)
    n_total = Int(round(sum(valid_df.n)))
    probs = valid_df.n ./ sum(valid_df.n)

    # Storage for bootstrap results
    bootstrap_results = Vector{Dict{Symbol,Dict{String,Float64}}}(undef, n_bootstrap)

    # Get the initial group values that correspond to comp1 and comp2
    group_val1 = group_vals[1]  # Value for comp1
    group_val2 = group_vals[end]  # Value for comp2

    # Perform bootstrap iterations
    for b in 1:n_bootstrap
        # Generate bootstrap sample
        boot_df = copy(valid_df)
        boot_df.n = rand(Distributions.Multinomial(n_total, probs))

        # Split into groups based on the identified grouping variable
        group1_df = filter(row -> row[group_col] == group_val1, boot_df)
        group2_df = filter(row -> row[group_col] == group_val2, boot_df)

        boot_comp1 = extract_components(group1_df)
        boot_comp2 = extract_components(group2_df)

        # Store decomposition results
        bootstrap_results[b] = decompose_differences(boot_comp1, boot_comp2).contributions
    end

    # Calculate bootstrap statistics with proper handling of invalid results
    results = Dict{Symbol,Dict{String,NamedTuple}}()

    for pattern in [:homogamy, :hypergamy, :hypogamy]
        results[pattern] = Dict{String,NamedTuple}()

        for component in ["total", "expansion", "gradient", "pattern"]
            # Get all values and filter out missing or NaN
            all_values = [bootstrap_results[b][pattern][component] for b in 1:n_bootstrap]
            valid_values = filter(x -> !ismissing(x) && !isnan(x), all_values)

            point_est = point_estimates.contributions[pattern][component]

            results[pattern][component] = (
                estimate=point_est,
                se=std(valid_values),
                ci_lower=quantile(valid_values, 0.025),
                ci_upper=quantile(valid_values, 0.975)
            )
        end
    end

    return results
end

"""
    create_comparison_analysis(df::DataFrame, group_var::Symbol; n_bootstrap::Int=1000)

Analyze differences between groups defined by group_var, comparing each group to the baseline
(first group). Returns a DataFrame containing decomposition results and uncertainty measures.

Parameters:
- df: Input DataFrame containing marriage data
- group_var: Symbol specifying the grouping variable (e.g., :cohort, :urban)
- n_bootstrap: Number of bootstrap iterations for uncertainty estimation
"""
function create_comparison_analysis(df::DataFrame, group_var::Symbol; n_bootstrap::Int=1000)
    groups = unique(df[!, group_var])
    base_group = groups[1]

    # Create component sets for all groups
    component_sets = Dict(
        group => extract_components(filter(row -> row[group_var] == group, df))
        for group in groups
    )

    # Initialize storage for results
    results_data = []

    # Perform comparisons
    for group in groups
        # Perform decomposition with bootstrap
        bootstrap_results = bootstrap_decomposition(
            component_sets[base_group],
            component_sets[group],
            df,
            n_bootstrap=n_bootstrap
        )

        # Extract and store results for each pattern and component
        for pattern in [:homogamy, :hypergamy, :hypogamy]
            for component in ["total", "expansion", "gradient", "pattern"]
                result = bootstrap_results[pattern][component]

                push!(results_data, (
                    group=group,
                    base_group=base_group,
                    group_var=String(group_var),
                    pattern=pattern,
                    component=component,
                    estimate=result.estimate,
                    se=result.se,
                    ci_lower=result.ci_lower,
                    ci_upper=result.ci_upper
                ))
            end
        end
    end

    # Convert to DataFrame
    results_df = DataFrame(results_data)

    # Add group order for plotting
    group_order = Dict(group => i for (i, group) in enumerate(groups))
    results_df.group_num = [group_order[g] for g in results_df.group]

    return results_df
end