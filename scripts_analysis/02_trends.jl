## ------------------------------------------------------------------------
##
## Script name: 02_trends.jl
## Purpose: Trends in educational sorting outcomes
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Compute the relative proportion of homogamy, hypergamy, 
## and hypogamy across cohorts (observed and structural)
##
## ------------------------------------------------------------------------

# 1 Observed trends -------------------------------------------------------

observed_pattern = @chain sample begin
    @groupby(:birthy)
    @combine(
        :Homogamy = mean(:homo),
        :Hypergamy = mean(:hyper),
        :Hypogamy = mean(:hypo)
    )
end

observed_pattern_long = stack(
    observed_pattern,
    variable_name="Pattern",
    value_name="Proportion"
)

sort!(observed_pattern_long, :birthy)

observed_pattern_long.Type .= "Observed"

# 2 Structural trends -----------------------------------------------------

structural_pattern = combine(groupby(sample, :birthy)) do group
    calculate_expected_proportion(group)
end

structural_pattern_long = stack(
    structural_pattern,
    variable_name="Pattern",
    value_name="Proportion"
)

sort!(structural_pattern_long, :birthy)

structural_pattern_long.Type .= "Structural"

# Merge observed and structural patterns
trends_df = vcat(observed_pattern_long, structural_pattern_long)

# Save to outputs
Arrow.write("Outputs/trends.arrow", trends_df)