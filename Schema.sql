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

insert into course_temp (code, name, hours, ects, semester, credit_form)
select code, name, hours, ects, semester, credit_form 
from course;
select * from course;
ALTER TABLE course_temp RENAME TO course;