
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(ggplot2)
library(data.table)
library(logger)

#options(shiny.port = 7775); options(shiny.host = "192.168.1.11")
to_time <- function(str) {
  lubridate::ymd_hms(str)
}

get_current_time_as_text <- function() {
  format(lubridate::now(), "%Y-%m-%d %H:%M:%S")
}

#' calcualtes cost per day and mean temperature in order to plot them
prep_data_for_plotting <- function(dt) {
  logger::log_debug()
  
  if (nrow(dt) < 2) {
     return(NULL)
  }
  dt <- data.table::copy(dt)
  dt[, ':='(
    diff_time_in_days = as.numeric(time - data.table::shift(time), units = "days"), 
    diff_power = power_indicator - data.table::shift(power_indicator),
    mean_temp = (temperature_outside + data.table::shift(temperature_outside))/2)]
  dt[, cost_per_day := diff_power/diff_time_in_days  * 0.25]
  dt
}

#' imports data from a file and updates input elements with the latest entries
#'
#' @param fName file name for import
#' @param session needed to update the input elements
#' @seealso update_input_with_last_dataentries
#' 
#' @return imported file as a data.table or just an empty data.table is file does not exist
load_historical_data <- function(fName, session) {
  logger::log_debug()
  if (!file.exists(fName))
    return(data.table::data.table())
  
  dt <- data.table::fread(fName)
  dt[, time := to_time(time)]
  update_input_with_last_dataentries(dt, session)
  dt
}

#' Updates temperature_outside, power_indicator, heatPump_settings as well as the time-input
#'
#' The time-input is updated with the current time.
#' @param pwr first row of this data.table is used to update temerature_outside, power_indicator and heatPump_settings
#' @param session needed to update the input elements
update_input_with_last_dataentries <- function(pwr, session) {
  logger::log_debug()
  
  if (nrow(pwr) > 0) {
    
    offset <- 0
    if (round(pwr$temperature_outside[1]) == pwr$temperature_outside[1]) {
      # strange effect that some phones does not offer a decimal point for temperature.
      # if the last temperature than was an integer, the decimal is also not contained
      # in the input-element, i.e. it displays 17 instead of 17.0, which makes it even harder
      # to enter a new number with a decimal.
      # make sure that temperature used to init the input-element is not an integer
      offset <- 0.1      
    }
    
    updateNumericInput(session, "temperature_outside", value = pwr$temperature_outside[1] + offset)
    updateNumericInput(session, "power_indicator", value = pwr$power_indicator[1])
    updateNumericInput(session, "heatPump_settings", value = pwr$heatPump_settings[1])
    updateTextInput(session, "time", value = get_current_time_as_text())
  }
}

#' Initialize the logger
init_logger <- function() {
  logger::log_threshold(logger::DEBUG)
  log_layout(layout_glue_generator(format = '{node}/{pid}/{call} {time} {level}: {msg}'))
}

shinyServer(function(input, output, session) {

  init_logger()
  logger::log_debug()
  
  data <- reactiveValues(pwr = load_historical_data(isolate(input$file_save), session))
  
  observeEvent(input$file_pwr, {
    # clicking the Load historical data button
    inFile <- input$file_pwr
    
    if (is.null(inFile))
      return(NULL)
    
    data$pwr <- load_historical_data(inFile$datapath, session)
  })
  
  observeEvent(input$save, {
    # clicking the save button
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
    logger::log_debug()
    
    dt <- prep_data_for_plotting(data$pwr)
    if (is.null(dt)) {
       return(ggplot())
    }
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
    # clicking update time button
    updateTextInput(session, "time", value = get_current_time_as_text())
  })
})
