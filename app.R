# Load R packages 
# install.packages("reactable")
# install.packages("RSQLite")
# install.packages("shinyalert")

library(shiny)
library(shinythemes)
library(reactable)
library(bslib)
library(RSQLite)
library(DBI)
library(dplyr)
library(ggplot2)
library(shinyalert) 
library(bslib)
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
      deadline_date = deadline_date,
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
# Define defensive functions       #
####################################

validate_note <- function(note){
    if (!is.character(note)) {
      stop("Note must be a string.")
    }
  
  if (nchar(note) > 60){
    print("There is more than 60 characters")
    stop("Note must not exceed 60 characters")
  }
  return(TRUE)
}
  
####################################
# Connect database                #
####################################
db <- dbConnect(RSQLite::SQLite(), "scheduler.db")

####################################
# Read the data                    #
####################################
  
program <- dbGetQuery(db, "SELECT * FROM course")
statuses <- dbGetQuery(db, "SELECT name FROM state")
tasks <- dbGetQuery(db, "SELECT name FROM task")
subjects <- dbGetQuery(db, "SELECT name FROM course")

####################################
# UI                               #
####################################
ui <- navbarPage("Personal Scheduler",
       theme = bs_theme(version = 5, bootswatch = "cerulean"),
       tabPanel("Current Schedule",          
        fluidPage(
          useShinyalert(),
          # theme = shinytheme("flatly"),
          h2('My deadlines'),
          fluidRow(
            column(width = 3,
                   div(h4("Add new deadline"),
                       
                   selectInput("subject", label = "Subject", 
                                   choices = subjects, 
                                   selected = NULL),
                       
                   selectInput("task", label = "Task", 
                                   choices = tasks, 
                                   selected = NULL),
                       
                   dateInput("deadline_date", 
                                 label = "Deadline date",
                                 format = "yyyy-mm-dd"),
                       
                   actionButton("addbutton", "Add new deadline",
                                class = "btn btn-primary"),
                   actionButton("extractbutton", "Extract to csv",
                                class = "btn btn-secondary")),
                   tags$hr(),
                   
                   div(h4("Change selected items"),
                       
                   selectInput("cr_state", label = "Current state", 
                                   choices = statuses, 
                                   selected = NULL),
                   textInput("new_note", label = "Leave a note", 
                             placeholder = "max 60 symbols"),
                       
                   actionButton("updateselected", "Update selected item",
                                class = "btn btn-primary" ), 
                   actionButton("deletebutton", "Delete",
                                class = "btn btn-warning"))),
            
            column(width = 9,reactableOutput("new_deadline")),
            verbatimTextOutput("selected")
  ))),
      tabPanel("Progress",
               fluidPage(
                 # theme = shinytheme("flatly"),
                 h2("Check your progress"),
                 fluidRow(
                   column(width = 3,
                          div(h4("Filter by"),
                              
                          selectInput("subject", label = "Subject", 
                                          choices = subjects, 
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
  
  ## Welcome alert ##
  observe({
      upcoming_deadlines <- dbGetQuery(db, "
                 SELECT course_id 
                 FROM deadline 
                 WHERE date BETWEEN DATE('now', '+1 days')
                 AND DATE('now', '+3 days') 
                 AND is_deleted = 0")
    
    today_deadline <- dbGetQuery(db, "
               SELECT course_id  
               FROM deadline 
               WHERE date BETWEEN DATE('now') 
               AND DATE('now', '+0 days') 
               AND is_deleted = 0")

    missed_deadlines <- dbGetQuery(db, "
               SELECT course_id  
               FROM deadline 
               WHERE date < DATE('now') 
               AND date > DATE('now', '-30 days') 
               AND is_deleted = 0")
    
    alert_text <- paste0(
      "You have:\n",
      nrow(today_deadline), " deadline(s) today\n",
      nrow(upcoming_deadlines), " deadline(s) in the next 3 days\n",
      nrow(missed_deadlines), " missed deadline(s)"
    )
    
    shinyalert(
      title = "Welcome!",
      text = alert_text,
      type = "info"
    )

  })
  
  
  ## Build a schedule ##
  v <- reactiveValues()
  
  v$data <- dbGetQuery(db, 'SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
                  FROM deadline d
                  JOIN course c ON d.course_id = c.course_id
                  JOIN task t ON d.task_id = t.task_id
                  JOIN state s ON d.state_id = s.state_id
                  WHERE d.is_deleted = 0')
  
  sorted_by_deadlines <- reactive({
    v$data %>%
      mutate(deadline_date = as.Date(deadline_date)) %>%
      arrange(deadline_date)
  })
  

  selected <- reactive(getReactableState("new_deadline", "selected"))
  

  ## Add new deadline ##
  
  observeEvent(input$addbutton,{
    req(input$subject, input$task, input$deadline_date)
    
    print('Add Button clicked...')
    
    # validate(
    #   need(input$subject != "", "Please select a subject."),
    #   need(input$task != "", "Please select a task."),
    #   need(!is.null(input$deadline_date) && input$deadline_date != "", "Please select a deadline date.")
    # )
    
    showNotification("New deadline saved")
    
    course_id <- dbGetQuery(db, "SELECT course_id FROM course WHERE name = ?", 
                            params = list(input$subject))$course_id
    task_id <- dbGetQuery(db, "SELECT task_id FROM task WHERE name = ?", 
                          params = list(input$task))$task_id
    state_id <- dbGetQuery(db, "SELECT state_id FROM state WHERE name = 'new'")$state_id
    
    # Calculate priority #
    selected_subject <- program[program$name == input$subject,]
    ects <- if (nrow(selected_subject) > 0) {selected_subject$ects}
    
    priority_d <- if (ects < 3) {3}
    else if (ects < 5) {2}
    else {1}
    
    dbExecute(
      db,
      'INSERT INTO deadline (course_id, task_id, date, priority, state_id, note) VALUES (?,?,?,?,?,?)',
      params = list(course_id, task_id, as.character(input$deadline_date), priority_d, state_id, "") 
    )
    
    v$data <- dbGetQuery(db, 'SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
                  FROM deadline d
                  JOIN course c ON d.course_id = c.course_id
                  JOIN task t ON d.task_id = t.task_id
                  JOIN state s ON d.state_id = s.state_id
                  WHERE d.is_deleted = 0')
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
    showNotification("Deadline successfully updated")
    
    req(input$cr_state)
    
    # Defensive validation for the note field
    is_note_correct <- tryCatch({
      validate_note(input$new_note)
      TRUE
    }, error = function(e) {
      showModal(modalDialog(
        title = "Validation Error",
        paste("Update failed:", e$message),
        easyClose = TRUE
      ))
      FALSE
    })
    
    if (!is_note_correct) {
      print("Validation failed. Aborting update.")
      return()
    }
    
    state_id <- dbGetQuery(db, "SELECT state_id FROM state WHERE name = ?", 
                           params = list(input$cr_state))$state_id
    
    # — VECTORISED UPDATE START —
    ids <- sorted_by_deadlines()$deadline_id[selected()]
    if (length(ids)) {
      ph <- paste(rep("?", length(ids)), collapse = ",")
      # params <- c(list(input$cr_state, input$new_note), as.list(ids))
      params <- c(list(state_id, input$new_note), as.list(ids))
      dbExecute(
        db,
        sprintf(
          "UPDATE deadline
           SET state_id = ?, note = ?
         WHERE deadline_id IN (%s)",
          ph
        ),
        params = params
      )
    }
    # — VECTORISED UPDATE END —
    
    v$data <- dbGetQuery(db, 'SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
                  FROM deadline d
                  JOIN course c ON d.course_id = c.course_id
                  JOIN task t ON d.task_id = t.task_id
                  JOIN state s ON d.state_id = s.state_id
                  WHERE d.is_deleted = 0')
  })
  
  
  ## Delete deadline item ##
  observeEvent(input$deletebutton, {
    
    print('Delete button clicked...')
    showNotification("Deadline deleted")
    
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
    
    v$data <- dbGetQuery(db, 'SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
                  FROM deadline d
                  JOIN course c ON d.course_id = c.course_id
                  JOIN task t ON d.task_id = t.task_id
                  JOIN state s ON d.state_id = s.state_id
                  WHERE d.is_deleted = 0')
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
            color <- if (is.na(days)) NULL
            else if (days < 2) "red"
            else if (days < 7) "yellow"
            else NULL
          }
        ),
        deadline_id = colDef(show = FALSE)
      )
    )
  })
  
  ## Filter data for plot ##

  filtered_deadlines <- reactive({
    # req (v$data)
    
    df_filtered <- dbGetQuery(db, 'SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
                  FROM deadline d
                  JOIN course c ON d.course_id = c.course_id
                  JOIN task t ON d.task_id = t.task_id
                  JOIN state s ON d.state_id = s.state_id
                  WHERE d.is_deleted = 0')    %>%
    # df_filtered <- v$data %>%
      mutate(
        deadline_date = as.Date(deadline_date),
        month         = factor(format(deadline_date, "%b"),
                               levels = month.abb)
      )
    cat("Original row count:", nrow(df_filtered), "\n")

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
