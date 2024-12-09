## ------------------------------------------------------------------------
##
## Script name: 00_import.jl
## Purpose: Import data and source scripts for analysis
## Author: Yanwen Wang
## Date Created: 2024-12-08
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Load the required packages
using AlgebraOfGraphics
using Arrow
using CairoMakie
using CategoricalArrays
using DataFrames
using DataFramesMeta
using FreqTables
using GLM
using MakieThemes
using ProportionalFitting
using Random
using StatsBase

set_theme!(theme_ggthemr(:fresh))

# Load functions
include("functions.jl")

# Load data
census = DataFrame(Arrow.Table("Data_clean/census.arrow"))
sample_women = DataFrame(Arrow.Table("Data_clean/sample_women.arrow"))
sample_men = DataFrame(Arrow.Table("Data_clean/sample_men.arrow"))
sample = DataFrame(Arrow.Table("Data_clean/sample.arrow"))

# Source scripts
# @time include("01_sample.jl")
@time include("02_trends.jl")
@time include("03_composition.jl")
@time include("04_gradient.jl")
