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

# Combine cleaned data
census = vcat(census_1982, census_1990, census_2000, census_2010)

# 2 Educational pair ------------------------------------------------------

edu_pair = Vector{Union{String,Missing}}(undef, nrow(census))
homo = Vector{Union{Int,Missing}}(undef, nrow(census))
heter = Vector{Union{Int,Missing}}(undef, nrow(census))
hyper = Vector{Union{Int,Missing}}(undef, nrow(census))
hypo = Vector{Union{Int,Missing}}(undef, nrow(census))

for i in 1:nrow(census)
    m = census.edu_m[i]
    f = census.edu_f[i]

    if ismissing(m) || ismissing(f)
        edu_pair[i] = missing
        homo[i] = missing
        heter[i] = missing
        hyper[i] = missing
        hypo[i] = missing
    elseif m == f
        edu_pair[i] = "homo"
        homo[i] = 1
        heter[i] = 0
        hyper[i] = 0
        hypo[i] = 0
    elseif m > f
        edu_pair[i] = "hyper"
        homo[i] = 0
        heter[i] = 1
        hyper[i] = 1
        hypo[i] = 0
    elseif m < f
        edu_pair[i] = "hypo"
        homo[i] = 0
        heter[i] = 1
        hyper[i] = 0
        hypo[i] = 1
    end
end

census[!, :edu_pair] = edu_pair
census[!, :homo] = homo
census[!, :heter] = heter
census[!, :hyper] = hyper
census[!, :hypo] = hypo

# 3 Save ------------------------------------------------------------------

Arrow.write("Data_clean/census.arrow", census)