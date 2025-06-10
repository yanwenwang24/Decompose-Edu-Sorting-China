## ------------------------------------------------------------------------
##
## Script name: 04_decomp.r
## Purpose: Visualize odds ratios
## Author: Yanwen Wang
## Date Created: 2024-12-10
## Email: yanwenwang@u.nus.edu
##
## ------------------------------------------------------------------------
##
## Notes:
##
## ------------------------------------------------------------------------

# 1 Load data -------------------------------------------------------------

decomp_pooled <- read_parquet("outputs/tables/pooled/decomp.parquet")
decomp_by_urban <- read_parquet("outputs/tables/urban-rural/decomp.parquet")

# Recode
decomp_pooled <- decomp_pooled %>%
  filter(group != base_group) %>%
  filter(component != "total") %>%
  mutate(pattern = str_to_title(pattern)) %>%
  mutate(
    component = case_when(
      component == "expansion" ~ "Educational expansion",
      component == "gradient" ~ "Educational gradient",
      component == "pattern" ~ "Assortative mating"
    ),
    component = factor(
      component,
      levels = c(
        "Educational expansion",
        "Educational gradient",
        "Assortative mating"
      )
    )
  )

decomp_by_urban <- decomp_by_urban %>%
  filter(group != base_group) %>%
  filter(component != "total") %>%
  mutate(pattern = str_to_title(pattern)) %>%
  mutate(
    component = case_when(
      component == "expansion" ~ "Educational expansion",
      component == "gradient" ~ "Educational gradient",
      component == "pattern" ~ "Assortative mating"
    ),
    component = factor(
      component,
      levels = c(
        "Educational expansion",
        "Educational gradient",
        "Assortative mating"
      )
    )
  )

# 2 Plot trends -----------------------------------------------------------

# Pooled
decomp_pooled_plt <- decomp_pooled %>%
  ggplot(aes(
    x = group, y = estimate,
    fill = component, group = component, linetype = component
  )) +
  geom_bar(position = "stack", stat = "identity") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    values = c(
      "#fd7f6f", "#7eb0d5", "#b2e061"
    )
  ) +
  labs(
    y = "",
    x = "Cohort"
  ) +
  theme(legend.position = "none") +
  facet_grid(~pattern)

# By urban
decomp_by_urban_plt <- decomp_by_urban %>%
  ggplot(aes(x = cohort, y = estimate, fill = component)) +
  geom_bar(position = "stack", stat = "identity") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(
    values = c(
      "#fd7f6f", "#7eb0d5", "#b2e061"
    )
  ) +
  labs(
    y = "",
    x = "Cohort"
  ) +
  facet_wrap(~pattern, nrow = 1) +
  theme_bw() +
  theme(
    legend.title = element_blank(),
    legend.position = "bottom"
  )

decomp_plt <- decomp_pooled_plt / decomp_by_urban_plt

# Save the plot
ggsave(
  "outputs/graphs/main/decomp.png",
  decomp_plt,
  width = 8,
  height = 12,
  dpi = 300
)
