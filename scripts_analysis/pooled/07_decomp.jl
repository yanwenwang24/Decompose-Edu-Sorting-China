## ------------------------------------------------------------------------
##
## Script name: 07_decomp
## Purpose: Decompose differences in educational sorting outcomes
## Author: Yanwen Wang
## Date Created: 2024-12-09
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Decompose differences in educational sorting outcomes across cohorts
## by educational expansion, educational gradients in marriage rates, and
## assortative mating preferences.
##
## ------------------------------------------------------------------------

# 1 Load data --------------------------------------------------------------

df = DataFrame(Arrow.Table("Outputs/df_for_decomp.arrow"))

# 2 Example ----------------------------------------------------------------

#=
## Component 1 (expansion): marginal totals of education (married + unmarried)
## Component 2 (gradients): marriage rates by education (matrix)
## Component 3 (preferences): assortative mating preferences (matrix)
group1 = extract_components(df[df.cohort .== "45s", :])
group2 = extract_components(df[df.cohort .== "50s", :])

# Perform decomposition
results = decompose_differences(group1, group2)

for pattern in [:homogamy, :hypergamy, :hypogamy]
    println("\nDecomposition of differences in $pattern:")
    for (component, value) in results.contributions[pattern]
        println("  $component: $(round(value * 100, digits=3))%")
    end
end

# Bootstrap results (for standard errors)
bootstrap_results = bootstrap_decomposition(group1, group2, df, n_bootstrap=1000)

# For analysis of all cohorts (the first cohort as the reference cohort)
cohort_results = create_comparison_analysis(df, :cohort, n_bootstrap=1000)
=#

# 3 Decomposition ----------------------------------------------------------

# Comparing across cohorts (45s as the reference cohort)
decomp_df = create_comparison_analysis(df, :cohort, n_bootstrap=1000)

# Save results
Arrow.write("Outputs/decomp.arrow", decomp_df)