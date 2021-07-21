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
                                p(),
                                textOutput("uploaddir"),
                                textInput("appname", "Application name"),
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
  ssApps <- reactiveVal()

  observeEvent(input$login, {
    removeModal()

    print("username is")
    print(input$username)
    oursession <- ss_connect(input$username,
                             keyfile = "~/shinysender/id_rsa")
    print(oursession)
    ssSession(oursession)

  })

  observeEvent(ssSession(), {
    ourApps <- ss_appreport(ssSession())
    ssApps(ourApps)
  })

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


  output$uploaddir <- renderText({
    # TODO Make reactive
    # TODO format according to if a valid Shiny App
    file_path <- parseDirPath(c(home="~"), input$appdirinput)
    file_path

  })

  shiny::observeEvent(input$upload, {
    if (is.integer(input$appdirinput)) {
      cat("No files have been selected (shinyFileChoose)")
    } else {
      file_path <- parseDirPath(c(home="~"), input$appdirinput)
      print(file_path)


      # Need to establish:
      # * Is it a shiny app?
      # * Is the app name valid?
      # * Does the app already exist on the server?

      path_files <- list.files(file_path)

      # Check if we have a Shiny app
      if(!shinysender:::isShinyApp(path_files)) {
        showNotification("Directory does not appear to contain a Shiny app")
      } else if(!shinysender:::ss_isAppNameValid(input$appname)){
        showNotification("App name does not appear to be valid")
      } else if(input$appname %in% shinysender::ss_listapps(ssSession())) {
        showNotification("App already exists on server")
      } else {
        showNotification("Uploading")
        # TODO Catch any errors that may occur here
        ss_uploadappdir(ssSession(), file_path, input$appname)

        # Update app list
        ourApps <- ss_appreport(ssSession())
        ssApps(ourApps)

        showNotification("Upload completed")
      }

    }



})

  }



shinyApp(ui, server)
