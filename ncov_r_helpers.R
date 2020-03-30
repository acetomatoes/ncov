
# Libraries ----------
### Libraries used are below
# The functions are namespaced, so once the libraries are installed you can just run the function and don't have to load each library
library(tidyverse)
library(data.table)
library(janitor)
library(lubridate)
library(leaflet)
library(leaflet.extras)
library(sf)
library(sp)


# Time Series data feeds ----------
# define the urls for the three conditions from which we'll pull in the data
confirmed_url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv'
deaths_url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv'
recovered_url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_recovered_global.csv'

# this function pulls the data from individual url
# the 'status' paramter creates a new column in the data
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
  cv_deaths <- get_cv_data(deaths_url, 'Deaths')
  
  cv_combined <- dplyr::bind_rows(cv_confirmed, cv_recovered, cv_deaths)
  cv_combined <- janitor::clean_names(cv_combined)
  cv_combined[, date := lubridate::mdy(date)]
  cv_combined[is.na(count), count := 0]
  return(cv_combined)
}

# this adds a CRS to the cv_object and turns it to a simple features object
cv_to_sf <- function(cv_data) {
  cv_sf <- sf::st_as_sf(cv_data, coords = c("long", "lat"), crs = "+proj=longlat +ellps=WGS84 +datum=WGS84")
}

# get the data in a tidy format and write to disk if desired
cv_data <- compile_cv_data()
data.table::fwrite(cv_data, "./data/coronavirus_data.csv")

# convert to a simple features object and write out as geojson if that's your preferred format
cv_sf <- cv_to_sf(cv_data)
sf::st_write(cv_sf, "./data/coronavirus_data.geojson")


# Daily data feed ----------
# this function directly reads in the latest daily report and can be run on a schedule
# if the data for the current date isn't available yet, it returns the previous day's data
# the output can also be converted to sf using the cv_sf() function

cv_daily <- function(date = Sys.Date()){
  if(missing(date)){
    current_day <- lubridate::today()
    date_str <- paste0(format(current_day, "%m-%d-%Y"),".csv")
    url = paste0("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/", date_str)
    current_data <-  tryCatch({
      pull <- data.table::fread(url)
      setnames(pull, names(pull), snakecase::to_snake_case(names(pull)))
    }, error = function(e) {
      prev_day <- current_day-lubridate::days(1)
      message(paste0("Data for ", current_day, " not yet available, returning data for ", prev_day))
      date_str <- paste0(format(prev_day, "%m-%d-%Y"),".csv")
      url = paste0("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/", date_str)
      pull <- data.table::fread(url)
      setnames(pull, names(pull), snakecase::to_snake_case(names(pull)))
    })
    return(current_data)
  } else {
    if(class(date) == "Date"){
      date_str <- paste0(format(date, "%m-%d-%Y"),".csv")
    } else {
      date_str <- paste0(gsub("/", "-", date), ".csv")
    }
    url = paste0("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/", date_str) 
    requested_data <- try({
      pull <- data.table::fread(url)
      setnames(pull, names(pull), snakecase::to_snake_case(names(pull)))
    })
    return(requested_data)
  }
  
}

#daily <- cv_daily("03-01-2020")
#daily <- cv_daily("03/01/2020")
#daily <- cv_daily(mdy("03/01/2020"))