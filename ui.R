
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
      textInput("file_save", "Save location:", value = "/srv/data/power_by_time.csv"),
      numericInput("temperature_outside", label = "Temperature outside:", value = 0.1, min = -80, max = 80, step = 0.1),
      numericInput("power_indicator", label = "Value of power indicator:", value = 12000, min = 0, max = Inf, step = 1),
      textInput("time", "Time:", value = lubridate::now()),
      actionButton("update_time_to_now", label = "Update Time"),
      textAreaInput("heatPump_settings", "Settings of the heat pump", value = "Professional tweaked settings on 2019-08-01; 100L Buffer activated"),
      actionButton("save", label = "Save"),
      fileInput("file_pwr", label = "Load historical data (if necessary):"),
      p("Version: 0.1.1.9000", style = "font-size:9px;float:right")
    ),

    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel(
          "Summary", 
          plotOutput("temp_vs_power_consumption"),
          dataTableOutput("power_indicator_by_time")),
        tabPanel(
          "Changelog", 
          
          h1("v0.1.2"),
          p("- input element for temperature is not initialized with an integer (in order to gurantee that a decimal point is available) "),
          
          h1("v0.1.1"),
          p("- temperature outside, power indicator and heatpump settings are initialized with the latest stored values"),
          
          h1("v0.1.0"),
          p("- data is stored as plain csv"),
          p("- data can be loaded"),
          p("- temperature and value of power indicator can be entered manually"),
          p("- free text that describes the settings can be added"),
          p("- scatterplot of cost per day versus temperature with simple linear regression stratified by the free text for the settings"))
      )
      )
    )
  )
)
