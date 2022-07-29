-- Creating tables for PH-EmployeeDB
CREATE TABLE departments (
     dept_no VARCHAR(4) NOT NULL,
     dept_name VARCHAR(40) NOT NULL,
     PRIMARY KEY (dept_no),
     UNIQUE (dept_name)
);

CREATE TABLE employees (
	     emp_no INT NOT NULL,
     birth_date DATE NOT NULL,
     first_name VARCHAR NOT NULL,
     last_name VARCHAR NOT NULL,
     gender VARCHAR NOT NULL,
     hire_date DATE NOT NULL,
     PRIMARY KEY (emp_no)
);

CREATE TABLE dept_manager (
dept_no VARCHAR(4) NOT NULL,
    emp_no INT NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
FOREIGN KEY (emp_no) REFERENCES employees (emp_no),
FOREIGN KEY (dept_no) REFERENCES departments (dept_no),
    PRIMARY KEY (emp_no, dept_no)
);

CREATE TABLE salaries (
  emp_no INT NOT NULL,
  salary INT NOT NULL,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  FOREIGN KEY (emp_no) REFERENCES employees (emp_no),
  PRIMARY KEY (emp_no)
);

CREATE TABLE dept_emp (
dept_no VARCHAR(4) NOT NULL,
    emp_no INT NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
FOREIGN KEY (emp_no) REFERENCES employees (emp_no),
FOREIGN KEY (dept_no) REFERENCES departments (dept_no),
    PRIMARY KEY (emp_no, dept_no)
);

CREATE TABLE titles (
	     emp_no INT NOT NULL,
     title VARCHAR NOT NULL,
     from_date DATE NOT NULL,
    to_date DATE NOT NULL,
     PRIMARY KEY (emp_no),
FOREIGN KEY (emp_no) REFERENCES employees (emp_no)
);
SELECT * FROM titles;

-- RETIREMENT ELIGIBILITY
SELECT first_name, last_name
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31') 
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- NUMBER OF EMPLOYEES RETIRING 
SELECT COUNT(first_name)
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31') 
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- TELL POSTGRES TO SAVE DATA INTO TABLE NAMED "RETIREMENT_INFO"
SELECT first_name, last_name
INTO retirement_info
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31') 
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- confirm table created and see what looks like 
SELECT * FROM retirement_info;

-- drop retirement_info table to recreate table including emp_no
DROP TABLE retirement_info;

-- recreate table to include emp_no & unique identifier column 
-- create new table for retiring employees
SELECT emp_no, first_name, last_name
INTO retirement_info
FROM employees
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31') 
AND (hire_date BETWEEN '1985-01-01' AND '1988-12-31');

-- Check the table 
SELECT * FROM retirement_info;

-- Joining departments and dept_manager tables
SELECT departments.dept_name,
     dept_manager.emp_no,
     dept_manager.from_date,
     dept_manager.to_date
FROM departments
INNER JOIN dept_manager
ON departments.dept_no = dept_manager.dept_no;

-- update table names using alias statements 
SELECT d.dept_name,
	dm.emp_no,
	dm.from_date,
	dm.to_date
FROM departments as d
INNER JOIN dept_manager as dm
ON d.dept_no = dm.dept_no;

-- Joining retirement_info and dept_emp tables 
-- LEFT JOIN used to include every row of the first table(retirement_info)
-- also tells postgres which table is second or on the right side (dept_emp)
-- ON clause tells postgres where the two tables are linked 
SELECT retirement_info.emp_no,
	retirement_info.first_name,
	retirement_info.last_name,
	dept_emp.to_date
FROM retirement_info
LEFT JOIN dept_emp
ON retirement_info.emp_no = dept_emp.emp_no;

-- update table names using alias statements
SELECT ri.emp_no,
	ri.first_name,
	ri.last_name,
	de.to_date
FROM retirement_info as ri 
LEFT JOIN dept_emp as de
ON ri.emp_no = de.emp_no;

-- create new table 'current_emp' with list of retirement eligible employees 
-- that are still employed with PH 
-- join retirement_info and dept_emp tables 
SELECT ri.emp_no,
	ri.first_name,
	ri.last_name,
	de.to_date
INTO current_emp
FROM retirement_info as ri 
LEFT JOIN dept_emp as de 
ON ri.emp_no = de.emp_no
WHERE de.to_date = ('9999-01-01');

-- check current_emp table 
SELECT * FROM current_emp;

-- count current employees by department number 
-- only needed columns 'emp_no' and 'dept_no'
-- group by is magic clause that gives number of employees 
-- retiring from each department
-- ORDER BY puts data in order of dept number, instead of random output that would  
-- occur without using ORDER BY 
SELECT COUNT(ce.emp_no), de.dept_no
FROM current_emp as ce 
LEFT JOIN dept_emp as de 
ON ce.emp_no = de.emp_no
GROUP BY de.dept_no
ORDER BY de.dept_no;

-- update code block to create new table and export as csv 
SELECT COUNT(ce.emp_no), de.dept_no
INTO dept_breakdown
FROM current_emp as ce 
LEFT JOIN dept_emp as de 
ON ce.emp_no = de.emp_no
GROUP BY de.dept_no
ORDER BY de.dept_no;

SELECT * FROM dept_breakdown;

-- create employee information list 
-- contain unique emp_no, last_name, first_name, gender, salary

SELECT * FROM salaries
ORDER BY to_date DESC;


-- add 3rd Join to create new table for emp info list 
SELECT e.emp_no, 
	e.first_name, 
	e.last_name, 
	e.gender,
	s.salary,
	de.to_date
INTO emp_info
FROM employees as e
INNER JOIN salaries as s
ON (e.emp_no = s.emp_no)
INNER JOIN dept_emp as de 
ON (e.emp_no = de.emp_no)
WHERE (e.birth_date BETWEEN '1952-01-01' AND '1955-12-31')
AND (e.hire_date BETWEEN '1985-01-01' AND '1988-12-31')
AND (de.to_date = '9999-01-01');



-- create management list 
-- contain dept_name, dept_no, name, manager emp_no, last_name 
-- first_name, hire_date, end employment date

SELECT dm.dept_no,
	d.dept_name,
	dm.emp_no,
	ce.last_name,
	ce.first_name,
	dm.from_date,
	dm.to_date
INTO manager_info
FROM dept_manager AS dm
	INNER JOIN departments AS d
		ON (dm.dept_no = d.dept_no)
	INNER JOIN current_emp AS ce
		ON (dm.emp_no = ce.emp_no);
		
-- create dept retirees list(an updated current_emp list)
-- contain everything in current_emp list plus emp depts

SELECT ce.emp_no,
	ce.first_name,
	ce.last_name,
	d.dept_name
INTO dept_info
FROM current_emp AS ce 
	INNER JOIN dept_emp as de 
		ON (ce.emp_no = de.emp_no)
	INNER JOIN departments as d 
		ON (de.dept_no = d.dept_no);
		
-- create sales team list 
-- contain emp_no, first_name,last_name,emp_dept_name
SELECT ri.emp_no,
	ri.first_name,
	ri.last_name,
	de.dept_no,
	d.dept_name
-- INTO sales_info
FROM retirement_info AS ri
	INNER JOIN dept_emp AS de 
		ON (ri.emp_no = de.emp_no)
	INNER JOIN departments AS d
		ON (de.dept_no = d.dept_no)
WHERE (d.dept_name = 'Sales') 
	  AND (de.to_date = '9999-01-01');
	  
-- Create sales and development team list 
SELECT ri.emp_no,
	ri.first_name,
	ri.last_name,
	de.dept_no,
	d.dept_name
-- INTO sales_development_info
FROM retirement_info AS ri
	INNER JOIN dept_emp AS de 
		ON (ri.emp_no = de.emp_no)
	INNER JOIN departments AS d
		ON (de.dept_no = d.dept_no)
WHERE (d.dept_name IN ('Sales', 'Development')) 
	  AND (de.to_date = '9999-01-01');