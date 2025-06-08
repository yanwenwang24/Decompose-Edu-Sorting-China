## ------------------------------------------------------------------------
##
## Script name: 03_tidy_00.jl
## Purpose: Clean Census 2000 data
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Census 2000 was downloaded from IPUMS International.
##
## ------------------------------------------------------------------------

# 1 Load data ---------------------------------------------------------------      

# Read parquet file
census_2000 = DataFrame(read_parquet("data/raw/census_2000.parquet"))

# 2 Clean data --------------------------------------------------------------

# 2.1 Select variables of interest ------------------------------------------

# Year and geographical information
census_2000 = @chain census_2000 begin
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
    @transform(
        # 1 = rural, 2 = urban
        :urban = Int.(:urban),
    )
end

# Group quarter
census_2000 = @chain census_2000 begin
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
census_2000 = @chain census_2000 begin
    @transform(:female = ifelse.(Int.(:sex) .== 1, 0, 1))
    @transform(:age = Int.(:age))
    @transform(:age = ifelse.(:age .== 999, missing, :age))
    @transform(:birthy = :year - :age)
    @transform(:marst = get.(Ref(marst_dict), :marst, missing))
    @transform(:maryr = ifelse.(:marryr .>= 2020, missing, :marryr))
end

# Hukou status
census_2000 = @chain census_2000 begin
    @transform(:cn2000a_regtype = Int.(:cn2000a_regtype))
    @transform(
        :hukou = recode(
            :cn2000a_regtype,
            1 => 1, # Agricultural
            2 => 2, # Non-agricultural
            9 => missing,
            missing => missing
        )
    )
end

# Education
census_2000 = @chain census_2000 begin
    @transform(
        :edu7 = recode(
            :cn2000a_edattain,
            0 => missing,
            1 => 1, # Illiterate
            2 => 1, # Illiterate
            3 => 2, # Primary
            4 => 3, # Junior Middle
            5 => 4, # Secondary
            6 => 4, # Secondary
            7 => 5, # Some college
            8 => 6, # College
            9 => 7, # Graduate
            missing => missing
        ),
        :edu6 = recode(
            :cn2000a_edattain,
            0 => missing,
            1 => 1, # Illiterate
            2 => 1, # Illiterate
            3 => 2, # Primary
            4 => 3, # Junior Middle
            5 => 4, # Secondary
            6 => 4, # Secondary
            7 => 5, # Some college
            8 => 6, # College
            9 => 6, # College
            missing => missing
        ),
        :edu5 = recode(
            :cn2000a_edattain,
            0 => missing,
            1 => 1, # Primary or less
            2 => 1, # Primary or less
            3 => 1, # Primary or less
            4 => 2, # Junior Middle
            5 => 3, # Secondary
            6 => 3, # Secondary
            7 => 4, # Some college
            8 => 5, # College
            9 => 5, # College
            missing => missing
        ),
        :edu4 = recode(
            :cn2000a_edattain,
            0 => missing,
            1 => 1, # Primary or less
            2 => 1, # Primary or less
            3 => 1, # Primary or less
            4 => 2, # Junior Middle
            5 => 3, # Secondary
            6 => 3, # Secondary
            7 => 4, # College
            8 => 4, # College
            9 => 4, # College
            missing => missing
        )
    )
end

# Relationships
census_2000 = @chain census_2000 begin
    @transform(
        :pernum = Int.(:pernum),
        :headloc = Int.(:headloc),
        :sploc = Int.(:sploc),
        :relate = Int.(:relate)
    )
end

# Select variables of interest
select!(
    census_2000,
    :year,
    :hhid,
    :region,
    :province,
    :district,
    :prefecture,
    :urban,
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
    :maryr,
    :hukou,
    :edu7,
    :edu6,
    :edu5,
    :edu4
)

# 2.2 Spousal information ----------------------------------------------------

# Information needed for spouse
df = @select(
    census_2000,
    :hhid,
    :pernum,
    :sploc,
    :female,
    :age,
    :birthy,
    :hukou,
    :maryr,
    :edu7,
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
    :maryr_sp,
    :edu7_sp,
    :edu6_sp,
    :edu5_sp,
    :edu4_sp
)

# Merge spousal information back to main dataset
leftjoin!(census_2000, sp_df, on=[:hhid, :pernum])

# Identiy male and female information
@transform!(
    census_2000,
    :age_m = ifelse.(:female .== 0, :age, :age_sp),
    :age_f = ifelse.(:female .== 0, :age_sp, :age),
    :birthy_m = ifelse.(:female .== 0, :birthy, :birthy_sp),
    :birthy_f = ifelse.(:female .== 0, :birthy_sp, :birthy),
    :hukou_m = ifelse.(:female .== 0, :hukou, :hukou_sp),
    :hukou_f = ifelse.(:female .== 0, :hukou_sp, :hukou),
    :maryr_m = ifelse.(:female .== 0, :maryr, :maryr_sp),
    :maryr_f = ifelse.(:female .== 0, :maryr_sp, :maryr),
    :edu7_m = ifelse.(:female .== 0, :edu7, :edu7_sp),
    :edu7_f = ifelse.(:female .== 0, :edu7_sp, :edu7),
    :edu6_m = ifelse.(:female .== 0, :edu6, :edu6_sp),
    :edu6_f = ifelse.(:female .== 0, :edu6_sp, :edu6),
    :edu5_m = ifelse.(:female .== 0, :edu5, :edu5_sp),
    :edu5_f = ifelse.(:female .== 0, :edu5_sp, :edu5),
    :edu4_m = ifelse.(:female .== 0, :edu4, :edu4_sp),
    :edu4_f = ifelse.(:female .== 0, :edu4_sp, :edu4)
)

# 3 Save data ---------------------------------------------------------------

write_parquet("data/processed/census_2000.parquet", census_2000)
