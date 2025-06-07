## ------------------------------------------------------------------------
##
## Script name: 01_sample.jl
## Purpose: Select samples for analysis
## Author: Yanwen Wang
## Date Created: 2024-12-08
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
cohort_ranges = (1946:5:1981) .=> [string(y,"s") for y in 45:5:80]

## Assign and categorize cohorts
transform!(sample_women, :birthy => ByRow(assign_cohort) => :cohort)

# Sample of married women (main sample for analysis)
sample_women_married = @subset(sample_women, :marst .== "married")

# 1.2 Men ----------------------------------------------------------------

# Select all men, regardless of marital status
sample_men = restrict_sample_men(census)

# Assign cohorts (5-year)
## Define cohort range
cohort_ranges = (1944:5:1983) .=> [string(y,"s") for y in 45:5:80]

## Assign and categorize cohorts
transform!(sample_men, :birthy => ByRow(assign_cohort) => :cohort)

# 2 Save samples ----------------------------------------------------------

write_parquet("data/samples/pooled/sample_women.parquet", sample_women)
write_parquet("data/samples/pooled/sample_men.parquet", sample_men)
write_parquet("data/samples/pooled/sample_women_married.parquet", sample_women_married)
