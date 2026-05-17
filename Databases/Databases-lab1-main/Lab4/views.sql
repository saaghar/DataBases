--- Views ---
-- Basic Information --
CREATE VIEW BasicInformation AS
SELECT 
    s.idnr,
    s.name,
    s.login,
    s.program,
    sb.branch
FROM 
    Students s
LEFT JOIN 
    StudentBranches sb ON s.idnr = sb.student;

-- Find Courses --
CREATE VIEW FinishedCourses AS
SELECT 
    t.student,
    t.course,
    c.name AS courseName,
    t.grade,
    c.credits
FROM 
    Taken t
INNER JOIN 
    Courses c ON t.course = c.code;

-- Registration --
CREATE VIEW Registrations AS
  (SELECT r.student, r.course, 'registered' AS status
  FROM Registered AS r
  UNION 
  SELECT w.student, w.course, 'waiting' AS status
  FROM WaitingList AS w
  ORDER BY status, course, student);

-- Hint 1 Passed Courses student, course , credit 
CREATE VIEW PassedCourses AS
SELECT 
	Taken.student, 
	Taken.course, 
	Courses.credits
FROM Taken
JOIN Courses
ON Taken.course = Courses.code
WHERE Taken.grade != 'U';

-- Hint 2 (Students, Courses) Mandatory courses for each student
CREATE VIEW MandatoryCourses AS
SELECT 
    StudentBranches.student,
    MandatoryBranch.course
FROM StudentBranches
JOIN MandatoryBranch 
ON (StudentBranches.branch,StudentBranches.program) = (MandatoryBranch.branch, MandatoryBranch.program)            
UNION
SELECT
    BasicInformation.idnr,
    MandatoryProgram.course
FROM BasicInformation
JOIN MandatoryProgram
ON BasicInformation.program = MandatoryProgram.program;  

-- Remove the courses that students have alredady passed--
CREATE VIEW UnreadMandatory AS
SELECT 
	student, 
	course
FROM MandatoryCourses
WHERE NOT EXISTS 
	(SELECT (student, course) 
	FROM PassedCourses 
	WHERE (MandatoryCourses.student, MandatoryCourses.course) = (PassedCourses.student, PassedCourses.course));

-- Hint 3 Query to list students and their total credits
CREATE VIEW StudentScores AS
WITH 
StudentScores AS
(SELECT BasicInformation.idnr, COALESCE(PassedCourses.credits, 0) AS credits
	FROM BasicInformation
	LEFT JOIN PassedCourses
	ON BasicInformation.idnr = PassedCourses.student)
SELECT 
idnr AS student, 
SUM(credits) AS totalCredits
FROM StudentScores
GROUP BY idnr
ORDER BY idnr;    

-- Hint 4 Query to count the number of unread mandatory courses (mandatoryLeft)
CREATE VIEW StudentCoursesLeft AS
WITH 
StudentCoursesLeft AS
	(SELECT BasicInformation.idnr, UnreadMandatory.course
	FROM BasicInformation
	LEFT JOIN UnreadMandatory
	ON BasicInformation.idnr = UnreadMandatory.student)
SELECT
idnr AS student,
COALESCE(COUNT(course), 0) AS MandatoryLeft
FROM StudentCoursesLeft
GROUP BY idnr
ORDER BY idnr;

-- Hint 5
CREATE VIEW RecommendedCourses AS
SELECT
    sb.student,
    pc.course,
    pc.credits
FROM StudentBranches sb
JOIN RecommendedBranch rb ON sb.branch = rb.branch AND sb.program = rb.program
JOIN PassedCourses pc ON rb.course = pc.course AND sb.student = pc.student;

-- Hint 7
CREATE VIEW PathToGraduation AS
SELECT 
    s.idnr AS student,
    COALESCE(pc.totalCredits, 0) AS totalCredits,
    COALESCE(um.MandatoryLeft, 0) AS mandatoryLeft,
    COALESCE(mc.mathCredits, 0) AS mathCredits,
    COALESCE(sc.seminarCourses, 0) AS seminarCourses,
    COALESCE( 
        NOT EXISTS (
            SELECT 1 
            FROM MandatoryCourses m
            WHERE m.student = s.idnr AND NOT EXISTS (
                SELECT 1
                FROM PassedCourses p
                WHERE p.student = s.idnr AND p.course = m.course
            )
        ) AND recommendedCredits >= 10 AND mc.mathCredits >= 20 AND sc.seminarCourses >= 1, false 
    ) AS qualified
FROM 
    Students s
LEFT JOIN 
    (SELECT student, SUM(credits) AS totalCredits FROM PassedCourses GROUP BY student) pc ON s.idnr = pc.student
LEFT JOIN 
    (SELECT student, COUNT(course) AS MandatoryLeft FROM UnreadMandatory GROUP BY student) um ON s.idnr = um.student
LEFT JOIN 
    (SELECT 
        student, 
        SUM(credits) AS mathCredits
    FROM 
        PassedCourses
    JOIN Classified ON PassedCourses.course = Classified.course
    WHERE 
        Classified.classification = 'math'
    GROUP BY student) mc ON s.idnr = mc.student
LEFT JOIN 
    (SELECT 
        student, 
        COUNT(*) AS seminarCourses
    FROM 
        PassedCourses
    JOIN Classified ON PassedCourses.course = Classified.course
    WHERE 
        Classified.classification = 'seminar'
    GROUP BY student) sc ON s.idnr = sc.student
LEFT JOIN 
    (SELECT 
        pc.student, 
        SUM(pc.credits) AS recommendedCredits
    FROM 
        RecommendedCourses pc
    JOIN RecommendedCourses rc ON pc.course = rc.course
    GROUP BY pc.student) rc ON s.idnr = rc.student;


CREATE VIEW CourseQueuePositions AS
SELECT
	course,
	student,
	row_number() OVER (PARTITION BY course ORDER BY position) AS place
FROM WaitingList;


