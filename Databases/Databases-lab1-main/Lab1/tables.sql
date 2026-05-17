--- Creating Schema ---

-- Students Table --
CREATE TABLE Students (
    idnr CHAR(10) NOT NULL,
    name VARCHAR(255) NOT NULL,
    login VARCHAR(255) NOT NULL,
    program VARCHAR(255) NOT NULL,
    PRIMARY KEY (idnr)
);

-- Branches Table --
CREATE TABLE Branches (
    name VARCHAR(255) NOT NULL,
    program VARCHAR(255) NOT NULL,
    PRIMARY KEY (name, program)
);

-- Courses Table --
CREATE TABLE Courses (
    code CHAR(6) NOT NULL,
    name VARCHAR(255) NOT NULL,
    credits INT NOT NULL,
    department VARCHAR(255) NOT NULL,
    PRIMARY KEY (code),
    CHECK (LENGTH(code) = 6),
    CHECK (credits >= 0)
);

-- LimitedCourses Table --
CREATE TABLE LimitedCourses (
    code VARCHAR(255) NOT NULL,
    capacity INT NOT NULL,
    PRIMARY KEY (code),
    FOREIGN KEY (code) REFERENCES Courses(code),
    CHECK (capacity >= 0)
);

-- StudentBranches Table --
CREATE TABLE StudentBranches (
    student CHAR(10) NOT NULL,
    branch VARCHAR(255) NOT NULL,
    program VARCHAR(255) NOT NULL,
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
    PRIMARY KEY (student)
);

-- Classifications Table --
CREATE TABLE Classifications (
    name VARCHAR(255) NOT NULL,
    PRIMARY KEY (name)
);

-- Classified Table --
CREATE TABLE Classified (
    course VARCHAR(255) NOT NULL,
    classification VARCHAR(255) NOT NULL,
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (classification) REFERENCES Classifications(name),
    PRIMARY KEY (course, classification)
);

-- MandatoryProgram Table --
CREATE TABLE MandatoryProgram (
    course VARCHAR(255) NOT NULL,
    program VARCHAR(255) NOT NULL,
    FOREIGN KEY (course) REFERENCES Courses(code),
    PRIMARY KEY (course, program)
);

-- MandatoryBranch Table --
CREATE TABLE MandatoryBranch (
    course VARCHAR(255) NOT NULL,
    branch VARCHAR(255) NOT NULL,
    program VARCHAR(255) NOT NULL,
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
    PRIMARY KEY (course, branch, program)
);

-- RecommendedBranch Table --
CREATE TABLE RecommendedBranch (
    course VARCHAR(255) NOT NULL,
    branch VARCHAR(255) NOT NULL,
    program VARCHAR(255) NOT NULL,
    FOREIGN KEY (course) REFERENCES Courses(code),
    FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
    PRIMARY KEY (course, branch, program)
);

-- Registered Table --
CREATE TABLE Registered (
    student CHAR(10) NOT NULL,
    course VARCHAR(255) NOT NULL,
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code),
    PRIMARY KEY (student, course)
);

-- Taken Table --¨
CREATE TYPE grade_type AS ENUM ('U', '3', '4', '5');
CREATE TABLE Taken (
    student CHAR(10) NOT NULL,
    course VARCHAR(255) NOT NULL,
    grade grade_type NOT NULL,
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES Courses(code),
    PRIMARY KEY (student, course)
);

-- WaitingList Table --
CREATE TABLE WaitingList (
    student CHAR(10) NOT NULL,
    course VARCHAR(255) NOT NULL,
    position SERIAL,
    PRIMARY KEY (student, course),
    FOREIGN KEY (student) REFERENCES Students(idnr),
    FOREIGN KEY (course) REFERENCES LimitedCourses(code)
);
