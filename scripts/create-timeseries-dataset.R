library(plyr)
library(tidyverse)

# Script to create time series data file from individual CSV files. Expects cleaned CSVs in output directory.

setwd('../output')


zip2tract <- function(zcta) {
  # Get tract IDs and tract populations for given ZCTA
  tracts <- crosswalk %>% filter(ZCTA5 == zcta) %>% select(ZCTA5, TRACT, TRPOP)
  
  # Get percent each tract's population represents of the total population
  total_pop <- sum(tracts$TRPOP)
  for (i in 1:nrow(tracts)) {
    tracts$percent_pop[i] <- tracts$TRPOP[i] / total_pop 
  }
  # Get NYC cases matching each ZCTA and join with tracts
  zcta_cases <- combined_df %>% filter(MODZCTA == zcta)
  
  joined <- tracts %>% left_join(zcta_cases, by = c('ZCTA5' = 'MODZCTA'))
  
  # Allocate cases to tracts based upon percentages
  for (i in 1:nrow(joined)) {
    joined$tract_total[i] <- joined$percent_pop[i] * joined$Total[i]
    joined$tract_positive[i] <- joined$percent_pop[i] * joined$Positive[i]
    # Calculate cumulative positive cases by tract to check accuracy of allocation
    joined$tract_cum_perc_pos[i] <- round(joined$tract_positive / joined$tract_total * 100, digits = 1)
  }
  return(joined)
}

# List all daily testing files from Git repository
dat_files <- list.files('../output', pattern='*.csv')

# Get dates and use it to start building dataframe
dates <- data.frame(date=str_replace(dat_files, ".csv", ""))

# Add dates to CSV files as a column
for (i in 1:nrow(dates)) {
  current_df <- suppressMessages(read_csv(paste0(dates$date[i],'.csv')))
  current_df$date <- dates$date[i]
  write.csv(current_df, paste0(dates$date[i],'.csv'), row.names = FALSE)
}

# Combine all of the CSV files into a single dataframe
combined_df <- ldply(dat_files, read_csv)

# Write out the combined dataframe to CSV
write.csv(combined_df, '../nyc-covid-timeseries-zcta.csv', row.names = FALSE)

# Create dataset by census tract

# Convert ZCTA to character for joining with tract crosswalk
combined_df$MODZCTA = as.character(combined_df$MODZCTA)

list <- lapply(combined_df$MODZCTA, function(x) zip2tract(x))

# Convert to a single dataframe
combined_cases <- rbind.fill(list)

write.csv(combined_cases, '../nyc-covid-timeseries-by-tract.csv', row.names = FALSE)
write.csv(combined_df, '../nyc-covid-timeseries-zcta.csv', row.names = FALSE)
