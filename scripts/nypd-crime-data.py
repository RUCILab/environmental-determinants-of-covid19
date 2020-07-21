import pandas as pd
from uszipcode import SearchEngine

df = pd.read_csv('NYPD_Complaint_Data_Current__Year_To_Date_.csv', low_memory=False)

# Define function for converting town names to ZIP codes
def get_zip_code(lat,lon):
    try:
        res = search.by_coordinates(lat, lon, radius=1, returns=1)[0].zipcode
    except IndexError:
        res = 'NA' 
    return(str(res))

# Read in data and iterate over ZIP search engine
search = SearchEngine(simple_zipcode=True)

for index, row in df.iterrows():
    df.loc[index,'ZIP'] = get_zip_code(row['Latitude'],row['Longitude'])

# Crosswalk the ZIP codes to ZIP code tabluation areas
crosswalk = pd.read_csv('https://www2.census.gov/geo/docs/maps-data/data/rel/zcta_tract_rel_10.txt')
