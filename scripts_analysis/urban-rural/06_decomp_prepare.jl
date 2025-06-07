## ------------------------------------------------------------------------
##
## Script name: 06_decomp_prepare.jl
## Purpose: Prepare data for decomposition analysis
## Author: Yanwen Wang
## Date Created: 2024-12-10
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Prepare data for decomposition analysis
##
## ------------------------------------------------------------------------

# 1 Rural -----------------------------------------------------------------

sample_women_rural = @subset(sample_women, :urban .== 1)
sample_men_rural = @subset(sample_men, :urban .== 1)
sample_women_married_rural = @subset(sample_women_married, :urban .== 1)

# Number of unmarried women
women_unmarried = @chain sample_women_rural begin
    @subset(:marst .!= "married")
    @groupby(:cohort, :edu4_f)
    @combine(:women_unmarried = length(:edu4_f))
    @select(:cohort, :edu4_f, :women_unmarried)
    sort([:cohort, :edu4_f])
end

# Men's ratio of unmarried to married
men_ratio = combine(
    groupby(sample_men_rural, [:cohort, :edu4_m]),
    # Calculate married and unmarried counts
    :marst => (x -> sum(x .== "married")) => :married,
    :marst => (x -> sum(x .!= "married")) => :unmarried
) 

men_ratio[!, :ratio] = men_ratio.unmarried ./ men_ratio.married

select!(men_ratio, :cohort, :edu4_m, :ratio)

# Women's ratio of unmarried to married
women_ratio = combine(
    groupby(sample_women_rural, [:cohort, :edu4_f]),
    # Calculate married and unmarried counts
    :marst => (x -> sum(x .== "married")) => :married,
    :marst => (x -> sum(x .!= "married")) => :unmarried
) 

women_ratio[!, :ratio] = women_ratio.unmarried ./ women_ratio.married

select!(women_ratio, :cohort, :edu4_f, :ratio)

# Make an empty DataFrame to store results
df = DataFrame(
    collect(
        Iterators.product(
            sample_women_rural.cohort |> unique |> sort,
            1:5,
            1:5
        )
    ) |> vec
)

rename!(df, [:cohort, :edu4_f, :edu4_m])

# Make contingency tables
count_df = @chain sample_women_married_rural begin
    @groupby(:cohort, :edu4_f, :edu4_m)
    @combine(:n = length(:edu4_m))
end

leftjoin!(df, count_df, on=["cohort", "edu4_f", "edu4_m"])
sort!(df, [:cohort, :edu4_f, :edu4_m])

# Compute number of unmarried men at each educational level (counterfactual)
men_unmarried = @chain count_df begin
    # Number of men (married) at each educational level
    @groupby(:cohort, :edu4_m)
    @combine(:men_married = sum(:n))
end

# Number of men (unmarried) at each educational level
leftjoin!(men_unmarried, men_ratio, on=["cohort", "edu4_m"])

men_unmarried = @chain men_unmarried begin
    @transform(:men_unmarried = :men_married .* :ratio)
    @select(:cohort, :edu4_m, :men_unmarried)
end

# Merge number of unmarried men to the contingency table
leftjoin!(df, men_unmarried, on=[:cohort, :edu4_m])
df[!, :n] = coalesce.(df.n, df.men_unmarried)

# Merge number of unmarried women to the contingency table
leftjoin!(df, women_unmarried, on=[:cohort, :edu4_f])
df[!, :n] = coalesce.(df.n, df.women_unmarried)

select!(df, :cohort, :edu4_f, :edu4_m, :n)

# Total number of unmarried women by educational level
women_total = @chain df begin
    @groupby(:cohort, :edu4_f)
    @combine(:women_total = sum(skipmissing(:n)))
end

# Total number of unmarried men by educational level
men_total = @chain df begin
    @groupby(:cohort, :edu4_m)
    @combine(:men_total = sum(skipmissing(:n)))
end

# Merge to the contingency table
leftjoin!(df, women_total, on=[:cohort, :edu4_f])
df[df.edu4_m .== 5, :n] = df[df.edu4_m .== 5, :women_total]
leftjoin!(df, men_total, on=[:cohort, :edu4_m])
df[df.edu4_f .== 5, :n] = df[df.edu4_f .== 5, :men_total]

df[(df.edu4_m .== 5) .& (df.edu4_f .== 5), :n] .= missing

df[!, :n_unrounded] = df.n
df[!, :n] = round.(df.n)
df.n = convert(Vector{Union{Missing, Int}}, df.n)
df.n_unrounded = convert(Vector{Union{Missing, Float64}}, df.n_unrounded)
df[!, :urban] .= 1 # Rural
df_rural = select(df, :urban, :cohort, :edu4_f, :edu4_m, :n, :n_unrounded)

# 2 Urban -----------------------------------------------------------------

sample_women_urban = @subset(sample_women, :urban .== 2)
sample_men_urban = @subset(sample_men, :urban .== 2)
sample_women_married_urban = @subset(sample_women_married, :urban .== 2)

# Number of unmarried women
women_unmarried = @chain sample_women_urban begin
    @subset(:marst .!= "married")
    @groupby(:cohort, :edu4_f)
    @combine(:women_unmarried = length(:edu4_f))
    @select(:cohort, :edu4_f, :women_unmarried)
    sort([:cohort, :edu4_f])
end

# Men's ratio of unmarried to married
men_ratio = combine(
    groupby(sample_men_urban, [:cohort, :edu4_m]),
    # Calculate married and unmarried counts
    :marst => (x -> sum(x .== "married")) => :married,
    :marst => (x -> sum(x .!= "married")) => :unmarried
) 

men_ratio[!, :ratio] = men_ratio.unmarried ./ men_ratio.married

select!(men_ratio, :cohort, :edu4_m, :ratio)

# Women's ratio of unmarried to married
women_ratio = combine(
    groupby(sample_women_urban, [:cohort, :edu4_f]),
    # Calculate married and unmarried counts
    :marst => (x -> sum(x .== "married")) => :married,
    :marst => (x -> sum(x .!= "married")) => :unmarried
) 

women_ratio[!, :ratio] = women_ratio.unmarried ./ women_ratio.married

select!(women_ratio, :cohort, :edu4_f, :ratio)

# Make an empty DataFrame to store results
df = DataFrame(
    collect(
        Iterators.product(
            sample_women_urban.cohort |> unique |> sort,
            1:5,
            1:5
        )
    ) |> vec
)

rename!(df, [:cohort, :edu4_f, :edu4_m])

# Make contingency tables
count_df = @chain sample_women_married_urban begin
    @groupby(:cohort, :edu4_f, :edu4_m)
    @combine(:n = length(:edu4_m))
end

leftjoin!(df, count_df, on=["cohort", "edu4_f", "edu4_m"])
sort!(df, [:cohort, :edu4_f, :edu4_m])

# Compute number of unmarried men at each educational level (counterfactual)
men_unmarried = @chain count_df begin
    # Number of men (married) at each educational level
    @groupby(:cohort, :edu4_m)
    @combine(:men_married = sum(:n))
end

# Number of men (unmarried) at each educational level
leftjoin!(men_unmarried, men_ratio, on=["cohort", "edu4_m"])

men_unmarried = @chain men_unmarried begin
    @transform(:men_unmarried = :men_married .* :ratio)
    @select(:cohort, :edu4_m, :men_unmarried)
end

# Merge number of unmarried men to the contingency table
leftjoin!(df, men_unmarried, on=[:cohort, :edu4_m])
df[!, :n] = coalesce.(df.n, df.men_unmarried)

# Merge number of unmarried women to the contingency table
leftjoin!(df, women_unmarried, on=[:cohort, :edu4_f])
df[!, :n] = coalesce.(df.n, df.women_unmarried)

select!(df, :cohort, :edu4_f, :edu4_m, :n)

# Total number of unmarried women by educational level
women_total = @chain df begin
    @groupby(:cohort, :edu4_f)
    @combine(:women_total = sum(skipmissing(:n)))
end

# Total number of unmarried men by educational level
men_total = @chain df begin
    @groupby(:cohort, :edu4_m)
    @combine(:men_total = sum(skipmissing(:n)))
end

# Merge to the contingency table
leftjoin!(df, women_total, on=[:cohort, :edu4_f])
df[df.edu4_m .== 5, :n] = df[df.edu4_m .== 5, :women_total]
leftjoin!(df, men_total, on=[:cohort, :edu4_m])
df[df.edu4_f .== 5, :n] = df[df.edu4_f .== 5, :men_total]

df[(df.edu4_m .== 5) .& (df.edu4_f .== 5), :n] .= missing

df[!, :n_unrounded] = df.n
df[!, :n] = round.(df.n)
df.n = convert(Vector{Union{Missing, Int}}, df.n)
df.n_unrounded = convert(Vector{Union{Missing, Float64}}, df.n_unrounded)
df[!, :urban] .= 2 # urban
df_urban = select(df, :urban, :cohort, :edu4_f, :edu4_m, :n, :n_unrounded)

df = vcat(df_rural, df_urban)

# Save the data
write_parquet("outputs/tables/urban-rural/df_for_decomp.parquet", df)
