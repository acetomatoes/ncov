import pandas as pd
import janitor

confirmed_url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv'
deaths_url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv'
recovered_url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Recovered.csv'

# this function pulls the data from individual url
#the 'status' paramter creates a new column in the data
def get_cv_data(dataset_url, status):
    cv = pd.read_csv(dataset_url)
    cv['status'] = status
    id_cols = ['Province/State', 'Country/Region', 'Lat', 'Long', 'status']
    cv_melt = pd.melt(cv, id_vars=id_cols, var_name='date', value_name='count')
    return cv_melt
    
# this function pulls all 3 urls and combines them into one tidy object with clean column names
# takes no input parameters
def compile_cv_data():
    cv_confirmed = get_cv_data(confirmed_url, 'confirmed')
    cv_recovered = get_cv_data(recovered_url, 'recovered')
    cv_deaths = get_cv_data(deaths_url, 'deaths')
    
    cv_combined = pd.concat([cv_confirmed, cv_recovered, cv_deaths]).clean_names().fillna(0)
    cv_combined['date'] = pd.to_datetime(cv_combined['date'])
    
    return cv_combined

# pulls in the data and writes to disk if desired
cv_data = compile_cv_data()
cv_data.to_csv('./data/coronavirus_data.csv', index=False)
