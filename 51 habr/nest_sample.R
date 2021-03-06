library(dplyr)
library(tidyr)

iris %>% nest(-Species)
chickwts %>% nest(weight)

if (require("gapminder")) {
  gapminder %>%
    group_by(country, continent) %>%
    nest()
  
  gapminder %>%
    nest(-country, -continent)
}