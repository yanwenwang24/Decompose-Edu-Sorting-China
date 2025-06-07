## ------------------------------------------------------------------------
##
## Script name: 01_tidy_82.jl
## Purpose: Clean Census 1982 data
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Census 1982 was downloaded from IPUMS International.
##
## ------------------------------------------------------------------------

# 1 Load data ---------------------------------------------------------------      

# Read parquet file
census_1982 = DataFrame(read_parquet("data/raw/census_1982.parquet"))

# 2 Clean data --------------------------------------------------------------

# 2.1 Select variables of interest ------------------------------------------

# Year and geographical information
census_1982 = @chain census_1982 begin
    @transform(
        :year = Int.(:year),
        :province = lpad.(Int.(:geo1_cn .% 156000), 2, "0"),
        :district = lpad.(Int.(:geo2_cn .% (:geo1_cn .* 1000)), 2, "0"),
        :hhnumber = lpad.(Int.(:serial), 10, "0"),
        :hhsize = Int.(:persons)
    )
    @transform(
        :region = get.(Ref(region_dict), :province, missing),
        :prefecture = string.(:province, :district),
        :hhid = string.(:year, :province, :district, :hhnumber)
    )
end

# Group quarter
census_1982 = @chain census_1982 begin
    @transform(
        :gq = recode(
            :gq,
            10 => 0, # households
            20 => 1, # group quarters
            29 => 0, # 1-person unit created by splitting large household
            missing => missing
        )
    )
end

# Demographics (gender, age, birth year, marital status)
census_1982 = @chain census_1982 begin
    @transform(:female = ifelse.(Int.(:sex) .== 1, 0, 1))
    @transform(:age = Int.(:age))
    @transform(:age = ifelse.(:age .== 999, missing, :age))
    @transform(:birthy = :year - :age)
    @transform(:marst = get.(Ref(marst_dict), :marst, missing))
end

# Education
census_1982 = @chain census_1982 begin
    @transform(
        :edu6 = recode(
            :cn1982a_educ,
            0 => missing,
            1 => 6, # College
            2 => 5, # Some college
            3 => 4, # Secondary
            4 => 3, # Junior Middle
            5 => 2, # Primary
            6 => 1, # Illiterate
            9 => missing,
            missing => missing
        ),
        :edu5 = recode(
            :cn1982a_educ,
            0 => missing,
            1 => 5, # College
            2 => 4, # Some college
            3 => 3, # Secondary
            4 => 2, # Junior Middle
            5 => 1, # Primary or less
            6 => 1, # Primary or less
            9 => missing,
            missing => missing
        ),
        :edu4 = recode(
            :cn1982a_educ,
            0 => missing,
            1 => 4, # Some college or higher
            2 => 4, # Some college or higher
            3 => 3, # Secondary
            4 => 2, # Junior Middle
            5 => 1, # Primary or less
            6 => 1, # Primary or less
            9 => missing,
            missing => missing
        )
    )
end

# Relationships
census_1982 = @chain census_1982 begin
    @transform(
        :pernum = Int.(:pernum),
        :headloc = Int.(:headloc),
        :sploc = Int.(:sploc),
        :relate = Int.(:relate)
    )
end

# Select variables of interest
select!(
    census_1982,
    :year,
    :hhid,
    :region,
    :province,
    :district,
    :prefecture,
    :hhnumber,
    :hhsize,
    :gq,
    :pernum,
    :headloc,
    :sploc,
    :relate,
    :female,
    :age,
    :birthy,
    :marst,
    :edu6,
    :edu5,
    :edu4
)

# 2.2 Spousal information ----------------------------------------------------

# Information needed for spouse
df = @select(
    census_1982,
    :hhid,
    :pernum,
    :sploc,
    :female,
    :age,
    :birthy,
    :edu6,
    :edu5,
    :edu4,
)

# Identify spousal information using `pernum` to `sploc` linkage
sp_df = leftjoin(
    df, df,
    on=[:hhid => :hhid, :pernum => :sploc],
    renamecols="" => "_sp"
)

@select!(
    sp_df,
    :hhid,
    :pernum,
    :age_sp,
    :birthy_sp,
    :edu6_sp,
    :edu5_sp,
    :edu4_sp
)

# Merge spousal information back to main dataset
leftjoin!(census_1982, sp_df, on=[:hhid, :pernum])

# Identiy male and female information
@transform!(
    census_1982,
    :age_m = ifelse.(:female .== 0, :age, :age_sp),
    :age_f = ifelse.(:female .== 0, :age_sp, :age),
    :birthy_m = ifelse.(:female .== 0, :birthy, :birthy_sp),
    :birthy_f = ifelse.(:female .== 0, :birthy_sp, :birthy),
    :edu6_m = ifelse.(:female .== 0, :edu6, :edu6_sp),
    :edu6_f = ifelse.(:female .== 0, :edu6_sp, :edu6),
    :edu5_m = ifelse.(:female .== 0, :edu5, :edu5_sp),
    :edu5_f = ifelse.(:female .== 0, :edu5_sp, :edu5),
    :edu4_m = ifelse.(:female .== 0, :edu4, :edu4_sp),
    :edu4_f = ifelse.(:female .== 0, :edu4_sp, :edu4)
)

# 3 Save data ---------------------------------------------------------------

write_parquet("data/processed/census_1982.parquet", census_1982)
