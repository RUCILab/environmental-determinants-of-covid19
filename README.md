# Code for The Environmental Determinants of COVID-19

 This repository contains code and data for the RUCI Lab's research project "The Environmental Determinants of COVID-19"

The New York City Department of Health & Mental Hygeine's official COVID-19 data repository is included as a submodule in this repository under the folder "coronavirus-data"

A single time series dataset by ZIP code tabluation area (ZCTA) is produced by way of the following code located in the /scripts folder:

1. First, the script export-revisions.sh is run from within the NYC COVID-19 data repository with the file tests-by-zcta.csv as an argument. This script extracts each version of this file and outputs it to a directory.

2. Second, the script trim-filenames.sh is run on the files outputted by the first step. This script removes other data from the filenames so that each CSV file has the filename of the date of the corresponding Git commit for the tests-by-zcta.csv file.

3. Third, the R script clean-files.R is run to clean the individual CSV files. The script prepares the data to be combined into a single dataframe for further analysis.

4. Fourth, the script create-timeseries-dataset.R is used to combine the 64 individual CSV files into a combined dataset. Then, the data is matched with a crosswalk file that allocates COVID-19 case counts to census tracts by population.The result of this file is a time series dataset with COVID-19 testing data by census tract from April 1st - June 6th 2020.