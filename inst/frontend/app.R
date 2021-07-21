# Frontend for Shinysender

library(shiny)
library(shinydashboard)
library(shinyFiles)
library(shinysender)

static_session <- ss_connect("david", "~/shinysender/id_rsa")

ui <- dashboardPage(dashboardHeader(title = "Shiny Sender"),

                    dashboardSidebar(
                      sidebarMenu(
                        menuItem("Installed Apps", tabName = "installed"),
                        menuItem("Add app", tabName = "add")
                      )),

                    dashboardBody(
                      tabItems(
                        tabItem("installed",
                                h1("Installed applications"),
                                # actionButton("login", "Login"),
                                dataTableOutput("installedapps")
                        ),
                        tabItem("add",
                                h1("Add a new Shiny App"),
                                shinyDirButton("appdirinput", "Select directory",
                                               "Select your Shiny app directory"),
                                actionButton("upload", "Upload app")
                        )


                      )

                    )
)


server <- function(input, output) {

  # https://stackoverflow.com/a/50326449/1683372 details of how to do
  # modals in Shiny server
  startup_modal <- modalDialog(
    title = "Login/Setup",
    textInput("username", "Enter username"),
    footer = modalButton("Login")
  )

  # showModal(startup_modal)

  ssSession <- reactiveVal(static_session)

  observeEvent(input$login, {
    removeModal()

    print("username is")
    print(input$username)
    oursession <- ss_connect(input$username,
                             keyfile = "~/shinysender/id_rsa")
    print(oursession)
    ssSession(oursession)

  })

  ssApps <- reactive({ss_appreport(ssSession()) })

  output$installedapps <- renderDataTable({

    if(class(ssSession()) == "ssh_session")
      ssApps()
    else
      NULL

  })


  observeEvent(input$login,
               {
                 showModal(startup_modal)
               }
  )


  shinyDirChoose(input, "appdirinput",
                 roots = c(home="~"),
                 allowDirCreate = FALSE)

  observe({print(input$appdirinput)})

  shiny::observeEvent(input$upload, {
    if (is.integer(input$appdirinput)) {
      cat("No files have been selected (shinyFileChoose)")
    } else {
      file_path <- parseDirPath(c(home="~"), input$appdirinput)
      print(file_path)
    }
  })

}



shinyApp(ui, server)
