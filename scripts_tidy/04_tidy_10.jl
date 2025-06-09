## ------------------------------------------------------------------------
##
## Script name: 04_tidy_10.jl
## Purpose: Clean Census 2010 data
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes: Census 2010 was in Chinese.
## Spousal location needs to be identified manually.
##
## ------------------------------------------------------------------------

# 1 Load data ---------------------------------------------------------------      

# Read parquet file
census_2010 = DataFrame(read_parquet("data/raw/census_2010.parquet"))

# Read area code file
area_code = DataFrame(XLSX.readtable("data/raw/area_code_2009.xlsx", "Sheet1"))

# 2 Clean data --------------------------------------------------------------

# 2.1 Select variables of interest ------------------------------------------

# Year and geographic information
census_2010 = @chain census_2010 begin
    @transform(:year = 2010)
    @transform(
        :province = string.(parse.(Int, :地址码) .÷ 100000000000 .÷ 100),
        :district = lpad.(parse.(Int, :地址码) .÷ 100000000000 .% 100, 2, "0"),
        :hhnumber = string.(:户编码),
        :hhsize = :当晚居住本户的人数
    )
    @transform(
        :region = get.(Ref(region_dict), :province, missing),
        :prefecture = string.(:province, :district),
        :hhid = string.(:year, :户编码)
    )
end

# Urban vs. rural residence
area_code = @chain area_code begin
    @transform begin
        :urban = [startswith(string(x), "1") ? 2 :
                  startswith(string(x), "2") ? 1 : missing
                  for x in :code_urban]
        :code = string.(:code)
    end
    @select(:code, :urban)
end

census_2010 = @chain census_2010 begin
    @transform :code = [ismissing(x) ? missing : x[1:end-3] for x in :地址码]
end

leftjoin!(census_2010, area_code, on=[:code])

# Group quarter
census_2010 = @chain census_2010 begin
    @transform(
        :gq = recode(
            :户别, # Whether group quarter (collective living)
            1 => 0,
            2 => 1,
            missing => missing
        )
    )
end

# Demographics
census_2010 = @chain census_2010 begin
    @transform(:female = ifelse.(:性别 .== 1, 0, 1))
    @transform(:age = Int.(:周岁年龄))
    @transform(:birthy = Int.(:出生年))
    @transform(:relate = Int.(:与户主关系))
    @transform(:marst = get.(Ref(marst_dict), :婚姻状况, missing))
    @transform(:maryr = :结婚初婚年)
end

# Hukou status
census_2010 = @chain census_2010 begin
    @transform(
        :hukou = recode(
            :户口性质,
            1 => 1, # Agricultural
            2 => 2, # Non-agricultural
            missing => missing
        )
    )
end

# Urban/rural status at the time of first marriage
# --- Step 1: impuate peak marriae year for those missing `maryr` ---
census_2010.cohort = floor.(census_2010.birthy / 5) * 5

cohort_mar_stats = @chain census_2010 begin
    @rsubset !ismissing(:maryr)
    @by(
        [:female, :cohort],
        :median_maryr = round(Int, median(:maryr))
    )
end

leftjoin!(census_2010, cohort_mar_stats, on=[:female, :cohort])

census_2010 = @chain census_2010 begin
    @transform(:peak_mar_yr = coalesce.(:maryr, :median_maryr))
end

# --- Step 2: determine urban/rural status at the time of first marriage ---
census_2010 = @chain census_2010 begin
    @rtransform :marurban = determine_urban_2010(
        :year,
        :peak_mar_yr,
        :urban,
        :离开户口登记地时间,
        :户口登记地类型
    )
end

# Education
census_2010 = @chain census_2010 begin
    @transform(
        :edu7 = recode(
            :受教育程度,
            1 => 1, # Illiterate
            2 => 2, # Primary
            3 => 3, # Junior Middle
            4 => 4, # Secondary
            5 => 5, # Some college
            6 => 6, # College
            7 => 7, # Graduate
            missing => missing
        ),
        :edu6 = recode(
            :受教育程度,
            1 => 1, # Illiterate
            2 => 2, # Primary
            3 => 3, # Junior Middle
            4 => 4, # Secondary
            5 => 5, # Some college
            6 => 6, # College
            7 => 6, # College
            missing => missing
        ),
        :edu5 = recode(
            :受教育程度,
            1 => 1, # Primary or less
            2 => 1, # Primary or less
            3 => 2, # Junior Middle
            4 => 3, # Secondary
            5 => 4, # Some college
            6 => 5, # College
            7 => 5, # College
            missing => missing
        ),
        :edu4 = recode(
            :受教育程度,
            1 => 1, # Primary or less
            2 => 1, # Primary or less
            3 => 2, # Junior Middle
            4 => 3, # Secondary
            5 => 4, # College
            6 => 4, # College
            7 => 4, # College
            missing => missing
        )
    )
end

# 2.2 Select variables ----------------------------------------------------

select!(
    census_2010,
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
    :relate,
    :female,
    :age,
    :birthy,
    :marst,
    :maryr,
    :marurban,
    :hukou,
    :edu7,
    :edu6,
    :edu5,
    :edu4
)

# 2.3 Head location -------------------------------------------------------

# Add pernum within each household
census_2010 = @chain census_2010 begin
    @groupby(:hhid)
    @transform(:pernum = 1:length(:hhid))
end

# Identify head location within each household
headloc_df = @chain census_2010 begin
    @subset(:relate .== 0)
    @select(:hhid, :pernum)
    @rename(:headloc = :pernum)
end

leftjoin!(census_2010, headloc_df, on=:hhid)

# 2.4 Spousal location ----------------------------------------------------

# 2.4.1 Head & spouse -----------------------------------------------------

# Rule 1: head (relate == 0) and spouse (relate == 1)
# Extract heads
heads_df = @chain census_2010 begin
    @subset(:relate .== 0)
    @select(:hhid, :pernum)
    @rename(:head_pernum = :pernum)
end

# Extract spouses
spouses_df = @chain census_2010 begin
    @subset(:relate .== 1)
    @select(:hhid, :pernum)
    @rename(:sp_pernum = :pernum)
end

head_spouse_df = innerjoin(heads_df, spouses_df, on=:hhid)

# Prepare DataFrames for merging back
head_sploc_df = @chain head_spouse_df begin
    @rename(:pernum = :head_pernum, :sploc = :sp_pernum)
    # Remove duplicate `hhid` if multiple heads (keep first occurence)
    unique(:hhid)
end

spouse_sploc_df = @chain head_spouse_df begin
    @rename(:pernum = :sp_pernum, :sploc = :head_pernum)
    # Remove duplicate `hhid` if multiple spouses (keep first occurence)
    unique(:hhid)
end

sploc_df = vcat(head_sploc_df, spouse_sploc_df)

# Merge back
leftjoin!(census_2010, sploc_df, on=[:hhid, :pernum])

# 2.4.2 Parent & parent ---------------------------------------------------

# Rule 2: parent and parent (relate == 3)
# Extract parents
parents_df = @chain census_2010 begin
    @subset(:relate .== 3)
    @select(:hhid, :pernum)
end

# Self-join parents to find the other parent
parents_sploc_df = innerjoin(parents_df, parents_df, on=:hhid, makeunique=true)

# Exclude self matches
parents_sploc_df = @chain parents_sploc_df begin
    @subset(:pernum .!= :pernum_1)
    @select(:hhid, :pernum, :pernum_1)
    @rename(:sploc = :pernum_1)
end

# Merge sploc back to main dataset
leftjoin!(census_2010, parents_sploc_df, on=[:hhid, :pernum], makeunique=true)
@transform!(census_2010, :sploc = coalesce.(:sploc, :sploc_1))
select!(census_2010, Not(:sploc_1))

# 2.4.3 Parent-in-law & parent-in-law -------------------------------------

# Rule 3: Parent-in-law and parent-in-law (relate == 4)
# Extract parents-in-law
parents_in_law_df = @chain census_2010 begin
    @subset(:relate .== 4)
    @select(:hhid, :pernum, :maryr)
end

# Count parents-in-law
parents_in_law_counts = @chain parents_in_law_df begin
    @groupby(:hhid)
    @combine(:n_parents_in_law = length(:pernum))
end

# Single-match households (with two parents-in-law)
## Identify single-match households
single_match_hhids = @chain parents_in_law_counts begin
    @subset(:n_parents_in_law .== 2)
    @select(:hhid)
end

parents_in_law_single_df = semijoin(
    parents_in_law_df,
    single_match_hhids,
    on=:hhid
)

## Self-join to find the other parent-in-law
parents_in_law_single_sploc_df = innerjoin(
    parents_in_law_single_df, parents_in_law_single_df,
    on=:hhid, makeunique=true
)

## Exclude self matches
parents_in_law_single_sploc_df = @chain parents_in_law_single_sploc_df begin
    @subset(:pernum .!= :pernum_1)
    @select(:hhid, :pernum, :pernum_1)
    @rename(:sploc = :pernum_1)
end

# Multiple-match households (with more than two parents-in-law)
## Identify multiple-match households
multiple_match_hhids = @chain parents_in_law_counts begin
    @subset(:n_parents_in_law .> 2)
    @select(:hhid)
end

## Skip multiple-match households because none

# Merge back
leftjoin!(
    census_2010, parents_in_law_single_sploc_df,
    on=[:hhid, :pernum], makeunique=true
)
@transform!(census_2010, :sploc = coalesce.(:sploc, :sploc_1))
select!(census_2010, Not(:sploc_1))

# 2.4.4 Grandparent & grandparent -----------------------------------------

# Rule 4: Grandparent and grandparent (relate == 5)
# Extract grandparents
grandparents_df = @chain census_2010 begin
    @subset(:relate .== 5)
    @select(:hhid, :pernum, :maryr)
end

# Count grandparents
grandparents_counts = @chain grandparents_df begin
    @groupby(:hhid)
    @combine(:n_grandparents = length(:pernum))
end

# Single-match households (with two grandparents)
## Identify single-match households
single_match_hhids = @chain grandparents_counts begin
    @subset(:n_grandparents .== 2)
    @select(:hhid)
end

grandparents_single_df = semijoin(
    grandparents_df,
    single_match_hhids,
    on=:hhid
)

## Self-join to find the other grandparent
grandparents_single_sploc_df = innerjoin(
    grandparents_single_df, grandparents_single_df,
    on=:hhid, makeunique=true
)

## Exclude self matches
grandparents_single_sploc_df = @chain grandparents_single_sploc_df begin
    @subset(:pernum .!= :pernum_1)
    @select(:hhid, :pernum, :pernum_1)
    @rename(:sploc = :pernum_1)
end

# Multiple-match households (with more than two grandparents)
## Identify multiple-match households
multiple_match_hhids = @chain grandparents_counts begin
    @subset(:n_grandparents .> 2)
    @select(:hhid)
end

## Match by year of first marriage
grandparents_multiple_df = semijoin(
    grandparents_df, multiple_match_hhids,
    on=:hhid
)

## Group by `hhid` and `maryr`
grouped_df = groupby(grandparents_multiple_df, [:hhid, :maryr])

## Apply function create_matches() to each group
grandparents_multiple_sploc_df = combine(grouped_df, create_parent_matches)
select!(grandparents_multiple_sploc_df, [:hhid, :pernum, :sploc])

# Combine and merge back
grandparents_sploc_df = vcat(
    grandparents_single_sploc_df,
    grandparents_multiple_sploc_df
)

leftjoin!(
    census_2010, grandparents_sploc_df,
    on=[:hhid, :pernum], makeunique=true
)
@transform!(census_2010, :sploc = coalesce.(:sploc, :sploc_1))
select!(census_2010, Not(:sploc_1))

# 2.4.5 Child & child-in-law ----------------------------------------------

# Rule 5: child (relate == 2) and child-in-law (relate == 6)
# Extract married children
children_df = @chain census_2010 begin
    @subset(:relate .== 2, :marst .== "married")
    @select(:hhid, :pernum, :maryr)
end

# Extract married children-in-law
children_in_law_df = @chain census_2010 begin
    @subset(:relate .== 6, :marst .== "married")
    @select(:hhid, :pernum, :maryr)
end

# Count married children
children_counts = @chain children_df begin
    @groupby(:hhid)
    @combine(:n_children = length(:pernum))
end

# Count married children-in-law
children_in_law_counts = @chain children_in_law_df begin
    @groupby(:hhid)
    @combine(:n_children_in_law = length(:pernum))
end

counts = leftjoin(children_counts, children_in_law_counts, on=:hhid)

# Single-match households (with one child and one child-in-law)
## Identify single-match households
single_match_hhids = @chain counts begin
    @subset(:n_children .== 1, :n_children_in_law .== 1)
    @select(:hhid)
end

## Married children and children-in-law in single-match households
children_single_df = semijoin(children_df, single_match_hhids, on=:hhid)
children_in_law_single_df = semijoin(
    children_in_law_df,
    single_match_hhids,
    on=:hhid
)

single_matches_df = innerjoin(
    children_single_df,
    children_in_law_single_df,
    on=:hhid, makeunique=true
)

## Assign `sploc` for children and children-in-law
children_single_sploc_df = @chain single_matches_df begin
    @select(:hhid, :pernum, :pernum_1)
    @rename(:sploc = :pernum_1)
end

children_in_law_single_sploc_df = @chain single_matches_df begin
    @select(:hhid, :pernum_1, :pernum)
    @rename(
        :pernum = :pernum_1,
        :sploc = :pernum
    )
end

children_single_sploc_df = vcat(
    children_single_sploc_df,
    children_in_law_single_sploc_df
)

# Multiple-match households (with more than one child and one child-in-law)
## Identify multiple-match households
multiple_match_hhids = @chain counts begin
    @subset(
        :n_children .>= 1,
        :n_children_in_law .>= 1,
        :n_children .+ :n_children_in_law .> 2
    )
    @select(:hhid)
end

## Children and children-in-law in multiple-match households
children_multiple_df = semijoin(children_df, multiple_match_hhids, on=:hhid)
children_in_law_multiple_df = semijoin(
    children_in_law_df,
    multiple_match_hhids,
    on=:hhid
)

## Add a column to indicate role
@transform!(children_multiple_df, :role = "child")
@transform!(children_in_law_multiple_df, :role = "child_in_law")

## Combine children and children-in-law
combined_df = vcat(children_multiple_df, children_in_law_multiple_df)

## Group by `hhid` and `maryr`
grouped_df = groupby(combined_df, [:hhid, :maryr])

## Apply function create_matches() to each group
children_multiple_sploc_df = combine(grouped_df, create_children_matches)
select!(children_multiple_sploc_df, [:hhid, :pernum, :sploc])

# Combine and merge back
children_sploc_df = vcat(
    children_single_sploc_df,
    children_multiple_sploc_df
)

leftjoin!(census_2010, children_sploc_df, on=[:hhid, :pernum], makeunique=true)
@transform!(census_2010, :sploc = coalesce.(:sploc, :sploc_1))
@select!(census_2010, Not(:sploc_1))

# Fill missing sploc with 0
@transform!(census_2010, :sploc = coalesce.(:sploc, 0))

# 2.5 Spousal information -------------------------------------------------

# Information needed for spouse
df = select(
    census_2010,
    :hhid,
    :pernum,
    :sploc,
    :age,
    :birthy,
    :hukou,
    :maryr,
    :marurban,
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
    :marurban_sp,
    :edu7_sp,
    :edu6_sp,
    :edu5_sp,
    :edu4_sp
)

# Merge spousal information back to main dataset
leftjoin!(census_2010, sp_df, on=[:hhid, :pernum])

# Identiy male and female information
@transform!(
    census_2010,
    :age_m = ifelse.(:female .== 0, :age, :age_sp),
    :age_f = ifelse.(:female .== 0, :age_sp, :age),
    :birthy_m = ifelse.(:female .== 0, :birthy, :birthy_sp),
    :birthy_f = ifelse.(:female .== 0, :birthy_sp, :birthy),
    :hukou_m = ifelse.(:female .== 0, :hukou, :hukou_sp),
    :hukou_f = ifelse.(:female .== 0, :hukou_sp, :hukou),
    :maryr_m = ifelse.(:female .== 0, :maryr, :maryr_sp),
    :maryr_f = ifelse.(:female .== 0, :maryr_sp, :maryr),
    :marurban_m = ifelse.(:female .== 0, :marurban, :marurban_sp),
    :marurban_f = ifelse.(:female .== 0, :marurban_sp, :marurban),
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

write_parquet("data/processed/census_2010.parquet", census_2010)
