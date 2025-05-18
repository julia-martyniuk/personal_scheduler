# Load R packages 
# install.packages("reactable")
# install.packages("RSQLite")

library(shiny)
library(shinythemes)
library(reactable)
library(bslib)
library(RSQLite)
library(DBI)
library(dplyr)
library(ggplot2)

####################################
# Define classes                   #
####################################

# ---- S3 “Deadline” class definitions begin here ----

Deadline <- function(subject, task, deadline_date, priority,
                     state = "new", note = "") {
  stopifnot(
    is.character(subject), length(subject) == 1,
    is.character(task),    length(task)    == 1,
    inherits(as.Date(deadline_date), "Date"),
    is.numeric(priority),  length(priority) == 1,
    state %in% c("new","in progress","done","cancelled")
  )
  structure(
    list(
      subject       = subject,
      task          = task,
      deadline_date = as.Date(deadline_date),
      priority      = priority,
      state         = state,
      note          = note
    ),
    class = "Deadline"
  )
}

# ---- S3 definitions end here ----
# ---- S3 “Deadline” methods ----

print.Deadline <- function(x, ...) {
  cat(
    sprintf(
      "<Deadline> %s — %s\n  Due: %s | Prio: %d | State: %s\n  Note: %s\n",
      x$subject, x$task,
      format(x$deadline_date), x$priority, x$state,
      ifelse(x$note == "", "<none>", x$note)
    )
  )
}

as.data.frame.Deadline <- function(x, ...) {
  data.frame(
    subject       = x$subject,
    task          = x$task,
    deadline_date = as.character(x$deadline_date),
    priority      = x$priority,
    state         = x$state,
    note          = x$note,
    stringsAsFactors = FALSE
  )
}

# ---- end S3 methods ----
# ---- begin S3: urgency ----

urgency <- function(x) UseMethod("urgency")

# for a single Deadline, returns (deadline_date − today)
urgency.Deadline <- function(x) {
  as.numeric(x$deadline_date - Sys.Date())
}

# ---- end S3: urgency ----
# ---- begin S3: setState ----

setState <- function(x, state, note) UseMethod("setState")

setState.Deadline <- function(x, state, note = "") {
  x$state <- state
  x$note  <- note
  x
}

# ---- end S3: setState ----


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
                                          selected = NULL,
                                          multiple = TRUE),
                              
                          selectInput("task", label = "Task", 
                                          choices = tasks, 
                                          selected = NULL,
                                          multiple = TRUE),
                          
                          selectInput("state", label = "State", 
                                      choices = statuses, 
                                      selected = NULL,
                                      multiple = TRUE),
                              
                          selectInput("month", label   = "Month",
                            choices = c(`(All)` = "", month.abb),
                            selected = ""
                          )
                 )),
                 column(width = 9,plotOutput("progress_plot")))
                 
               ))
  
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
    v$data %>%
      mutate(deadline_date = as.Date(deadline_date)) %>%
      arrange(deadline_date)
  })

  selected <- reactive(getReactableState("new_deadline", "selected"))
  

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
    
    dl <- Deadline(
      subject       = input$subject,
      task          = input$task,
      deadline_date = input$deadline_date,
      priority      = priority_d
    )
    new_entry <- as.data.frame.Deadline(dl)
    
    dbExecute(
      db,
      'INSERT INTO deadline (subject, task, deadline_date, priority, state, note) VALUES (?,?,?,?,?,?)',
      params = unname(new_entry[1, ])
    )
    
    v$data <- dbGetQuery(db, 'SELECT deadline_id, subject, task, deadline_date, priority, state, note
                              FROM deadline
                              WHERE is_deleted = 0')
  })
  
  ## Extract schedule to csv file ##
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
    
    # — VECTORISED UPDATE START —
    ids <- sorted_by_deadlines()$deadline_id[selected()]
    if (length(ids)) {
      ph <- paste(rep("?", length(ids)), collapse = ",")
      params <- c(list(input$cr_state, input$new_note), as.list(ids))
      dbExecute(
        db,
        sprintf(
          "UPDATE deadline
           SET state = ?, note = ?
         WHERE deadline_id IN (%s)",
          ph
        ),
        params = params
      )
    }
    # — VECTORISED UPDATE END —
    
    v$data <- dbGetQuery(db, '
    SELECT deadline_id, subject, task, deadline_date, priority, state, note
    FROM deadline
    WHERE is_deleted = 0
  ')
  })
  
  
  ## Delete deadline item ##
  observeEvent(input$deletebutton, {
    
    print('Delete button clicked...')
    
    # collect all selected IDs
    ids <- sorted_by_deadlines()$deadline_id[selected()]
    
    # update selected items
    if (length(ids)) {
      ph     <- paste(rep("?", length(ids)), collapse = ",")
      params <- as.list(ids)
      dbExecute(
        db,
        sprintf(
          "UPDATE deadline
            SET is_deleted = TRUE
          WHERE deadline_id IN (%s)",
          ph
        ),
        params = params
      )
    }
    
    v$data <- dbGetQuery(db, '
    SELECT deadline_id, subject, task, deadline_date, priority, state, note
      FROM deadline
     WHERE is_deleted = 0
  ')
  })
  
  ## Render table ##
  output$new_deadline <- renderReactable({
    
    days_left_df <- sorted_by_deadlines() %>%
      mutate(
        days_left = as.numeric(deadline_date - Sys.Date())
      )
    
    reactable(
      days_left_df,
      striped   = TRUE,
      highlight = TRUE,
      selection = "multiple",
      onClick   = "select",
      sortable  = TRUE,
      defaultSorted = list(days_left = "asc"),
      theme = reactableTheme(
        borderColor      = "#dfe2e5",
        stripedColor     = "#f6f8fa",
        highlightColor   = "cornsilk",
        cellPadding      = "8px 12px",
        style            = list(fontFamily = "-apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif"),
        searchInputStyle = list(width = "100%")
      ),
      columns = list(
        
        days_left = colDef(
          name   = "days left",
          footer = htmltools::tags$span(
            style = "font-style: italic;",
            "lower = more urgent"
          )
        ),
        
        deadline_date = colDef(
          defaultSortOrder = "desc",
          style = function(value) {
            days <- as.Date(value) - Sys.Date()
            color <- if (days < 3) "red"
            else if (days < 7) "yellow"
            else NULL
            list(background = color)
          }
        ),
        deadline_id = colDef(show = FALSE)
      )
    )
  })
  
  ## Filter data for plot ##

  filtered_deadlines <- reactive({
    
    df_filtered <- dbGetQuery(db, 'SELECT deadline_id, subject, task, deadline_date, priority, state, note
                                       FROM deadline
                                       WHERE is_deleted = 0')    %>%
      mutate(
        deadline_date = as.Date(deadline_date),
        month         = factor(format(deadline_date, "%b"),
                               levels = month.abb)
      )
    # cat("Original row count:", nrow(df_filtered), "\n")

    if (length(input$subject) > 0) {
      df_filtered <- df_filtered %>% filter(subject %in% input$subject)
      # cat("After subject filter:", nrow(df_filtered), "\n")
    }
    if (length(input$task) > 0) {
      df_filtered <- df_filtered %>% filter(task %in% input$task)
      # cat("After task filter:", nrow(df_filtered), "\n")
    }
    if (length(input$state) > 0) {
      df_filtered <- df_filtered %>% filter(state %in% input$state)
      # cat("After state filter:", nrow(df_filtered), "\n")
    }
    if (nzchar(input$month)) {
      df_filtered <- df_filtered %>% filter(month == input$month)
      # cat("After month filter:", nrow(df_filtered), "\n")
    }
    df_filtered
})
  
  
  ## Render plot ##
  output$progress_plot <- renderPlot({
    df_plot <- filtered_deadlines()
    
    if (nrow(df_plot) == 0) {
      return(NULL)}
    
    df_plot$state <- as.character(df_plot$state)
    
    df_summary <- df_plot %>%
      group_by(month,state) %>%
      summarise(task_count = n(), .groups = "drop")
    
    ggplot(df_summary, aes(x = month, y = task_count, fill = state)) +
      geom_bar(stat = "identity", position = "stack") +
      labs(title = "Task Count by State", x = "Month", y = "Number of Tasks") +
      theme_minimal()
    })
}

  
  # Test outputs and button behavior 
  # observe({
  #   print(v$data)
  # })
  # 
  # output$selected <- renderPrint({
  #   print(selected())
  # })
  # 
  # observe({
  #   print(v$data[selected(), ])
  # })
  
####################################
# Create the shiny app             #
####################################
shinyApp(ui = ui, server = server)
