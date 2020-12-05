# Load R packages
library(abind)
library(dashboardthemes)
library(dplyr)
library(GGally)
library(plotly)
library(rcompanion)
library(rvest)     # web scraping
library(shiny)
library(shiny)
library(shinyalert)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyjs)
library(shinythemes)
library(shinyWidgets)
library(tidyverse) # clean and tidy the data
library(timeDate)
library(visNetwork)
library(wordcloud2)
library(xml2)      # read the html page

## Only run examples in interactive R sessions
if (interactive()) {

    ui <- fluidPage(
        numericInput("end", "End Page", value = 100, min=100, max=1000, step = 100),
        textInput("Initial_page", "Indeed Link"),
        dataTableOutput("dataset")

    )

    server <- function(input, output, session) {
        observe({
            # We'll use the input$end variable multiple times, so save it as x
            # for convenience.
            x <- reactive({input$Initial_page})
            x1 <- reactive({paste('"',x(),'"')})
            x2<- reactive({gsub(" ", "", x1(), fixed = TRUE)})
            output$y <- renderText(x2())

            library(tidyverse) # clean and tidy the data
            library(rvest)     # web scraping
            library(xml2)      # read the html page

            # Specifying the url
            start <- 10  # where the page starts
            end <- reactive({input$end})   # last page, depends on how many data that you want
            links <- reactive({seq(start, end(), by = 10)}) # it will return 10, 20, ... , 500

            # Make an empty dataframe to store the data
            data <- data.frame()

            order<- reactive({seq_along(links())})

            # Let's loop!
            # we will process the links, one by one, that's why I used seq_along function
            reactive({for(i in order()) {
                Initial_page <- reactive({x2()}) # the very first page
                Initial_page <- gsub(" ", "", Initial_page, fixed = TRUE)
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

                output$dataset<- renderTable(data)
            }})


        })
    }

    shinyApp(ui, server)
}
