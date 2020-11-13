#<https://rstudio-pubs-static.s3.amazonaws.com/221012_b0c842bd540f4ecdb5df02f2ae567be3.html>

# Let's load the packages
library(tidyverse) # clean and tidy the data
library(rvest)     # web scraping
library(xml2)      # read the html page

# Specifying the url
start <- 10  # where the page starts
end <- 500   # last page, depends on how many data that you want
links <- seq(start, end, by = 10) # it will return 10, 20, ... , 500

# Make an empty dataframe to store the data
data <- data.frame()

# Let's loop!
# we will process the links, one by one, that's why I used seq_along function
for(i in seq_along(links)) {
  Initial_page <- "https://ie.indeed.com/jobs?q=Data+Analyst" # the very first page
  url <- paste0(Initial_page, "&start=", links[i]) # construct the url by pasting
  page <- xml2::read_html(url) # read the html

  # Sys.sleep pauses R for two seconds to avoid the error message
  Sys.sleep(2)

  # right-click on page - inspect and you can use CSS Selector addins on Chrome
  # get the job title
  job_title <- page %>%
    rvest::html_nodes("div") %>%
    rvest::html_nodes(xpath = '//a[@data-tn-element = "jobTitle"]') %>%
    rvest::html_attr("title")

  # get job location CSS selector
  job_location <- page %>%
    rvest::html_nodes('.accessible-contrast-color-location') %>%
    rvest::html_text() %>%
    stringi::stri_trim_both()

  # get the company name
  company_name <- page %>%
    rvest::html_nodes("span")  %>%
    rvest::html_nodes(xpath = '//*[@class="company"]')  %>%
    rvest::html_text() %>%
    stringi::stri_trim_both() -> company.name

  # get job description CSS selector
  job_description <- page %>%
    rvest::html_nodes('.summary') %>%
    rvest::html_text() %>%
    stringi::stri_trim_both()

  df <- data.frame(job_title, job_location, company_name, job_description)
  data <- rbind(data, df)
}

# New data set
df_Dublin <- data %>%
  dplyr::distinct() %>%
  dplyr::mutate(city = "Dublin") # add column city = Dublin

# With some cleaning
df_Dublin$job_description <- gsub("[\r\n]", "", df_Dublin$job_description)

# in case you want to save the dataset into a csv
# write.csv(df_Dublin,"df_Dublin.csv")

