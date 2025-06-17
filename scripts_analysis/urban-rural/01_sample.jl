## ------------------------------------------------------------------------
##
## Script name: 01_sample.jl
## Purpose: Select samples for analysis
## Author: Yanwen Wang
## Date Created: 2024-12-09
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Select samples of all women, all men, and married women
##
## ------------------------------------------------------------------------

# 1 Restrict sample -------------------------------------------------------

# 1.1 Women ---------------------------------------------------------------

# Select all women, regardless of marital status
sample_women = restrict_sample_women(census)

# Assign cohorts (5-year)
## Define cohort range
cohort_ranges = (1966:5:1981) .=> [string(y,"s") for y in 65:5:80]

## Assign and categorize cohorts
transform!(sample_women, :birthy => ByRow(assign_cohort) => :cohort)

# Recode urban status (prioritize urban status at marriage)
sample_women = @chain sample_women begin
    @transform(:urban = :marurban)
end

# Sample of married women (main sample for analysis)
sample_women_married = @subset(sample_women, :marst .== "married")

# 1.2 Men ----------------------------------------------------------------

# Select all men, regardless of marital status
sample_men = restrict_sample_men(census)

# Assign cohorts (5-year)
## Define cohort range
cohort_ranges = (1964:5:1983) .=> [string(y,"s") for y in 65:5:80]

## Assign and categorize cohorts
transform!(sample_men, :birthy => ByRow(assign_cohort) => :cohort)

# Recode urban status (prioritize urban status at marriage)
sample_men = @chain sample_men begin
    @transform(:urban = :marurban)
end

# 2 Save samples ----------------------------------------------------------

write_parquet("data/samples/urban-rural/sample_women.parquet", sample_women)
write_parquet("data/samples/urban-rural/sample_men.parquet", sample_men)
write_parquet("data/samples/urban-rural/sample_women_married.parquet", sample_women_married)
