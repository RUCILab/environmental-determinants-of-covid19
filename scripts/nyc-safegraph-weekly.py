from datetime import datetime, timedelta
import ast
import pandas as pd 

# Script to process Safegraph weekly summary data for NYC dataset generation

# Empty df to store final results
results_df = pd.DataFrame([])

# Read in safegraph data
df = pd.read_csv('NYC_weekly.csv',parse_dates=['date_range_start','date_range_end'],dtype={'poi_cbg':str})

# Get the Census Tract for each POI and store it
df['TRACT'] = df['poi_cbg'].str[5:11]

# Takes a single row of safegraph weekly summaries and creates daily counts
def sg_weekly_to_daily(df):
    # Create empty df to store result
    result = pd.DataFrame([])
    #start iterating
    # Create date range from values and store as resul
    actual_end = row['date_range_end'] - datetime.timedelta(days=1)
    result['date'] = pd.date_range(start=row['date_range_start'].date(),end=actual_end.date(),freq='D')
    # Create list from daily count values
    daily_visits = ast.literal_eval(row['visits_by_day'])
    # Append daily visits to result dataframe
    result['daily_visit_count'] = pd.DataFrame(daily_visits)
    # Append other values
    result['POI'] = row['location_name']
    result['TRACT'] = row['TRACT']
    result['median_dwell'] = row['median_dwell']
    result['distance_from_home'] = row['distance_from_home']
    return(result)

for index, row in df.iterrows():
    result = sg_weekly_to_daily(df)
    results_df = pd.concat([result,results_df])
