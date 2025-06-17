## ------------------------------------------------------------------------
##
## Script name: 02_trends.jl
## Purpose: Trends in educational sorting outcomes
## Author: Yanwen Wang
## Date Created: 2024-12-09
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Compute the relative proportion of homogamy, hypergamy, 
## and hypogamy across cohorts (observed and structural)
##
## ------------------------------------------------------------------------

# 1 Observed trends -------------------------------------------------------

observed_pattern = @chain sample_women_married begin
    @groupby(:urban, :birthy)
    @combine(
        :Homogamy = mean(:homo5),
        :Hypergamy = mean(:hyper5),
        :Hypogamy = mean(:hypo5)
    )
end

observed_pattern_long = stack(
    observed_pattern,
    Not(:urban, :birthy),
    variable_name="Pattern",
    value_name="Proportion"
)

observed_pattern_long.Type .= "Observed"

# 2 Structural trends -----------------------------------------------------

structural_pattern = combine(groupby(sample_women_married, [:urban, :birthy])) do group
    calculate_expected_proportion(group)
end

structural_pattern_long = stack(
    structural_pattern,
    Not(:urban, :birthy),
    variable_name="Pattern",
    value_name="Proportion"
)

structural_pattern_long.Type .= "Structural"

# Merge observed and structural patterns
trends_df = vcat(observed_pattern_long, structural_pattern_long)

# Save to outputs
write_parquet("outputs/tables/urban-rural/trends.parquet", trends_df)
