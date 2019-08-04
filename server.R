
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


shinyServer(function(input, output, session) {

  data <- reactiveValues(pwr = data.table::data.table())
  
  save_entry <- eventReactive(input$save, {
    data$pwr <- rbind(
      data$pwr, 
      data.table::data.table(
        time = input$time, 
        temperature_outside = input$temperature_outside, 
        power_indicator = input$power_indicator, 
        heatPump_settings = input$heatPump_settings)
    )
    data$pwr
  })
  
  output$temp_vs_power_consumption <- renderPlot({

    dt <- data.table::data.table(temp = rnorm(100, mean = input$temperature_outside))
    dt[, power_consumption := -1 * temp + rnorm(100)]
    ggplot(dt, aes(x = temp, y = power_consumption)) + 
      geom_point()
  })
  
  output$power_indicator_by_time <- renderDataTable({
    save_entry()
  })
  
  observeEvent(input$update_time_to_now, {
    updateTextInput(session, "time", value = get_current_time_as_text())
  })
})
