# README

**Personal Scheduler** is a Shiny web application designed to help students (and others) manage deadlines and monitor academic workload over time. It supports task scheduling, visual progress tracking, and burnout risk forecasting via the `burnoutTools` package.

Why this project?<br>
Managing multiple deadlines is stressful, especially for students balancing subjects on different platforms. We designed this tool to:<br>

- Help users visualize and prioritize their tasks.<br>
- Track progress interactively.<br>
- Forecast burnout risk.<br>

# Features

- **Add deadlines** with subject, task type, due date, and auto-assigned priority.
- **Update** task status and add personal notes.
- **Delete** multiple selected tasks at once.
- **Export** your current schedule to a `.csv` file.
- **Monitor progress** by filtering tasks by subject, task, state, or month.
- **Forecast burnout** using `burnoutTools`: simulates how workload, productivity, and fatigue interact over time.

# Installation Requirements

- **R version:** 4.0 or newer
- **SQLite** installed and writable
- **Required R packages:**

```r
install.packages(c(
  "shiny", "shinythemes", "reactable", "bslib", 
  "RSQLite", "DBI", "dplyr", "ggplot2", 
  "shinyalert", "shinycssloaders"
))
```

# Code functionality 
## Custom Classes and Methods
**Deadline S3 class** encapsulates each task with fields such as subject, task, date, priority, state, and note.<br> 
Methods:<br> 

- print.Deadline() – Formatted print output.<br> 
- as.data.frame.Deadline() – Converts to a row-ready format for database.<br>
- urgency.Deadline() – Calculates days left until deadline.<br>
- setState.Deadline() – Updates the status and note.<br>
- validate_note() ensures note length does not exceed 60 characters.<br>

## Database Operations

The application uses SQLite via RSQLite and DBI. All CRUD operations are fully vectorised, meaning multiple rows can be processed in one call. 
The application uses reactive values (reactiveValues() and reactive()) to manage the current deadline list (v$data). 
Filtering and mutating are done using dplyr pipelines to avoid per-row loops.

## Task priority 
Priorities are auto-assigned based on ECTS values:<br>

3 ECTS → low priority (3)<br>
4–5 ECTS → medium priority (2)<br>
5 ECTS → high priority (1)<br>

## Schedule tab

Deadlines selection is enabled through reactable with row selection. 
Deadlines can be added, updated, and deleted using UI and backend vector logic.
Real-time alerts and feedback via shinyalert and showNotification().

## Progress tab

Users can filter by subject, task, month, and state. Visualization is handled with ggplot2 using stacked bar charts:
```
ggplot(df_summary, aes(x = month, y = task_count, fill = state)) +
  geom_bar(stat = "identity")
```
Real-time notifications and alerts are triggered using shinyalert() and showNotification().

## Burnout Forecast tab
The burnoutTools package simulates burnout risk using a C++ backend via Rcpp. Built specifically for **Personal scheduler** application, it forecasts how fatigue and productivity interact based on task load.
The Forecast tab lets users simulate burnout with options for task count, productivity, and workload.

For more details please read README file for the ***burnoutTools*** package. 