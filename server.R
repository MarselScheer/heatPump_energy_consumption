
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(ggplot2)
library(data.table)

shinyServer(function(input, output) {

  output$temp_vs_power_consumption <- renderPlot({

    dt <- data.table::data.table(temp = rnorm(100, mean = input$temperature_outside))
    dt[, power_consumption := -1 * temp + rnorm(100)]
    ggplot(dt, aes(x = temp, y = power_consumption)) + 
      geom_point()
  })
  
  output$power_indicator_by_time <- renderDataTable({
    data.frame(a = "a", b = 1:4)
  })
  
})
