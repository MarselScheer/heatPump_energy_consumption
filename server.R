
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(ggplot2)
library(data.table)

get_current_time_as_text <- function() {
  format(lubridate::now(), "%Y-%m-%d %H:%M:%S")
}

load_historical_data <- function(fName) {
  if (!file.exists(fName))
    return(data.table::data.table())
  
  data.table::fread(fName)
}

shinyServer(function(input, output, session) {

  data <- reactiveValues(pwr = load_historical_data(isolate(input$file_save)))
  
  observeEvent(input$file_pwr, {
    inFile <- input$file_pwr
    
    if (is.null(inFile))
      return(NULL)
    
    data$pwr <- data.table::fread(inFile$datapath)
  })
  
  observeEvent(input$save, {
    data$pwr <- rbind(
      data.table::data.table(
        time = input$time, 
        temperature_outside = input$temperature_outside, 
        power_indicator = input$power_indicator, 
        heatPump_settings = input$heatPump_settings),
      data$pwr
    )
    # just in case some hits the save button twice
    data$pwr <- unique(data$pwr)
    data.table::fwrite(data$pwr, isolate(input$file_save))
    data$pwr
  })
  
  output$temp_vs_power_consumption <- renderPlot({

    dt <- data.table::data.table(temp = rnorm(100, mean = input$temperature_outside))
    dt[, power_consumption := -1 * temp + rnorm(100)]
    ggplot(dt, aes(x = temp, y = power_consumption)) + 
      geom_point()
  })
  
  output$power_indicator_by_time <- renderDataTable({
    data$pwr
  })
  
  observeEvent(input$update_time_to_now, {
    updateTextInput(session, "time", value = get_current_time_as_text())
  })
})
