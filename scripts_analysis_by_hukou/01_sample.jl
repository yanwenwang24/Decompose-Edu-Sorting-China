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
sample_women.cohort = categorical(
    sample_women.cohort,
    levels=last.(cohort_ranges),
    ordered=true
)

# Sample of married women (main sample for analysis)
sample = @subset(sample_women, :marst .== "married")

# 1.2 Men ----------------------------------------------------------------

# Select all men, regardless of marital status
sample_men = restrict_sample_men(census)

# Assign cohorts (5-year)
## Define cohort range
cohort_ranges = (1964:5:1983) .=> [string(y,"s") for y in 65:5:80]

## Assign and categorize cohorts
transform!(sample_men, :birthy => ByRow(assign_cohort) => :cohort)
sample_men.cohort = categorical(
    sample_men.cohort,
    levels=last.(cohort_ranges),
    ordered=true
)

# 2 Save samples ----------------------------------------------------------

Arrow.write("Samples_by_hukou/sample_women.arrow", sample_women)
Arrow.write("Samples_by_hukou/sample_men.arrow", sample_men)
Arrow.write("Samples_by_hukou/sample.arrow", sample)