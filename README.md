# README

This Shiny app allows students to manage their subjects' deadlines interactively. You can add, update, and delete tasks, see priorities, set due dates, and track the status of different academic tasks (like labs, exams, presentations).

# Features

- Add new deadlines with subject, task type, date, and auto-assigned priority;
- Update status and notes for selected tasks;
- Delete selected deadline entries;
- Save and load your schedule from a local `.csv` file

# Requirements

- R version 4.0+
- R packages:
  - `shiny`
  - `shinythemes`
  - `reactable`
  - `reactable.extras`

Install required packages:

```r
install.packages(c("shiny", "shinythemes", "reactable", "reactable.extras"))