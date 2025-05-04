# Load R packages 
# install.packages("reactable")
# install.packages("reactable.extras")
library(shiny)
library(shinythemes)
library(reactable)
library(reactable.extras)

####################################
# Read the data                    #
####################################
read_data <- function() {
  program <- read.csv("NW2-DS.csv")
  program$Course.name <- 
    sprintf("%s - %s", program$Course.name, program$Course.type)
  program
}

program <- read_data()

statuses <- c("new", "in progress", "done", "cancelled")

####################################
# UI                               #
####################################
ui <- fluidPage(
  reactable_extras_dependency(),
  theme = shinytheme("flatly"),
  titlePanel('My deadlines'),
  fluidRow(
    column(width = 3,
           div(h4("Add new deadline"),
               
               selectInput("subject", label = "Subject:", 
                           choices = program$Course.name, 
                           selected = NULL),
               
               selectInput("task", label = "Task:", 
                           choices = list("programming task", 
                                          "test", 
                                          "project", 
                                          "exam", 
                                          "presentation", 
                                          "task"), 
                           selected = NULL),
               
               dateInput("deadlinedate", 
                         label = "Deadline date:",
                         format = "yyyy-mm-dd"),
               
               actionButton("addbutton", "Add new deadline"),
               actionButton("savebutton", "Save Schedule")
           ),
           tags$hr(),
           div(h4("Change selected items"),
               
               selectInput("cr_state", label = "Current state:", 
                           choices = list("new", 
                                          "in progress", 
                                          "done", 
                                          "cancelled"), 
                           selected = NULL),
               textInput("new_note", label = "Keep a note:"),
               
               actionButton("updateselected", "Update selected item"), 
               actionButton("deletebutton", "Delete"))
    ),
    
    column(width = 9,reactableOutput("new_deadline")),
    verbatimTextOutput("selected")
    
    # mainPanel(reactableOutput("new_deadline"),verbatimTextOutput("selected")),
  )
)

####################################
# Server                           #
####################################

server<- function(input, output, session) {
  
  ## Build a schedule ##
  v <- reactiveValues()
  if (file.exists("deadlines.csv")) {
    v$data <- read.csv("deadlines.csv")
    # print(v$data)
  }
  else {
    v$data <- data.frame(
      subject = as.character(),
      task = as.character(),
      deadlinedate = as.Date(character()),
      priority = as.integer(),
      state = as.character(),
      note = as.character(),
      stringsAsFactors = FALSE)
    # print(v$data)
  }
  
  selected <- reactive(getReactableState("new_deadline", "selected"))
  ## Add new deadline ##
  
  observeEvent(input$addbutton,{
    
    print('Add Button clicked...')
    
    req(input$subject, input$task, input$deadlinedate)
    
    # Calculate priority #
    selected_subject <- program[program$Course.name == input$subject,]
    ects <- if (nrow(selected_subject) > 0) {selected_subject$ECTS}
    
    priority_d <- if (ects < 3) {3}
    else if (ects < 5) {2}
    else {1}
    
    new_entry <- data.frame(
      subject = input$subject,
      task = input$task,
      deadlinedate = as.character(as.Date(input$deadlinedate)),
      priority = priority_d,
      state = "new",
      note = "write note",
      stringsAsFactors = FALSE
    )
    
    ## Delete entry ##
    # observe(input$buttondelete, {})
    
    v$data <- rbind(v$data, new_entry)  
    # print(v$data)
    
  })
  
  ## Update csv table ##
  observeEvent(input$savebutton,{
    
    print('Save Button clicked...')
    
    write.table(v$data, 
                file = "deadlines.csv", 
                sep = ",", 
                append = FALSE, # file.exists("deadlines.csv"), 
                quote = TRUE, 
                col.names = colnames(v$data), # !file.exists("deadlines.csv"), 
                row.names = FALSE)
  })
  
  ## Update deadline item ##
  observeEvent(input$updateselected, {
    
    print('Update Button clicked...')
    
    req(input$cr_state)
    
    selected_items <- selected()
    
    if (length(selected_items) > 0) {
      v$data[selected_items, "state"] <- input$cr_state
      v$data[selected_items, "note"] <- input$new_note
    }
  })
  
  ## Delete items ##
  observeEvent(input$deletebutton, {
    
    print('Delete button clicked...')
    
    selected_items <- selected()
    
    if (length(selected_items) > 0) {
      v$data <- v$data[-c(selected_items),]
    }
  })
  
  ## Render the table ##
  output$new_deadline <- renderReactable({
    sorted_by_deadlines <- v$data[order(as.Date(v$data$deadlinedate)),]
    
    # v$data$check <- sample(c(TRUE, FALSE), nrow(v$data), TRUE)
    
    reactable(sorted_by_deadlines, 
              striped = TRUE,
              highlight = TRUE,
              selection = "multiple",
              onClick = "select",
              theme = reactableTheme(
                borderColor = "#dfe2e5",
                stripedColor = "#f6f8fa",
                highlightColor = "cornsilk",
                cellPadding = "8px 12px",
                style = list(fontFamily = "-apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif"),
                searchInputStyle = list(width = "100%")
              ),
              columns = list(
                deadlinedate = colDef(
                  defaultSortOrder = "desc",
                  style = function(value) {
                    if (as.Date(value) - Sys.Date() < 3) {
                      color <- "red"}
                    else if (as.Date(value) - Sys.Date() < 7)  {
                      color <- "yellow"}
                    else {color <- NULL}
                    list(background = color)})
                
              )
    )
    
  }
  )
  
  output$selected <- renderPrint({
    print(selected())
  })
  
  observe({
    print(v$data[selected(), ])
  })
} 

####################################
# Create the shiny app             #
####################################
shinyApp(ui = ui, server = server)
