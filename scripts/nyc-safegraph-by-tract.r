### Script for reading expanded weekly Safegraph data for NYC
### Creates a new file with counts of visits by census tract, by day

data <- read_csv('nyc-safegraphweekly.csv')

visit_count <- data %>% group_by(date,daily_visit_count,TRACT) %>% tally()

aggregate(visit_count["daily_visit_count"], by=c(visit_count["date"],visit_count["TRACT"]), sum)

write.csv(visits_by_tract,'visits_by_tract.csv')
