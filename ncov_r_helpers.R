library(tidyverse)
library(data.table)
library(janitor)
library(lubridate)
library(leaflet)
library(leaflet.extras)
library(sf)
library(sp)

# define the urls for the three conditions from which we'll pull in the data
confirmed_url <- 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv'
deaths_url <- 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv'
recovered_url <- 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Recovered.csv'

# this function pulls the data from individual url
#the 'status' paramter creates a new column in the data
get_cv_data <- function(dataset_url, status) {
  cv <- data.table::fread(dataset_url) 
  cv[, Status := status]
  data.table::setcolorder(cv, c("Province/State", "Country/Region", "Lat", "Long", "Status"))
  
  cv_melt <- data.table::melt(cv, id.vars = 1:5, measure.vars = names(cv)[-c(1:5)], variable.name = "Date", value.name = "Count")
  return(cv_melt) 
}

# this function pulls all 3 urls and combines them into one tidy object with clean column names
# takes no input parameters
compile_cv_data <- function() {
  cv_confirmed <- get_cv_data(confirmed_url, 'Confirmed')
  cv_recovered <- get_cv_data(recovered_url, 'Recovered')
  cv_deaths <- get_cv_data(confirmed_url, 'Deaths')
  
  cv_combined <- dplyr::bind_rows(cv_confirmed, cv_recovered, cv_deaths)
  cv_combined <- janitor::clean_names(cv_combined)
  cv_combined[, date := lubridate::mdy(date)]
  cv_combined[is.na(count), count := 0]
  return(cv_combined)
}

# this adds a CRS to the cv_object and turns it to a simple features object
cv_to_sf <- function(cv_data) {
  sp::coordinates(cv_data) <- ~long+lat
  sp::proj4string(cv_data) <- "+proj=longlat +ellps=WGS84 +datum=WGS84"
  cv_sf <- sf::st_as_sf(cv_data)
  
}

# get the data in a tidy format and write to disk if desired
cv_data <- compile_cv_data()
data.table::fwrite(cv_data, "./data/coronavirus_data.csv")

# convert to a simple features object and write out as geojson if that's your preferred format
cv_sf <- cv_to_sf(cv_data)
sf::st_write(cv_sf, "./data/coronavirus_data.geojson")
