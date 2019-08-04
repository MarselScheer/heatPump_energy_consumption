
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(ggplot2)
library(data.table)

#options(shiny.port = 7775); options(shiny.host = "192.168.1.11")
to_time <- function(str) {
  lubridate::ymd_hms(str)
}
get_current_time_as_text <- function() {
  format(lubridate::now(), "%Y-%m-%d %H:%M:%S")
}

prep_data_for_plotting <- function(dt) {
  dt <- data.table::copy(dt)
  dt[, ':='(
    diff_time_in_days = as.numeric(time - data.table::shift(time), units = "days"), 
    diff_power = power_indicator - data.table::shift(power_indicator),
    mean_temp = (temperature_outside + data.table::shift(temperature_outside))/2)]
  dt[, cost_per_day := diff_power/diff_time_in_days  * 0.25]
  dt
}

load_historical_data <- function(fName) {
  if (!file.exists(fName))
    return(data.table::data.table())
  
  dt <- data.table::fread(fName)
  dt[, time := to_time(time)]
  dt
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
        time = to_time(input$time), 
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

    dt <- prep_data_for_plotting(data$pwr)
    
    ggplot(
      dt[data.table::shift(heatPump_settings) == heatPump_settings & diff_time_in_days < 2],
      aes(
        x = mean_temp, 
        y = cost_per_day, 
        color = heatPump_settings)) +
      ylab("Cost per day in EURO") + 
      geom_point(alpha = 0.5) + 
      geom_smooth(method = "lm") + 
      theme(legend.position = "top")
  })
  
  output$power_indicator_by_time <- renderDataTable({
    data$pwr
  })
  
  observeEvent(input$update_time_to_now, {
    updateTextInput(session, "time", value = get_current_time_as_text())
  })
})
