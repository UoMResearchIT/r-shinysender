# Frontend for Shinysender

library(shiny)
library(shinydashboard)

ui <- dashboardPage(dashboardHeader(title = "Shiny Sender"),
              dashboardSidebar(),
              dashboardBody())


server <- function(input, output) {

# https://stackoverflow.com/a/50326449/1683372 details of how to do
# modals in Shiny server

}


shinyApp(ui, server)
