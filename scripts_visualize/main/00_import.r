## ------------------------------------------------------------------------
##
## Script name: 00_import.r
## Purpose: Import libraries and source scripts for visualization
## Author: Yanwen Wang
## Date Created: 2024-12-10
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# Load the required packages
library(arrow)
library(ggthemes)
library(tidyverse)
library(patchwork)

theme_set(theme_hc())

# Source scripts
source("scripts_visualize/main/01_trends.r")
source("scripts_visualize/main/02_composition.r")
source("scripts_visualize/main/03_gradient.r")
source("scripts_visualize/main/04_odds_ratio.r")
source("scripts_visualize/main/05_decomp.r")
