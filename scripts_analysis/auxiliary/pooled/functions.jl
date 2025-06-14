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

"""
    FilterStep

A struct representing a single step in the data filtering process.

# Fields
- `name::String`: The name of the filter step
- `filter_fn::Function`: The function to apply for filtering
- `description::String`: A detailed description of what the filter does
"""
struct FilterStep
    name::String
    filter_fn::Function
    description::String
end

"""
    restrict_sample_women(df::DataFrame) -> DataFrame

Apply a series of filtering steps to restrict the sample for women based on predefined criteria.

# Arguments
- `df::DataFrame`: The input DataFrame to be filtered

# Returns
- A filtered DataFrame containing only observations that meet all criteria

# Details
Applies sequential filters for:
1. Gender (female only)
2. Age (27-36 for 1982, 25-34 for 1990, 2000, and 2010)
3. Marital status (married or never-married)
4. Non-missing education (respondent and spouse if married)

Prints progress information for each filtering step.
"""
function restrict_sample_women(df::DataFrame)
    initial_size = size(df, 1)
    println("Initial sample size: ", initial_size)

    # Define all filtering steps
    filter_steps = [
        FilterStep(
            "gender",
            df -> filter(
                row -> !ismissing(row.female) && row.female == 1, df
            ),
            "Filter by gender (female only)"
        ),
        FilterStep(
            "age",
            df -> filter(row -> begin
                    row.year == 1982 && !ismissing(row.age) && 27 <= row.age <= 36 ||
                        row.year == 1990 && !ismissing(row.age) && 25 <= row.age <= 34 ||
                        row.year == 2000 && !ismissing(row.age) && 25 <= row.age <= 34 ||
                        row.year == 2010 && !ismissing(row.age) && 25 <= row.age <= 34
                end, df),
            "Filter by age: 1982 (27-36), 1990/2000/2010 (25-34)"
        ),
        FilterStep(
            "marital status",
            df -> filter(
                row -> !ismissing(row.marst) &&
                    (row.marst == "married" || row.marst == "never-married"),
                df
            ),
            "Filter by marital status: married or never-married"
        ),
        FilterStep(
            "education",
            df -> filter(
                row -> !ismissing(row.edu5) && !(row.marst == "married" && ismissing(row.edu5_sp)),
                df
            ),
            "Filter by education: non-missing own and spousal education"
        )
    ]

    # Apply filters sequentially
    current_sample = df
    previous_size = initial_size

    for (i, step) in enumerate(filter_steps)
        # Apply filter
        current_sample = step.filter_fn(current_sample)
        current_size = size(current_sample, 1)

        # Calculate statistics
        dropped = previous_size - current_size
        percent_dropped = round(dropped / previous_size * 100, digits=2)

        # Print results
        println(
            "Step ", i, ": ", step.description,
            ", size: ", current_size,
            ", dropped: ", dropped,
            " (", percent_dropped, "%)"
        )

        previous_size = current_size
    end

    return current_sample
end

"""
    restrict_sample_men(df::DataFrame) -> DataFrame

Apply a series of filtering steps to restrict the sample for men based on predefined criteria.

# Arguments
- `df::DataFrame`: The input DataFrame to be filtered

# Returns
- A filtered DataFrame containing only observations that meet all criteria

# Details
Applies sequential filters for:
1. Gender (male only)
2. Age (29-38 for 1982, 27-36 for 1990, 2000, and 2010)
3. Marital status (married or never-married)
4. Non-missing education (respondent and spouse if married)

Prints progress information for each filtering step.
"""
function restrict_sample_men(df::DataFrame)
    initial_size = size(df, 1)
    println("Initial sample size: ", initial_size)

    # Define all filtering steps
    filter_steps = [
        FilterStep(
            "gender",
            df -> filter(
                row -> !ismissing(row.female) && row.female == 0, df
            ),
            "Filter by gender (female only)"
        ),
        FilterStep(
            "age",
            df -> filter(row -> begin
                    row.year == 1982 && !ismissing(row.age) && 29 <= row.age <= 38 ||
                        row.year == 1990 && !ismissing(row.age) && 27 <= row.age <= 36 ||
                        row.year == 2000 && !ismissing(row.age) && 27 <= row.age <= 36 ||
                        row.year == 2010 && !ismissing(row.age) && 27 <= row.age <= 36
                end, df),
            "Filter by age: 1982 (29-38), 1990/2000/2010 (27-36)"
        ),
        FilterStep(
            "marital status",
            df -> filter(
                row -> !ismissing(row.marst) &&
                    (row.marst == "married" || row.marst == "never-married"),
                df
            ),
            "Filter by marital status: married or never-married"
        ),
        FilterStep(
            "education",
            df -> filter(
                row -> !ismissing(row.edu5) && !(row.marst == "married" && ismissing(row.edu5_sp)),
                df
            ),
            "Filter by education: non-missing own and spousal education"
        )
    ]

    # Apply filters sequentially
    current_sample = df
    previous_size = initial_size

    for (i, step) in enumerate(filter_steps)
        # Apply filter
        current_sample = step.filter_fn(current_sample)
        current_size = size(current_sample, 1)

        # Calculate statistics
        dropped = previous_size - current_size
        percent_dropped = round(dropped / previous_size * 100, digits=2)

        # Print results
        println(
            "Step ", i, ": ", step.description,
            ", size: ", current_size,
            ", dropped: ", dropped,
            " (", percent_dropped, "%)"
        )

        previous_size = current_size
    end

    return current_sample
end

"""
    assign_cohort(year)

Assign a cohort label to a year based on 5-year ranges in `cohort_ranges`.

Returns the matching cohort label or `missing` if no match found.
"""
function assign_cohort(year)
    for (range, label) in cohort_ranges
        if year >= range[1] && year <= range[1] + 4
            return label
        end
    end
    return missing
end

"""
    calculate_expected_proportion(group)

Calculate expected proportions of homogamy, hypergamy, and hypogamy based on marginal distributions of education levels for females and males.

# Arguments
- `group`: Data structure containing `edu_f` (female education) and `edu_m` (male education) fields

# Returns
Named tuple with three fields:
- `Homogamy`: Expected proportion of couples with same education level
- `Hypergamy`: Expected proportion of couples where female education < male education  
- `Hypogamy`: Expected proportion of couples where female education > male education

Returns `missing` values if input data is empty or invalid.
"""
function calculate_expected_proportion(group)
    # Remove missing values and count frequencies
    f_counts = countmap(skipmissing(group.edu5_f))
    m_counts = countmap(skipmissing(group.edu5_m))

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
    max_edu = maximum(df.edu5_f) - 1
    full_matrix = zeros(Float64, max_edu + 1, max_edu + 1)

    # Fill marriage table and margins
    for row in eachrow(df)
        if row.edu5_f ≤ max_edu && row.edu5_m ≤ max_edu
            full_matrix[row.edu5_f, row.edu5_m] = row.n
        elseif row.edu5_m == max_edu + 1 && row.edu5_f ≤ max_edu
            full_matrix[row.edu5_f, end] = row.n
        elseif row.edu5_f == max_edu + 1 && row.edu5_m ≤ max_edu
            full_matrix[end, row.edu5_m] = row.n
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
    factors = ipf(initial_matrix, [f_married_norm, m_married_norm], maxiter=10000, tol=1e-6)

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
    group_col = names(df)[findfirst(col -> col ∉ ["edu5_f", "edu5_m", "n", "n_unrounded"], names(df))]
    group_vals = unique(df[:, group_col])

    # Remove rows with missing values and prepare for bootstrap
    valid_df = filter(row -> !ismissing(row.n), df)

    # Get the initial group values that correspond to comp1 and comp2
    group_val1 = group_vals[1]
    group_val2 = group_vals[end]

    # Split original data by group
    group1_orig = filter(row -> row[group_col] == group_val1, valid_df)
    group2_orig = filter(row -> row[group_col] == group_val2, valid_df)

    # Calculate group-specific totals and probabilities
    n_total1 = Int(round(sum(group1_orig.n)))
    n_total2 = Int(round(sum(group2_orig.n)))
    probs1 = group1_orig.n ./ sum(group1_orig.n)
    probs2 = group2_orig.n ./ sum(group2_orig.n)

    # Storage for bootstrap results
    bootstrap_results = Vector{Dict{Symbol,Dict{String,Float64}}}(undef, n_bootstrap)

    # Define the small constant to add for numerical stability
    pseudo_count = 1e-6

    # Perform bootstrap iterations
    for b in 1:n_bootstrap
        # Generate bootstrap samples separately for each group
        boot_group1 = copy(group1_orig)
        boot_group1.n = rand(Distributions.Multinomial(n_total1, probs1))

        boot_group2 = copy(group2_orig)
        boot_group2.n = rand(Distributions.Multinomial(n_total2, probs2))

        # Ensure no zero counts by adding a small constant
        boot_group1.n = Float64.(boot_group1.n) .+ pseudo_count
        boot_group2.n = Float64.(boot_group2.n) .+ pseudo_count

        boot_comp1 = extract_components(boot_group1)
        boot_comp2 = extract_components(boot_group2)

        # Store decomposition results
        bootstrap_results[b] = decompose_differences(boot_comp1, boot_comp2).contributions
    end

    # Calculate bootstrap statistics
    results = Dict{Symbol,Dict{String,NamedTuple}}()

    for pattern in [:homogamy, :hypergamy, :hypogamy]
        results[pattern] = Dict{String,NamedTuple}()

        for component in ["total", "expansion", "gradient", "pattern"]
            # Get all values and filter out missing or NaN
            all_values = [bootstrap_results[b][pattern][component] for b in 1:n_bootstrap]
            valid_values = filter(x -> !ismissing(x) && !isnan(x), all_values)

            point_est = point_estimates.contributions[pattern][component]
            se_value = std(valid_values)

            results[pattern][component] = (
                estimate=point_est,
                se=se_value,
                ci_lower=point_est - 1.96 * se_value,
                ci_upper=point_est + 1.96 * se_value
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
    groups = sort(unique(df[!, group_var]))
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
        df_comparison = filter(row -> row[group_var] in (base_group, group), df)

        bootstrap_results = bootstrap_decomposition(
            component_sets[base_group],
            component_sets[group],
            df_comparison,
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
                    pattern=String(pattern),
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
