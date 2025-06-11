## ------------------------------------------------------------------------
##
## Script name: 05_tidy_merge.jl
## Purpose: Merge cleaned data
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Combine cleaned data --------------------------------------------------

# Load cleaned data
census_1982 = DataFrame(read_parquet("data/processed/census_1982.parquet"))
census_1990 = DataFrame(read_parquet("data/processed/census_1990.parquet"))
census_2000 = DataFrame(read_parquet("data/processed/census_2000.parquet"))
census_2010 = DataFrame(read_parquet("data/processed/census_2010.parquet"))

# Combine cleaned data
census = vcat_complete_columns(
    census_1982,
    census_1990,
    census_2000,
    census_2010
)

# 2 Educational pair ------------------------------------------------------

edu7_pair = Vector{Union{String,Missing}}(undef, nrow(census))
homo7 = Vector{Union{Int,Missing}}(undef, nrow(census))
heter7 = Vector{Union{Int,Missing}}(undef, nrow(census))
hyper7 = Vector{Union{Int,Missing}}(undef, nrow(census))
hypo7 = Vector{Union{Int,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.edu7_m[i]
    f = census.edu7_f[i]

    if ismissing(m) || ismissing(f)
        edu7_pair[i] = missing
        homo7[i] = missing
        heter7[i] = missing
        hyper7[i] = missing
        hypo7[i] = missing
    elseif m == f
        edu7_pair[i] = "homo"
        homo7[i] = 1
        heter7[i] = 0
        hyper7[i] = 0
        hypo7[i] = 0
    elseif m > f
        edu7_pair[i] = "hyper"
        homo7[i] = 0
        heter7[i] = 1
        hyper7[i] = 1
        hypo7[i] = 0
    elseif m < f
        edu7_pair[i] = "hypo"
        homo7[i] = 0
        heter7[i] = 1
        hyper7[i] = 0
        hypo7[i] = 1
    end
end

census[!, :edu7_pair] = edu7_pair
census[!, :homo7] = homo7
census[!, :heter7] = heter7
census[!, :hyper7] = hyper7
census[!, :hypo7] = hypo7

edu6_pair = Vector{Union{String,Missing}}(undef, nrow(census))
homo6 = Vector{Union{Int,Missing}}(undef, nrow(census))
heter6 = Vector{Union{Int,Missing}}(undef, nrow(census))
hyper6 = Vector{Union{Int,Missing}}(undef, nrow(census))
hypo6 = Vector{Union{Int,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.edu6_m[i]
    f = census.edu6_f[i]

    if ismissing(m) || ismissing(f)
        edu6_pair[i] = missing
        homo6[i] = missing
        heter6[i] = missing
        hyper6[i] = missing
        hypo6[i] = missing
    elseif m == f
        edu6_pair[i] = "homo"
        homo6[i] = 1
        heter6[i] = 0
        hyper6[i] = 0
        hypo6[i] = 0
    elseif m > f
        edu6_pair[i] = "hyper"
        homo6[i] = 0
        heter6[i] = 1
        hyper6[i] = 1
        hypo6[i] = 0
    elseif m < f
        edu6_pair[i] = "hypo"
        homo6[i] = 0
        heter6[i] = 1
        hyper6[i] = 0
        hypo6[i] = 1
    end
end

census[!, :edu6_pair] = edu6_pair
census[!, :homo6] = homo6
census[!, :heter6] = heter6
census[!, :hyper6] = hyper6
census[!, :hypo6] = hypo6

edu5_pair = Vector{Union{String,Missing}}(undef, nrow(census))
homo5 = Vector{Union{Int,Missing}}(undef, nrow(census))
heter5 = Vector{Union{Int,Missing}}(undef, nrow(census))
hyper5 = Vector{Union{Int,Missing}}(undef, nrow(census))
hypo5 = Vector{Union{Int,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.edu5_m[i]
    f = census.edu5_f[i]

    if ismissing(m) || ismissing(f)
        edu5_pair[i] = missing
        homo5[i] = missing
        heter5[i] = missing
        hyper5[i] = missing
        hypo5[i] = missing
    elseif m == f
        edu5_pair[i] = "homo"
        homo5[i] = 1
        heter5[i] = 0
        hyper5[i] = 0
        hypo5[i] = 0
    elseif m > f
        edu5_pair[i] = "hyper"
        homo5[i] = 0
        heter5[i] = 1
        hyper5[i] = 1
        hypo5[i] = 0
    elseif m < f
        edu5_pair[i] = "hypo"
        homo5[i] = 0
        heter5[i] = 1
        hyper5[i] = 0
        hypo5[i] = 1
    end
end

census[!, :edu5_pair] = edu5_pair
census[!, :homo5] = homo5
census[!, :heter5] = heter5
census[!, :hyper5] = hyper5
census[!, :hypo5] = hypo5

edu4_pair = Vector{Union{String,Missing}}(undef, nrow(census))
homo4 = Vector{Union{Int,Missing}}(undef, nrow(census))
heter4 = Vector{Union{Int,Missing}}(undef, nrow(census))
hyper4 = Vector{Union{Int,Missing}}(undef, nrow(census))
hypo4 = Vector{Union{Int,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.edu4_m[i]
    f = census.edu4_f[i]

    if ismissing(m) || ismissing(f)
        edu4_pair[i] = missing
        homo4[i] = missing
        heter4[i] = missing
        hyper4[i] = missing
        hypo4[i] = missing
    elseif m == f
        edu4_pair[i] = "homo"
        homo4[i] = 1
        heter4[i] = 0
        hyper4[i] = 0
        hypo4[i] = 0
    elseif m > f
        edu4_pair[i] = "hyper"
        homo4[i] = 0
        heter4[i] = 1
        hyper4[i] = 1
        hypo4[i] = 0
    elseif m < f
        edu4_pair[i] = "hypo"
        homo4[i] = 0
        heter4[i] = 1
        hyper4[i] = 0
        hypo4[i] = 1
    end
end

census[!, :edu4_pair] = edu4_pair
census[!, :homo4] = homo4
census[!, :heter4] = heter4
census[!, :hyper4] = hyper4
census[!, :hypo4] = hypo4

# 4 Save ------------------------------------------------------------------

write_parquet("data/processed/census.parquet", census)
