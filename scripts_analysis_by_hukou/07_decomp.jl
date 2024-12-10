## ------------------------------------------------------------------------
##
## Script name: 07_decomp.jl
## Purpose: Decompose differences in educational sorting outcomes
## Author: Yanwen Wang
## Date Created: 2024-12-10
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Decompose differences in educational sorting outcomes between
## urban and rural areas by each cohort.
##
## ------------------------------------------------------------------------

# 1 Load data --------------------------------------------------------------

df = DataFrame(Arrow.Table("Outputs_by_hukou/df_for_decomp.arrow"))

# 2 Example ----------------------------------------------------------------

#=
# Decompose differences between urban and rural areas for the 65s cohort

df_65s = df[df.cohort .== "65s", :]
df_65s_rural = df_65s[df_65s.urban .== 1, :]
df_65s_urban = df_65s[df_65s.urban .== 2, :]

# Extract components for decomposition
comp1 = extract_components(df_65s_rural)
comp2 = extract_components(df_65s_urban)

# Decompose differences
results = decompose_differences(comp1, comp2)

for pattern in [:homogamy, :hypergamy, :hypogamy]
    println("\nDecomposition of differences in $pattern:")
    for (component, value) in results.contributions[pattern]
        println("  $component: $(round(value * 100, digits=3))%")
    end
end

# Get standard errors
bootstrap_results = bootstrap_decomposition(comp1, comp2, df_65s, n_bootstrap=1000)
=#

# 3 Decomposition ----------------------------------------------------------

# Get unique cohorts for iteration
cohorts = unique(df.cohort)

# Initialize DataFrame for storing all results
decomp_df = DataFrame()

# Analyze urban-rural differences within each cohort
for cohort in cohorts
    # Filter data for current cohort
    cohort_df = filter(row -> row.cohort == cohort, df)

    # Perform urban-rural comparison analysis
    cohort_results = create_comparison_analysis(cohort_df, :urban, n_bootstrap=1000)

    # Add cohort information
    cohort_results[!, :cohort] .= cohort

    # Combine results
    if nrow(decomp_df) == 0
        decomp_df = cohort_results
    else
        append!(decomp_df, cohort_results)
    end
end

# Save results 
Arrow.write("Outputs_by_hukou/decomp.arrow", decomp_df)