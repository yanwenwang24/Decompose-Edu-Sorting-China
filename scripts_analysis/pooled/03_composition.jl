## ------------------------------------------------------------------------
##
## Script name: 03_composition.jl
## Purpose: Educational composition
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Compute changes in educational composition across cohorts
##
## ------------------------------------------------------------------------

# 1 Women -----------------------------------------------------------------

prop_women = prop(freqtable(sample_women, :cohort, :edu5), margins=1)

# Convert named matrix to DataFrame
data = parent(prop_women)
row_names = names(prop_women, 1) # cohort values
col_names = names(prop_women, 2) # edu values

edu_comp_women = DataFrame(data, Symbol.(string.(col_names)))

edu_comp_women[!, :cohort] = row_names
select!(edu_comp_women, :cohort, Not(:cohort))

# Transform to long format
edu_comp_women_long = stack(
    edu_comp_women,
    variable_name="Education",
)
sort!(edu_comp_women_long, :cohort)

edu_comp_women_long.Gender .= "Women"

# 2 Men -------------------------------------------------------------------

prop_men = prop(freqtable(sample_men, :cohort, :edu5), margins=1)

# Convert named matrix to DataFrame
data = parent(prop_men)
row_names = names(prop_men, 1) # cohort values
col_names = names(prop_men, 2) # edu values

edu_comp_men = DataFrame(data, Symbol.(string.(col_names)))

edu_comp_men[!, :cohort] = row_names
select!(edu_comp_men, :cohort, Not(:cohort))

# Transform to long format
edu_comp_men_long = stack(
    edu_comp_men,
    variable_name="Education",
)
sort!(edu_comp_men_long, :cohort)

edu_comp_men_long.Gender .= "Men"

# Merge observed and structural patterns
edu_comp_df = vcat(edu_comp_women_long, edu_comp_men_long)

# Save to outputs
write_parquet("outputs/tables/pooled/edu_comp.parquet", edu_comp_df)
