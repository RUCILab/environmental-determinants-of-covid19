# Script for combining and cleaning daily case counts by MODZCTA into a single time series file for analysis.

library(tidyverse)

setwd('../output')

# USAGE: This script operates on the output of the bash scripts "export-revisions.sh" and "trim-filenames.sh"
# It is assumed that the output generated from those two scripts is stored in the '../ouput' directory referenced above.

# List all daily testing files from Git repository output
dat_files <- list.files('../output', pattern='*.csv')

# Get dates and use it to start building dataframe by stripping out the .csv portion of filenames
data <- data.frame(date=str_replace(dat_files, ".csv", ""))

# Clean daily case count files

# Rename MODZCTA columns CSV files from 2020-05-24 to 2020-06-08 so files are consistent, 
for (i in 50:nrow(data)) {
  current_df <- suppressMessages(read_csv(paste0(data$date[i],'.csv')))
  current_df <- current_df %>% rename(MODZCTA = modzcta) %>% rename(zcta_cum.perc_pos = modzcta_cum_perc_pos)
  write.csv(current_df, paste0(data$date[i],'.csv'), row.names = FALSE)
}

# Drop rows with 99999 as MODZCTA from all daily CSV files, write out cleaned versions
for (i in 1:nrow(data)) {
  current_df <- suppressMessages(read_csv(paste0(data$date[i],'.csv')))
  current_df <- current_df %>% filter(MODZCTA != 99999)
  write.csv(current_df, paste0(data$date[i],'.csv'), row.names = FALSE)
}

# Handle two fringe cases manually 

# April 10th has a duplicate row for ZCTA 11697 in row 178. Compared to the next day's report, row 178 is nowhere near expected values 
# We are dropping this row
apr10 <- read_csv('2020-04-10.csv')
# Drop duplicate row
apr10 <- apr10[-c(178),]
# Write out cleaned version
write.csv(apr10, '2020-04-10.csv', row.names = FALSE)

# May 23rd is a mess. It has 189 rows when we expected 177.
may23 <- read_csv('2020-05-23.csv')

# Get proper list of ZCTAs from April 10th's file
zctas <- apr10 %>% select(MODZCTA)

# Join with matching values from May 23rd's data, write out to CSV
may23 <- zctas %>% left_join(may23)
write.csv(may23, '2020-05-23.csv', row.names = FALSE)

# Sanity check: Check the number of rows for each date's CSV file and print output to console, all should be 177
for (i in 1:nrow(data)) {
  current_df <- suppressMessages(read_csv(paste0(data$date[i],'.csv')))
  print(paste('Date:', data$date[i], 'Number of rows:',nrow(current_df)))
}

