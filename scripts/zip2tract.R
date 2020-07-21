library(tidyverse)
library(plyr)

# Read ZCTA crosswalk data
crosswalk <- read_csv('https://www2.census.gov/geo/docs/maps-data/data/rel/zcta_tract_rel_10.txt')

# Get NYC Census Tracts GeoJSON from Open Data Portal
nyc_tracts <- read_csv('nyct2010.csv')
# Read in current NYC cases
nyc_cases <- read.csv('https://raw.githubusercontent.com/nychealth/coronavirus-data/master/tests-by-zcta.csv')

# Get modified ZCTA to ZCTA crosswalk file
modzcta <- read.csv('../coronavirus-data/master/Geography-resources/ZCTA-to-MODZCTA.csv')

# Convert NYC cases ZCTA value to character so it matches the crosswalk
nyc_cases$modzcta <- as.character(nyc_cases$modzcta)

# Assign cases to census tract

zip2tract <- function(zcta) {
  # Get tract IDs and tract populations for given ZCTA
  tracts <- crosswalk %>% filter(ZCTA5 == zcta) %>% select(ZCTA5, TRACT, TRPOP)
  
  # Get percent each tract's population represents of the total population
  total_pop <- sum(tracts$TRPOP)
  for (i in 1:nrow(tracts)) {
    tracts$percent_pop[i] <- tracts$TRPOP[i] / total_pop 
  }
  # Get NYC cases matching each ZCTA and join with tracts
  zcta_cases <- nyc_cases %>% filter(modzcta == zcta)
  
  joined <- tracts %>% left_join(zcta_cases, by = c('ZCTA5' = 'modzcta'))
  
  # Allocate cases to tracts based upon percentages
  for (i in 1:nrow(joined)) {
    joined$tract_total[i] <- joined$percent_pop[i] * joined$Total[i]
    joined$tract_positive[i] <- joined$percent_pop[i] * joined$Positive[i]
    # Calculate cumulative positive cases by tract to check accuracy of allocation
    joined$tract_cum_perc_pos[i] <- round(joined$tract_positive / joined$tract_total * 100, digits = 1)
  }
  return(joined)
}


# Apply the function to every NYC ZCTA and store the results to a list
list <- lapply(nyc_cases$modzcta, function(x) zip2tract(x))

# Convert to a single dataframe
combined_cases <- rbind.fill(list)

# Write out the combined df
write.csv(combined_cases,'nyc_tests_by_tract.csv')

# Join the combined df with shapefile for tracts

joined_geo <- nyc_tracts %>% left_join(combined_cases, by = c('CT2010' = 'TRACT'))

write.csv(joined_geo,'nyc_tests_by_tract_geo.csv')
