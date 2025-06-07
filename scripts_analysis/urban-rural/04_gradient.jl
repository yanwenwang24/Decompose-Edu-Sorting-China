## ------------------------------------------------------------------------
##
## Script name: 04_gradient.jl
## Purpose: Educational gradient in marriage rates
## Author: Yanwen Wang
## Date Created: 2024-12-09
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Compute changes in educational gradients in marriage rates
##
## ------------------------------------------------------------------------

# 1 Women -----------------------------------------------------------------

# Ratio of unmarried to married
women_ratio = combine(
    groupby(sample_women, [:urban, :birthy, :edu4]),
    # Calculate married and unmarried counts
    :marst => (x -> sum(x .== "married")) => :married,
    :marst => (x -> sum(x .!= "married")) => :unmarried
)

# Add ratio and gender columns
women_ratio.ratio = women_ratio.unmarried ./ women_ratio.married
women_ratio.Gender .= "Women"

# 2 Men -------------------------------------------------------------------

# Ratio of unmarried to married
men_ratio = combine(
    groupby(sample_men, [:urban, :birthy, :edu4]),
    # Calculate married and unmarried counts
    :marst => (x -> sum(x .== "married")) => :married,
    :marst => (x -> sum(x .!= "married")) => :unmarried
)

# Add ratio and gender columns
men_ratio.ratio = men_ratio.unmarried ./ men_ratio.married
men_ratio.Gender .= "Men"

# Merge
gradients_df = vcat(women_ratio, men_ratio)

# Save to outputs
write_parquet("outputs/tables/urban-rural/gradients.parquet", gradients_df)
