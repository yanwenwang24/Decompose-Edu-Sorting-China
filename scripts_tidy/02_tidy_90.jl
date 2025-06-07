## ------------------------------------------------------------------------
##
## Script name: 02_tidy_90.jl
## Purpose: Clean Census 1990 data
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Census 1990 was downloaded from IPUMS International.
##
## ------------------------------------------------------------------------

# 1 Load data ---------------------------------------------------------------      

# Read parquet file
census_1990 = DataFrame(read_parquet("data/raw/census_1990.parquet"))

# 2 Clean data --------------------------------------------------------------

# 2.1 Select variables of interest ------------------------------------------

# Year and geographical information
census_1990 = @chain census_1990 begin
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
census_1990 = @chain census_1990 begin
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
census_1990 = @chain census_1990 begin
    @transform(:female = ifelse.(Int.(:sex) .== 1, 0, 1))
    @transform(:age = Int.(:age))
    @transform(:age = ifelse.(:age .== 999, missing, :age))
    @transform(:birthy = :year - :age)
    @transform(:marst = get.(Ref(marst_dict), :marst, missing))
end

# Hukou status
census_1990 = @chain census_1990 begin
    @transform(:cn1990a_hhtyap = Int.(:cn1990a_hhtyap))
    @transform(
        :hukou = recode(
            :cn1990a_hhtyap,
            0 => missing,
            1 => 1, # Agricultural
            2 => 2, # Non-agricultural
            missing => missing
        )
    )
end

# Education
census_1990 = @chain census_1990 begin
    @transform(
        :edu6 = recode(
            :cn1990a_edlev1,
            0 => missing,
            1 => 1, # Illiterate
            2 => 2, # Primary
            3 => 3, # Junior Middle
            4 => 4, # Secondary
            5 => 4, # Secondary
            6 => 5, # Some college
            7 => 6, # College
            missing => missing
        ),
        :edu5 = recode(
            :cn1990a_edlev1,
            0 => missing,
            1 => 1, # Primary or less
            2 => 1, # Primary or less
            3 => 2, # Junior Middle
            4 => 3, # Secondary
            5 => 3, # Secondary
            6 => 4, # Some college
            7 => 5, # College
            missing => missing
        ),
        :edu4 = recode(
            :cn1990a_edlev1,
            0 => missing,
            1 => 1, # Primary or less
            2 => 1, # Primary or less
            3 => 2, # Junior Middle
            4 => 3, # Secondary
            5 => 3, # Secondary
            6 => 4, # Some college
            7 => 4, # College
            missing => missing
        )
    )
end

# Relationships
census_1990 = @chain census_1990 begin
    @transform(
        :pernum = Int.(:pernum),
        :headloc = Int.(:headloc),
        :sploc = Int.(:sploc),
        :relate = Int.(:relate)
    )
end

# Select variables of interest
select!(
    census_1990,
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
    :hukou,
    :edu6,
    :edu5,
    :edu4
)

# 2.2 Spousal information ----------------------------------------------------

# Information needed for spouse
df = @select(
    census_1990,
    :hhid,
    :pernum,
    :sploc,
    :female,
    :age,
    :birthy,
    :hukou,
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
    :hukou_sp,
    :edu6_sp,
    :edu5_sp,
    :edu4_sp
)

# Merge spousal information back to main dataset
leftjoin!(census_1990, sp_df, on=[:hhid, :pernum])

# Identiy male and female information
@transform!(
    census_1990,
    :age_m = ifelse.(:female .== 0, :age, :age_sp),
    :age_f = ifelse.(:female .== 0, :age_sp, :age),
    :birthy_m = ifelse.(:female .== 0, :birthy, :birthy_sp),
    :birthy_f = ifelse.(:female .== 0, :birthy_sp, :birthy),
    :hukou_m = ifelse.(:female .== 0, :hukou, :hukou_sp),
    :hukou_f = ifelse.(:female .== 0, :hukou_sp, :hukou),
    :edu6_m = ifelse.(:female .== 0, :edu6, :edu6_sp),
    :edu6_f = ifelse.(:female .== 0, :edu6_sp, :edu6),
    :edu5_m = ifelse.(:female .== 0, :edu5, :edu5_sp),
    :edu5_f = ifelse.(:female .== 0, :edu5_sp, :edu5),
    :edu4_m = ifelse.(:female .== 0, :edu4, :edu4_sp),
    :edu4_f = ifelse.(:female .== 0, :edu4_sp, :edu4)
)

# 3 Save data ---------------------------------------------------------------

write_parquet("data/processed/census_1990.parquet", census_1990)
