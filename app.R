# Load R packages 
# install.packages("reactable")
# install.packages("RSQLite")

library(shiny)
library(shinythemes)
library(reactable)
library(bslib)
library(RSQLite)
library(DBI)

####################################
# Connect database                #
####################################
db <- dbConnect(RSQLite::SQLite(), "scheduler.db")

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
tasks <- c("programming task", "test", "project", "exam", "presentation", "task")

####################################
# UI                               #
####################################
ui <- navbarPage("Personal Scheduler",
       tabPanel("Current Schedule",          
        fluidPage(
          theme = shinytheme("flatly"),
          h2('My deadlines'),
          fluidRow(
            column(width = 3,
                   div(h4("Add new deadline"),
                       
                   selectInput("subject", label = "Subject", 
                                   choices = program$Course.name, 
                                   selected = NULL),
                       
                   selectInput("task", label = "Task", 
                                   choices = tasks, 
                                   selected = NULL),
                       
                   dateInput("deadline_date", 
                                 label = "Deadline date",
                                 format = "yyyy-mm-dd"),
                       
                   actionButton("addbutton", "Add new deadline"),
                   actionButton("extractbutton", "Extract to csv")),
                   tags$hr(),
                   
                   div(h4("Change selected items"),
                       
                   selectInput("cr_state", label = "Current state", 
                                   choices = statuses, 
                                   selected = NULL),
                   textInput("new_note", label = "Keep a note"),
                       
                   actionButton("updateselected", "Update selected item"), 
                   actionButton("deletebutton", "Delete"))),
            
            column(width = 9,reactableOutput("new_deadline")),
            verbatimTextOutput("selected")
  ))),
      tabPanel("Progress",
               fluidPage(
                 theme = shinytheme("flatly"),
                 h2("Check your progress"),
                 fluidRow(
                   column(width = 3,
                          div(h4("Filter by"),
                              
                          selectInput("subject", label = "Subject", 
                                          choices = program$Course.name, 
                                          selected = NULL),
                              
                          selectInput("task", label = "Task", 
                                          choices = tasks, 
                                          selected = NULL),
                          
                          selectInput("state", label = "State", 
                                      choices = statuses, 
                                      selected = NULL),
                              
                          dateInput("month", label = "Month",
                                        format = "MM"),
                          dateInput("date", label = "Date",
                                    format = "yyyy-mm-dd"),
                              
                          actionButton("applybutton", "Apply filters"),
                   
                 )),
                 column(width = 9,plotOutput("progress_plot")))
                 
               ))
  
    # mainPanel(reactableOutput("new_deadline"),verbatimTextOutput("selected")),
  
)

####################################
# Server                           #
####################################

server<- function(input, output, session) {
  
  ## Build a schedule ##
  v <- reactiveValues()
  v$data <- dbGetQuery(db, 'SELECT deadline_id, subject, task, deadline_date, priority, state, note
                  FROM deadline
                  WHERE is_deleted = 0')
  sorted_by_deadlines <- reactive({
    v$data[order(as.Date(v$data$deadline_date)), ]})
  
  selected <- reactive(getReactableState("new_deadline", "selected"))
  print(selected)
  ## Add new deadline ##
  
  observeEvent(input$addbutton,{
    
    print('Add Button clicked...')
    
    req(input$subject, input$task, input$deadline_date)
    
    # Calculate priority #
    selected_subject <- program[program$Course.name == input$subject,]
    ects <- if (nrow(selected_subject) > 0) {selected_subject$ECTS}
    
    priority_d <- if (ects < 3) {3}
    else if (ects < 5) {2}
    else {1}
    
    new_entry <- data.frame(
      subject = input$subject,
      task = input$task,
      deadline_date = as.character(as.Date(input$deadline_date)),
      priority = priority_d,
      state = "new",
      note = "",
      stringsAsFactors = FALSE
    )
    
    dbExecute(db,'INSERT INTO deadline (subject, task,deadline_date, priority, state, note ) 
               VALUES (?,?,?,?,?,?)',
               params = list(
                 new_entry$subject,
                 new_entry$task,
                 new_entry$deadline_date,
                 new_entry$priority,
                 new_entry$state,
                 new_entry$note
               ))
    v$data <- dbGetQuery(db, 'SELECT deadline_id, subject, task, deadline_date, priority, state, note
                             FROM deadline
                             WHERE is_deleted = 0')
  })
  
  # Extract schedule to csv file ##
  observeEvent(input$extractbutton,{

    print('Extract Button clicked...')

    write.table(v$data,
                file = "deadlines.csv",
                sep = ",",
                append = FALSE,
                quote = TRUE,
                col.names = colnames(v$data),
                row.names = FALSE)

  })
  
  ## Update deadline item ##
  observeEvent(input$updateselected, {
    
    print('Update Button clicked...')
    
    req(input$cr_state)
    
    selected_items <- selected()
    
      if (length(selected_items) > 0) {
        for (i in selected_items) {
          row_id <- sorted_by_deadlines()[i, "deadline_id"]
        
        
    dbExecute(db, 'UPDATE deadline 
                    SET state = ?, note = ? 
                    WHERE deadline_id = ?',
                params = list(input$cr_state, input$new_note, row_id))}}
    
    v$data <- dbGetQuery(db, 'SELECT deadline_id, subject, task, deadline_date, priority, state, note
                          FROM deadline
                          WHERE is_deleted = 0')
  })
  

  
  ## Delete items ##
  observeEvent(input$deletebutton, {
    
    print('Delete button clicked...')
    
    selected_items <- selected()
    
    if (length(selected_items) > 0) {
      for (i in selected_items) {
        row_id <- sorted_by_deadlines()[i, "deadline_id"]
        
        
    dbExecute(db, 'UPDATE deadline 
                    SET is_deleted = TRUE 
                    WHERE deadline_id = ?',
                  params = list(row_id))}}
    
    v$data <- dbGetQuery(db, 'SELECT deadline_id, subject, task, deadline_date, priority, state, note
                          FROM deadline
                          WHERE is_deleted = 0')
    
  })
  
  ## Render the table ##
  output$new_deadline <- renderReactable({
    
    reactable(sorted_by_deadlines(), 
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
                deadline_date = colDef(
                  defaultSortOrder = "desc",
                  style = function(value) {
                    if (as.Date(value) - Sys.Date() < 3) {
                      color <- "red"}
                    else if (as.Date(value) - Sys.Date() < 7)  {
                      color <- "yellow"}
                    else {color <- NULL}
                    list(background = color)}),
                deadline_id = colDef(show = FALSE)
                
              )
    )
    
  }
  )
  observe({
    print(v$data)
  })
  
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
