CREATE TABLE course (
course_id INTEGER PRIMARY KEY AUTOINCREMENT,
code VARCHAR(255),
name VARCHAR(255) NOT NULL,
hours INTEGER NOT NULL, 
ects DECIMAL(2,2) NOT NULL,
semester INTEGER,
credit_form VARCHAR(255));

CREATE TABLE task (
task_id INTEGER PRIMARY KEY AUTOINCREMENT,
name VARCHAR(255) NOT NULL);

CREATE TABLE state (
state_id INTEGER PRIMARY KEY AUTOINCREMENT,
name VARCHAR(255) NOT NULL);

CREATE TABLE deadline (
deadline_id INTEGER PRIMARY KEY AUTOINCREMENT,
course_id INTEGER NOT NULL, 
task_id INTEGER NOT NULL, 
date DATE NOT NULL,
priority INTEGER, 
state_id INTEGER NOT NULL, 
note TEXT NOT NULL,
is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
FOREIGN KEY(course_id) REFERENCES course(course_id),
FOREIGN KEY(state_id) REFERENCES state(state_id),
FOREIGN KEY(task_id) REFERENCES task(task_id));


INSERT INTO state (name)
VALUES 
('new'), 
('in progress'), 
('done'), 
('cancelled');

INSERT INTO task (name)
VALUES 
('programming task'), 
('test'), 
('project'), 
('exam'),
('presentation'),
('task');

INSERT INTO course (code, name, hours, ects, semester, credit_form) 
VALUES
(NULL, 'Occupational Safety and Health (OSH) (there is a possibility of using credits received within the last five years at selected UW faculties)', 4, 0.5, 1, 'credit'),
(NULL, 'Intellectual Property Protection', 6, 0.5, 1, 'credit'),
(NULL, 'General elective course (OGUN) humanistic profile - general classes', 30, 3, 2, 'credit'),
('2400-DS1AMI', 'Applied Microeconomics - lecture', 45, 5, 1, 'exam'),
('2400-DS1AMA', 'Applied Macroeconomics - lecture', 30, 5, 1, 'exam'),
('2400-DS1AMA', 'Applied Macroeconomics - lab', 15, 5, 1, 'exam'),
('2400-DS1AE', 'Advanced Econometrics - lecture', 30, 6, 2, 'exam'),
('2400-DS1AE', 'Advanced Econometrics - lab', 30, 6, 2, 'exam'),
('2400-DS2AF', 'Applied Finance - lecture', 30, 5, 3, 'exam'),
('2400-DS2AF', 'Applied Finance - lab', 15, 5, 3, 'exam'),
('2400-DS1R', 'R: intro / data cleaning and imputation R / basics of visualisation - lab', 30, 3, 1, 'exam'),
('2400-DS1SQL', 'Python and SQL: intro / SQL platforms - lab', 30, 4, 1, 'credit'),
('2400-DS1AL', 'Algorithms for Data Science - lecture', 30, 6, 2, 'exam'),
(NULL, 'Algorithms for Data Science - lab', 15, 6, 2, 'exam'),
('2400-DS1ST', 'Statistics and Exploratory Data Analysis - lab', 30, 5, 1, 'credit'),
('2400-DS1IDS', 'Introduction to Data Science - lecture', 15, 3, 1, 'exam'),
('2400-DS1UL', 'Unsupervised Learning - lab', 30, 3, 1, 'credit');
('2400-DS1WSMS', 'Webscraping and Social Media Scraping - lab', 15, 3, 2, 'credit'),
('2400-DS1APR', 'Advanced Programming in R - lab', 30, 5, 2, 'exam'),
('2400-DS1ML1', 'Machine Learning 1: classification methods - lab', 30, 4, 2, 'credit'),
('2400-DS2AV', 'Advanced Visualisation in R - lab', 30, 6, 3, 'credit'),
('2400-DS2TMS', 'Text Mining and Social Media Mining - lab', 30, 4, 3, 'exam'),
('2400-DS2BDA', 'Big Data Analytics - lab', 15, 2, 3, 'credit'),
('2400-DS2ML2', 'Machine Learning 2: predictive models, deep learning, neuron network - lab', 30, 4, 3, 'credit'),
('2400-DS2RR', 'Reproducible Research - lab', 30, 4, 4, 'exam'),
('2400-DS2WWEF', 'Elective course (economics or finance) - discussion in lab', 30, 3, 4, 'credit'),
('2400-DS2WWIT', 'Elective course (IT tools) - lab', 30, 3, 4, 'credit'),
('2400-DS2WWQM', 'Elective course (quantitative methods) - discussion in lab', 60, 6, 4, 'credit'),
('2400-DS1CA', 'Communication and Autopresentation - discussion', 30, 2, 1, 'credit'),
('2400-DS2NEG', 'Negotiations - discussion', 30, 3, 3, 'exam'),
('2400-DS2UB', 'Understanding Business - lecture', 30, 3, 4, 'credit'),
('2400-SU2TS….', 'Master Thesis Seminar - seminar', 30, 3, 2, 'credit');
