# ncov
Python and R scripts for collecting and consolidating the time series and daily reports datasets related to the COVID-19 pandemic.
Data source: https://github.com/CSSEGISandData/COVID-19

* `get_cv_data()` - takes in the times series data url, downloads and prepares the individual time series datasets
* `compile_cv_data()` - directly pulls the data from all three condition urls and combines them into a tidy object
* `cv_to_sf()` - converts the data to a sf object that can be written out as a geojson file
* `cv_daily()` - reads in the latest dataset from the Daily Reports dataset
