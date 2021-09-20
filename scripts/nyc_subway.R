library(tidyverse)
library(tidytransit)
library(lubridate)
library(data.table)
library(geojsonsf)
library(fuzzyjoin)

setwd("//172.19.36.246/nycdohmh/Environmental Determinants of COVID-19")

nyc <- geojson_sf('https://data.cityofnewyork.us/api/geospatial/tqmj-j8zm?method=export&format=GeoJSON')

# Read in NYC subway GTFS feed
gtfs <- read_gtfs("envdata/transit/gtfs.zip")
stops <- stops_as_sf(gtfs$stops)

# Read in MTA subway data
subway <- read_csv('envdata/transit/subway_nyc.csv') %>%
  select(-`...111`) 


# Convert subway data to data.table for processing
setDT(subway)

# Melt the wide dataframe into a long dataframe
subway <- melt(subway, id.vars =c('Station ID','STATION'), variable.name = "date", value.name = "ridership")%>%
  mutate(date = mdy(date),
         week = week(date))


stations <- read_csv('https://data.cityofnewyork.us/api/views/kk4q-3rt2/rows.csv?accessType=DOWNLOAD')


# Split the lines and station names from the ridership dataset to match the station names
for (i in 1:nrow(subway)) {
  subway$STATION_CLEAN[i] <- str_split(subway$STATION[i], '[()]',n =3)[[1]][1]
  
  subway$LINE[i] <- str_split(subway$STATION[i], '[()]',n =3)[[1]][2]
}

# Clean up the lines
subway$LINE <- gsub(",","-",subway$LINE)

# Clean up the street names
#subway$STATION_CLEAN <- gsub("Av","Ave",subway$STATION_CLEAN)

# Trim extra whitespace
subway$STATION_CLEAN <- trimws(subway$STATION_CLEAN)

# Join the stations with the ridership data
crosswalk <- subway %>% 
  left_join(stops,by = c("STATION_CLEAN" = "stop_name")) %>% 
  distinct(`Station ID`, .keep_all = TRUE) %>%
  select('Station ID',geometry)

# Write out the crosswalk for later use
write_csv(crosswalk,"subway-station-crosswalk.csv")

joined <- subway %>%
  left_join(crosswalk, by = 'Station ID') %>%
  unnest_wider(geometry,names_sep = "geo") %>%
  rename("lon" = geometrygeo1,
         "lat" = geometrygeo2)

blm_ridership <- joined %>%
  filter(date >= "2020-05-01" & date <= "2020-06-30") %>%
  group_by(`Station ID`) %>%
  mutate(pct_change = (ridership/lag(ridership) - 1) * 100)

mylabels <- c("Low","Med-Low","Medium","Med-High","High")
blm_ridership$pct_change_break <- cut(blm_ridership$pct_change,5,mylabels)


fig1 <- ggplot(blm_ridership) +
  geom_line(aes(x = date, y = pct_change, group = STATION, color = STATION), show.legend = FALSE) +
  ggtitle("Change in NYC Subway Ridership During BLM Protests, May - June 2020")

fig2 <- ggplot(blm_ridership %>% filter(date != "2020-05-03")) +
  #geom_sf(data = nyc) +
  geom_point(aes(x = lon, y = lat, color = pct_change_break)) +
  facet_wrap(~date) +
  ggtitle("Change in NYC Subway Ridership During BLM Protests (2020) - By Station")

fig3 <- ggplot(blm_ridership %>% filter(date != "2020-05-03")) +
  geom_sf(data = nyc) +
  geom_point(aes(x = lon, y = lat, color = pct_change)) +
  facet_wrap(~date) +
  ggtitle("Change in NYC Subway Ridership During BLM Protests (2020) - By Station")
  
  geom_line(aes(x = date, y = pct_change, group = STATION, color = STATION), show.legend = FALSE) +
  ggtitle("Change in NYC Subway Ridership During BLM Protests (2020)")


  facet_wrap(~STATION_CLEAN)

# Figure out what happened with the rows that did not join
bad_rows <- joined %>% filter(is.na(lat))