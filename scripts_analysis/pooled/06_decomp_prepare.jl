## ------------------------------------------------------------------------
##
## Script name: 06_decomp_prepare.jl
## Purpose: Prepare data for decomposition analysis
## Author: Yanwen Wang
## Date Created: 2024-12-09
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Prepare data for decomposition analysis
##
## ------------------------------------------------------------------------

# 1 Prepare data ----------------------------------------------------------

# Number of unmarried women
women_unmarried = @chain sample_women begin
    @subset(:marst .!= "married")
    @groupby(:cohort, :edu_f)
    @combine(:women_unmarried = length(:edu_f))
    @select(:cohort, :edu_f, :women_unmarried)
    sort([:cohort, :edu_f])
end

# Men's ratio of unmarried to married
men_ratio = combine(
    groupby(sample_men, [:cohort, :edu_m]),
    # Calculate married and unmarried counts
    :marst => (x -> sum(x .== "married")) => :married,
    :marst => (x -> sum(x .!= "married")) => :unmarried
) 

men_ratio[!, :ratio] = men_ratio.unmarried ./ men_ratio.married

select!(men_ratio, :cohort, :edu_m, :ratio)

# Women's ratio of unmarried to married
women_ratio = combine(
    groupby(sample_women, [:cohort, :edu_f]),
    # Calculate married and unmarried counts
    :marst => (x -> sum(x .== "married")) => :married,
    :marst => (x -> sum(x .!= "married")) => :unmarried
) 

women_ratio[!, :ratio] = women_ratio.unmarried ./ women_ratio.married

select!(women_ratio, :cohort, :edu_f, :ratio)

# Make an empty DataFrame to store results
df = DataFrame(
    collect(
        Iterators.product(
            sample_women.cohort |> unique |> sort,
            1:5,
            1:5
        )
    ) |> vec
)

rename!(df, [:cohort, :edu_f, :edu_m])
sort!(df, [:cohort, :edu_f, :edu_m])

# Make contingency tables
count_df = @chain sample begin
    @groupby(:cohort, :edu_f, :edu_m)
    @combine(:n = length(:edu_m))
end

leftjoin!(df, count_df, on=["cohort", "edu_f", "edu_m"])
sort(df, [:cohort, :edu_f, :edu_m])

# Compute number of unmarried men at each educational level (counterfactual)
men_unmarried = @chain count_df begin
    # Number of men (married) at each educational level
    @groupby(:cohort, :edu_m)
    @combine(:men_married = sum(:n))
     # Number of men (unmarried) at each educational level
    leftjoin(men_ratio, on=["cohort", "edu_m"])
    @transform(:men_unmarried = :men_married .* :ratio)
    @select(:cohort, :edu_m, :men_unmarried)
end

# Merge number of unmarried men to the contingency table
leftjoin!(df, men_unmarried, on=[:cohort, :edu_m])
df[!, :n] = coalesce.(df.n, df.men_unmarried)

# Merge number of unmarried women to the contingency table
leftjoin!(df, women_unmarried, on=[:cohort, :edu_f])
df[!, :n] = coalesce.(df.n, df.women_unmarried)

select!(df, :cohort, :edu_f, :edu_m, :n)

# Total number of unmarried women by educational level
women_total = @chain df begin
    @groupby(:cohort, :edu_f)
    @combine(:women_total = sum(skipmissing(:n)))
end

# Total number of unmarried men by educational level
men_total = @chain df begin
    @groupby(:cohort, :edu_m)
    @combine(:men_total = sum(skipmissing(:n)))
end

# Merge to the contingency table
leftjoin!(df, women_total, on=[:cohort, :edu_f])
df[df.edu_m .== 5, :n] = df[df.edu_m .== 5, :women_total]
leftjoin!(df, men_total, on=[:cohort, :edu_m])
df[df.edu_f .== 5, :n] = df[df.edu_f .== 5, :men_total]

df[(df.edu_m .== 5) .& (df.edu_f .== 5), :n] .= missing

df[!, :n_unrounded] = df.n
df[!, :n] = round.(df.n)
select!(df, :cohort, :edu_f, :edu_m, :n, :n_unrounded)

# Save the data
Arrow.write("Outputs/df_for_decomp.arrow", df)