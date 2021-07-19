# Frontend for Shinysender

library(shiny)
library(shinydashboard)

ui <- dashboardPage(dashboardHeader(title = "Shiny Sender"),
              dashboardSidebar(),
              dashboardBody())


server <- function(input, output) {


}


shinyApp(ui, server)
