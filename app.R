####################################
# Load packages                    #
####################################
# install.packages("reactable")
# install.packages("RSQLite")
# install.packages("shinyalert")
# devtools::load_all("burnoutTools")
# install.packages("shinycssloaders")

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
library(burnoutTools) # custom package which contains C++ implementations via Rcpp
library(shinycssloaders)

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

validate_note <- function(note) {
  if (!is.character(note)) {
    stop("Note must be a string.")
  }
  
  if (nchar(note) > 60){
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
                            useShinyalert(force=TRUE),
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
                                                      class = "btn btn-primary"), 
                                         
                                         actionButton("deletebutton", "Delete",
                                                      class = "btn btn-warning"))),
                              
                              column(width = 9,reactableOutput("new_deadline")),
                              verbatimTextOutput("selected")
                            ))),
                 
                 tabPanel("Progress",
                          fluidPage(
                            h2("Check your progress"),
                            fluidRow(
                              column(width = 3,
                                     div(h4("Filter by"),
                                         selectInput("prog_subject", label = "Subject", choices = subjects, multiple = TRUE),
                                         selectInput("prog_task", label = "Task", choices = tasks, multiple = TRUE),
                                         selectInput("prog_state", label = "State", choices = statuses, multiple = TRUE),
                                         selectInput("prog_month", label = "Month", choices = c(`(All)` = "", month.abb))
                                     )),
                              column(width = 9,plotOutput("progress_plot")))
                            
                          )), 
                 
                 tabPanel("Forecast",
                          fluidPage(
                            h2("Burnout Forecast"),
                            
                            p("This tool estimates how your workload, fatigue, and burnout risk may evolve in the next few weeks. 
                               The model simulates how task pressure and recovery interact over time."),
                            
                            tags$details(
                              tags$summary("How the model works"),
                              tags$ul(
                                tags$li("You start with a number of unfinished tasks."),
                                tags$li("Each day, your productivity determines how many tasks you complete."),
                                tags$li("New tasks arrive randomly each day based on the rate you set."),
                                tags$li("If your backlog exceeds a threshold, burnout risk increases."),
                                tags$li("Prolonged overload causes fatigue, which reduces future productivity."),
                                tags$li("If workload stays low, fatigue gradually recovers."),
                                tags$li("The process is repeated multiple times to average out randomness.")
                              )
                            ),
                            
                            sidebarLayout(
                              sidebarPanel(
                                h4("Simulation Settings"),
                                
                                checkboxInput("auto_tasks", "Estimate task count from schedule", value = FALSE),
                                textOutput("task_info"),
                                
                                numericInput("n_tasks", "Pending tasks (manual entry)", value = 8, min = 1, step = 1),
                                
                                sliderInput("p_success", "Productivity (% tasks completed per day)", min = 10, max = 100, value = 60, step = 5),
                                
                                numericInput("burnout_threshold",
                                             label = tagList("Burnout threshold",
                                                             tags$small("Risk increases when pending tasks exceed this number")),
                                             value = 3, min = 1, max = 20),
                                
                                numericInput("arrival_rate", "Average number of new tasks/day", value = 0.5, min = 0, max = 10, step = 0.1),
                                
                                tags$details(
                                  tags$summary("Advanced options"),
                                  numericInput("forecast_days", "Days to simulate", value = 30, min = 5, max = 90),
                                  numericInput("forecast_reps", "Simulation repetitions", value = 100, min = 10, max = 1000)
                                ),
                                
                                actionButton("simulate_burnout", "Run Forecast", class = "btn btn-primary"),
                                br(), br(),
                                uiOutput("forecast_package_version"),
                                HTML("<small style='color: #888;'>Developed as part of university coursework</small>")
                              ),
                              
                              mainPanel(
                                h4("Forecast Plot"),
                                shinycssloaders::withSpinner(plotOutput("burnout_plot")),
                                br(),
                                uiOutput("summary_stats"),
                                br(),
                                uiOutput("peak_gauge_ui"),
                                helpText("Note: The shaded area on the plot highlights days when estimated burnout risk is high (above 0.7). 
                                          Fatigue reduces your productivity over time when you're overloaded. 
                                          Use this forecast to reflect on whether your pace is manageable.")
                              ))
                          )
                 )
)
                 

####################################
# Server                           #
####################################

server<- function(input, output, session) {
  
  ## Plot update trigger  ##
  plot_trigger <- reactiveVal(0)
  
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
  # — vectorised update start —
  v <- reactiveValues()
  
  v$data <- dbGetQuery(db, '
                  SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
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
  # — vectorised update end —
  
  ## Add new deadline ##
  observeEvent(input$addbutton,{
    req(input$subject, input$task, input$deadline_date)
    
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
    
    v$data <- dbGetQuery(db, '
                  SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
                  FROM deadline d
                  JOIN course c ON d.course_id = c.course_id
                  JOIN task t ON d.task_id = t.task_id
                  JOIN state s ON d.state_id = s.state_id
                  WHERE d.is_deleted = 0')
    
    showNotification("New deadline saved")
    
    # Re-render the plot after adding a new record
    plot_trigger(plot_trigger() + 1)
  })
  
  ## Extract schedule to csv file ##
  observeEvent(input$extractbutton, {
    write.table(v$data,
                file = "deadlines.csv",
                sep = ",",
                append = FALSE,
                quote = TRUE,
                col.names = colnames(v$data),
                row.names = FALSE)}
  )
  
  ## Update deadline item ##
  observeEvent(input$updateselected, {
    
    req(input$cr_state)
    
    # Validation for the note field
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
    
    state_id <- dbGetQuery(db, 
                           "SELECT state_id FROM state WHERE name = ?", 
                           params = list(input$cr_state))$state_id
    
    # — vectorised update start —
    ids <- sorted_by_deadlines()$deadline_id[selected()]
    if (length(ids)) {
      ph <- paste(rep("?", length(ids)), collapse = ",")
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
    # — vectorised update end —
    
    v$data <- dbGetQuery(db, '
                  SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
                  FROM deadline d
                  JOIN course c ON d.course_id = c.course_id
                  JOIN task t ON d.task_id = t.task_id
                  JOIN state s ON d.state_id = s.state_id
                  WHERE d.is_deleted = 0')
    
    showNotification("Deadline successfully updated")
    
    # Re-render the plot after updating a record
    plot_trigger(plot_trigger() + 1)
  })
  
  
  ## Delete deadline item ##
  observeEvent(input$deletebutton, {

    # collect all selected IDs
    ids <- sorted_by_deadlines()$deadline_id[selected()]
    
    # update selected items
    if (length(ids)) {
      ph     <- paste(rep("?", length(ids)), collapse = ",")
      params <- as.list(ids)
      dbExecute(
        db,
        sprintf("
            UPDATE deadline
            SET is_deleted = TRUE
            WHERE deadline_id IN (%s)",
                ph
        ),
        params = params
      )
    }
    
    v$data <- dbGetQuery(db, '
                  SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
                  FROM deadline d
                  JOIN course c ON d.course_id = c.course_id
                  JOIN task t ON d.task_id = t.task_id
                  JOIN state s ON d.state_id = s.state_id
                  WHERE d.is_deleted = 0')
    
    showNotification("Deadline deleted")
    
    # Re-render the plot after deleting a record
    plot_trigger(plot_trigger() + 1)
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
            list(background = color)
          }
        ),
        deadline_id = colDef(show = FALSE)
      )
    )
  })
  
  # Show package version
  output$forecast_package_version <- renderUI({
    HTML(paste0(
      "<div style='font-size: 12px; color: grey;'>burnoutTools version: ",
      as.character(packageVersion("burnoutTools")),
      "</div>"
    ))
  })
  
  # Store simulation results reactively
  df_reactive <- reactiveVal(NULL)
  
  # Count unfinished tasks from schedule data
  auto_task_count <- reactive({
    req(v$data)
    unfinished <- v$data %>% filter(state != "done" & state != "cancelled")
    nrow(unfinished)
  })
  
  # Show task info text based on auto_tasks checkbox
  output$task_info <- renderText({
    if (isTRUE(input$auto_tasks)) {
      count <- auto_task_count()
      if (count == 0) "No pending tasks detected. Using manual input."
      else paste("Detected", count, "pending task(s).")
    } else {
      ""
    }
  })
  
  # Determine number of tasks for simulation
  sim_n_tasks <- reactive({
    if (isTRUE(input$auto_tasks)) {
      count <- auto_task_count()
      if (count == 0) input$n_tasks else count
    } else {
      input$n_tasks
    }
  })
  
  # Run simulation on button click
  observeEvent(input$simulate_burnout, {
    if (sim_n_tasks() < 1 || input$forecast_days < 1 || input$forecast_reps < 1) {
      showModal(modalDialog(title = "Input Error",
                            "Please ensure all numeric inputs are positive.",
                            easyClose = TRUE))
      return()
    }
    
    req(sim_n_tasks(), input$p_success, input$burnout_threshold, input$forecast_days, input$forecast_reps)
    
    df <- burnoutTools::simulate_burnout(
      n_tasks = sim_n_tasks(),
      p = input$p_success / 100,
      threshold = input$burnout_threshold,
      days = input$forecast_days,
      reps = input$forecast_reps,
      task_arrival_rate = input$arrival_rate
    )
    
    df_reactive(df)
  })
  
  # Plot the simulation results
  output$burnout_plot <- renderPlot({
    req(df_reactive())
    df <- df_reactive()
    
    validate(
      need("Day" %in% colnames(df), "Simulation must return a 'Day' column."),
      need("BurnoutRisk" %in% colnames(df), "Simulation must return a 'BurnoutRisk' column.")
    )
    
    burnoutTools::plot_burnout_forecast(df)
  })
  
  # Show summary metrics under the plot
  output$summary_stats <- renderUI({
    req(df_reactive())
    df <- df_reactive()
    
    HTML(paste0(
      "<b>Simulation Summary:</b><br/>",
      "Days with high burnout risk (> 0.7): ",
      round(df$Summary_HighRiskDays[1], 1), "<br/>",
      "Day of peak burnout risk: ",
      df$Summary_PeakRiskDay[1], "<br/>",
      "Maximum fatigue level: ",
      round(df$Summary_MaxFatigue[1], 2)
    ))
  })

  ## Filter data for plot ##
  # — vectorised update start —
  filtered_deadlines <- reactive({
    
    # Trigger dependency
    plot_trigger()
    
    df_filtered <- dbGetQuery(db, '
                  SELECT d.deadline_id, c.name AS subject, t.name AS task, d.date AS deadline_date, d.priority, s.name AS state, d.note
                  FROM deadline d
                  JOIN course c ON d.course_id = c.course_id
                  JOIN task t ON d.task_id = t.task_id
                  JOIN state s ON d.state_id = s.state_id
                  WHERE d.is_deleted = 0')    %>%
      mutate(
        deadline_date = as.Date(deadline_date),
        month         = factor(format(deadline_date, "%b"),
                               levels = month.abb)
      )
    
    if (length(input$prog_subject) > 0) {
      df_filtered <- df_filtered %>% filter(subject %in% input$prog_subject)
    }
    if (length(input$prog_task) > 0) {
      df_filtered <- df_filtered %>% filter(task %in% input$prog_task)
    }
    if (length(input$prog_state) > 0) {
      df_filtered <- df_filtered %>% filter(state %in% input$prog_state)
    }
    if (nzchar(input$prog_month)) {
      df_filtered <- df_filtered %>% filter(month == input$prog_month)
    }
    df_filtered
  })
  # — vectorised update end —
  
  ## Render plot ##
  # — vectorised update start —
  output$progress_plot <- renderPlot({
    
    df_plot <- filtered_deadlines()
    
    if (nrow(df_plot) == 0) {return(NULL)}
    
    df_plot$state <- as.character(df_plot$state)
    
    df_summary <- df_plot %>%
      group_by(month,state) %>%
      summarise(task_count = n(), .groups = "drop")
    
    ggplot(df_summary, aes(x = month, y = task_count, fill = state)) +
      geom_bar(stat = "identity", position = "stack") +
      labs(title = "Task Count by State", x = "Month", y = "Number of Tasks") +
      theme_minimal()
  })
  # — vectorised update end —
  
}


####################################
# Create the shiny app             #
####################################
shinyApp(ui = ui, server = server)
