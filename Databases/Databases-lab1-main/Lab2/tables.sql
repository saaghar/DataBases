CREATE TABLE Departments ( 
    name TEXT NOT NULL PRIMARY KEY, 
    abbreviation TEXT NOT NULL UNIQUE 
);

CREATE TABLE Programs (
	name TEXT NOT NULL PRIMARY KEY,
	abbreviation TEXT NOT NULL 
);

CREATE TABLE Branches (
	name TEXT NOT NULL,
	program TEXT NOT NULL,
	PRIMARY KEY (name, program),
	FOREIGN KEY (program) REFERENCES Programs(name)
);

CREATE TABLE Students (
	idnr CHAR(10) NOT NULL PRIMARY KEY,
	name TEXT NOT NULL,
	login TEXT NOT NULL UNIQUE,
	program TEXT NOT NULL,
	UNIQUE (idnr, program),
	FOREIGN KEY (program) REFERENCES Programs(name) 
);

CREATE TABLE Courses (
    code CHAR(6) NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    credits INT NOT NULL,
    departmentName TEXT NOT NULL,
    FOREIGN KEY (departmentName) REFERENCES Departments(name),
    CHECK (LENGTH(code) = 6),
    CHECK (credits >= 0)
);

CREATE TABLE LimitedCourses (
    courseCode CHAR(6) NOT NULL PRIMARY KEY,
    capacity INT CHECK(capacity > 0)
    FOREIGN KEY (courseCode) REFERENCES Courses(code)
);

CREATE TABLE StudentBranches (
    student CHAR(10) NOT NULL PRIMARY KEY,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    FOREIGN KEY (program, program) REFERENCES Students(idnr, program),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE Classifications (
    name TEXT NOT NULL PRIMARY KEY
);

CREATE TABLE Classified (
    course CHAR(6) NOT NULL,
    classification TEXT NOT NULL,
    PRIMARY KEY (course, classification),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (classification) REFERENCES Classifications(name)
);

CREATE TABLE Prerequisites (
	targetcourse CHAR(6) NOT NULL,
	requiredcourse CHAR(6) NOT NULL,
	PRIMARY KEY (targetcourse, requiredcourse),
	FOREIGN KEY (targetcourse) REFERENCES Courses(code),
	FOREIGN KEY (requiredcourse) REFERENCES Courses(code)
);

CREATE TABLE MandatoryProgram (
    course CHAR(6) NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (course, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (program) REFERENCES Programs(name)
);

CREATE TABLE MandatoryBranch (
    course CHAR(6) NOT NULL,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE RecommendedBranch (
    course CHAR(6) NOT NULL,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    PRIMARY KEY (course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE Registered (
    student CHAR(10) NOT NULL,
    course CHAR(6) NOT NULL,
    PRIMARY KEY (student, course),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code)
);

CREATE TABLE Taken (
    student CHAR(10) NOT NULL,
    course CHAR(6) NOT NULL,
    grade TEXT NOT NULL,
    PRIMARY KEY (student, course),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code)
);


CREATE TABLE WaitingList(
    student TEXT,
    course TEXT,
    position INT NOT NULL,
    PRIMARY KEY(student, course),
    UNIQUE(position, course),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES LimitedCourses(code)
);    

