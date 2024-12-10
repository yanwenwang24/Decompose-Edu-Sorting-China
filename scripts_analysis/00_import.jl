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
using Arrow
using CategoricalArrays
using DataFrames
using DataFramesMeta
using Distributions
using FreqTables
using LinearAlgebra
using ProportionalFitting
using Random
using Statistics
using StatsBase

# Load functions
include("functions.jl")

# Load data
census = DataFrame(Arrow.Table("Data_clean/census.arrow"))
sample_women = DataFrame(Arrow.Table("Samples/sample_women.arrow"))
sample_men = DataFrame(Arrow.Table("Samples/sample_men.arrow"))
sample = DataFrame(Arrow.Table("Samples/sample.arrow"))

# Source scripts
# @time include("01_sample.jl")
@time include("02_trends.jl")
@time include("03_composition.jl")
@time include("04_gradient.jl")
@time include("06_decomp_prepare.jl")
@time include("07_decomp.jl")
