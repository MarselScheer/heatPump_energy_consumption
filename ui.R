
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

shinyUI(fluidPage(

  # Application title
  titlePanel("Energy consumption of the heat pump"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      numericInput("temperature_outside", label = "Temperature outside:", value = 0.0, min = -80, max = 80, step = 0.1),
      numericInput("power", label = "Value of power indicator:", value = 12000, min = 0, max = Inf, step = 1),
      textInput("time", "Time:", value = lubridate::now()),
      actionButton("update_time_to_now", label = "Update Time"),
      textAreaInput("heatPump_settings", "Settings of the heat pump", value = "Professional tweaked settings on 2019-08-01; 100L Buffer activated"),
      actionButton("save", label = "Save")
    ),

    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("temp_vs_power_consumption"),
      dataTableOutput("power_indicator_by_time")
    )
  )
))
