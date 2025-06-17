## ------------------------------------------------------------------------
##
## Script name: 03_composition.jl
## Purpose: Educational composition
## Author: Yanwen Wang
## Date Created: 2024-12-09
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Compute changes in educational composition across cohorts
##
## ------------------------------------------------------------------------

# 1 Women -----------------------------------------------------------------

prop_women = prop(freqtable(sample_women, :cohort, :edu5, :urban), margins=1:2:3)

# Convert named matrix to DataFrame
data_rural = parent(prop_women)[:, :, 1]
data_urban = parent(prop_women)[:, :, 2]
row_names = names(prop_women, 1) # cohort values
col_names = names(prop_women, 2) # edu values

# Rural
edu_comp_women_rural = DataFrame(data_rural, Symbol.(string.(col_names)))
edu_comp_women_rural[!, :cohort] = row_names
select!(edu_comp_women_rural, :cohort, Not(:cohort))

edu_comp_women_rural_long = stack(
    edu_comp_women_rural,
    variable_name="Education",
)
edu_comp_women_rural_long[!, :urban] .= 1
edu_comp_women_rural_long.Gender .= "Women"

# Urban
edu_comp_women_urban = DataFrame(data_urban, Symbol.(string.(col_names)))
edu_comp_women_urban[!, :cohort] = row_names
select!(edu_comp_women_urban, :cohort, Not(:cohort))

edu_comp_women_urban_long = stack(
    edu_comp_women_urban,
    variable_name="Education",
)
edu_comp_women_urban_long[!, :urban] .= 2
edu_comp_women_urban_long.Gender .= "Women"

edu_comp_women_long = vcat(
    edu_comp_women_urban_long,
    edu_comp_women_rural_long,
)

sort!(edu_comp_women_long, :cohort)

# 2 Men -------------------------------------------------------------------

prop_men = prop(freqtable(sample_men, :cohort, :edu5, :urban), margins=1:2:3)

# Convert named matrix to DataFrame
data_rural = parent(prop_men)[:, :, 1]
data_urban = parent(prop_men)[:, :, 2]
row_names = names(prop_men, 1) # cohort values
col_names = names(prop_men, 2) # edu values

# Rural
edu_comp_men_rural = DataFrame(data_rural, Symbol.(string.(col_names)))
edu_comp_men_rural[!, :cohort] = row_names
select!(edu_comp_men_rural, :cohort, Not(:cohort))

edu_comp_men_rural_long = stack(
    edu_comp_men_rural,
    variable_name="Education",
)
edu_comp_men_rural_long[!, :urban] .= 1
edu_comp_men_rural_long.Gender .= "Men"

# Urban
edu_comp_men_urban = DataFrame(data_urban, Symbol.(string.(col_names)))
edu_comp_men_urban[!, :cohort] = row_names
select!(edu_comp_men_urban, :cohort, Not(:cohort))

edu_comp_men_urban_long = stack(
    edu_comp_men_urban,
    variable_name="Education",
)
edu_comp_men_urban_long[!, :urban] .= 2
edu_comp_men_urban_long.Gender .= "Men"

edu_comp_men_long = vcat(
    edu_comp_men_urban_long,
    edu_comp_men_rural_long,
)

sort!(edu_comp_men_long, :cohort)

# Merge observed and structural patterns
edu_comp_df = vcat(edu_comp_women_long, edu_comp_men_long)

# Save to outputs
write_parquet("outputs/tables/urban-rural/edu_comp.parquet", edu_comp_df)
