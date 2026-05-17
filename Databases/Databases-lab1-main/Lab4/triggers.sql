
-- Trigger 1 for student registration --
CREATE OR REPLACE FUNCTION reg_student()
RETURNS TRIGGER AS $$
DECLARE
    missingPrerequisite TEXT;
    newPosition INT;
    currentPosition INT;
BEGIN
    -- Check if the course and student exist
    IF NOT EXISTS (SELECT 1 FROM Students WHERE idnr = NEW.student) THEN
        RAISE EXCEPTION 'Student % not found.', NEW.student;
    ELSIF NOT EXISTS (SELECT 1 FROM Courses WHERE code = NEW.course) THEN
        RAISE EXCEPTION 'Course % not found.', NEW.course;
    ELSIF EXISTS (SELECT 1 FROM Registered WHERE student = NEW.student AND course = NEW.course) THEN
        RAISE EXCEPTION 'Student % is already registered to course %.', NEW.student, NEW.course;
    END IF;

    -- Check if the student is already on the waiting list
    SELECT position INTO currentPosition FROM WaitingList WHERE student = NEW.student AND course = NEW.course;
    IF currentPosition IS NOT NULL THEN
        RAISE EXCEPTION 'Student % is already on the waiting list for course % with a position %.', NEW.student, NEW.course, currentPosition;
    END IF;
    
    -- Check if the student has already passed the course
    IF EXISTS (SELECT FROM Taken WHERE student = NEW.student AND course = NEW.course AND Taken.grade != 'U') THEN
        RAISE EXCEPTION 'Student % has already taken and passed course %.', NEW.student, NEW.course;
    END IF;

    -- Identify missing prerequisites for the course
    SELECT string_agg(pr.requiredcourse, ', ') INTO missingPrerequisite
    FROM Prerequisites pr
    WHERE pr.targetcourse = NEW.course
    AND NOT EXISTS (
        SELECT FROM Taken 
        WHERE Taken.student = NEW.student AND Taken.course = pr.requiredcourse AND Taken.grade != 'U'
    );

    IF missingPrerequisite IS NOT NULL THEN
        RAISE EXCEPTION 'Student % has not passed the prerequisite courses: %.', NEW.student, missingPrerequisite;
    END IF;
    
    -- Check if there's room in the course
    IF (SELECT COUNT(*) FROM Registered WHERE course = NEW.course) >= 
       (SELECT capacity FROM LimitedCourses WHERE code = NEW.course) THEN
        SELECT COALESCE(MAX(position), 0) + 1 INTO newPosition FROM WaitingList WHERE course = NEW.course;
        INSERT INTO WaitingList (student, course, position) VALUES (
            NEW.student, NEW.course, newPosition
        );
        RAISE NOTICE 'Student % is added to the waiting list for course % at position % due to course fully booked.', NEW.student, NEW.course, newPosition;
    ELSE
        INSERT INTO Registered (student, course) VALUES (NEW.student, NEW.course);
        RAISE NOTICE 'Student % is successfully registered to course %.', NEW.student, NEW.course;
    END IF;

    RETURN NEW; --Return NEW not NULL
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER registration_attempt
INSTEAD OF INSERT ON Registrations
FOR EACH ROW
EXECUTE FUNCTION reg_student();


-- Trigger 2 for student unregistration --
CREATE OR REPLACE FUNCTION unreg_studen() 
RETURNS TRIGGER AS $$
DECLARE
    nextStudent RECORD;
    courseCapacity INT;
    registeredCount INT;
    removedPosition INT;
    isRegistered BOOLEAN;
    isWaiting BOOLEAN;
BEGIN
    -- Check if the student is in the Registered table
    SELECT EXISTS(SELECT 1 FROM Registered WHERE student = OLD.student AND course = OLD.course) INTO isRegistered;
    IF isRegistered THEN
        DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
        RAISE NOTICE 'Student % has been successfully unregistered from course %.', OLD.student, OLD.course;
    END IF;

    -- Check if the student is on the WaitingList
    SELECT EXISTS(SELECT 1 FROM WaitingList WHERE student = OLD.student AND course = OLD.course) INTO isWaiting;
    IF isWaiting THEN
        SELECT position INTO removedPosition FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
        DELETE FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
        RAISE NOTICE 'Student % has been successfully removed from the waiting list for course % at position %.', OLD.student, OLD.course, removedPosition;
    END IF;

    -- Check if there's now room in the course due to the unregistration
    SELECT capacity INTO courseCapacity FROM LimitedCourses WHERE code = OLD.course;
    SELECT COUNT(*) INTO registeredCount FROM Registered WHERE course = OLD.course;

    -- If there's room now, move the next eligible student from the waiting list to registered
    IF registeredCount < courseCapacity THEN
        SELECT * INTO nextStudent FROM WaitingList 
        WHERE course = OLD.course
        ORDER BY position ASC
        LIMIT 1;

        IF FOUND THEN
            DELETE FROM WaitingList WHERE student = nextStudent.student AND course = OLD.course;
            INSERT INTO Registered (student, course) VALUES (nextStudent.student, OLD.course);
            UPDATE WaitingList SET position = position - 1
            WHERE course = OLD.course AND position > nextStudent.position;
        END IF;
    END IF;

    IF removedPosition IS NOT NULL THEN
        UPDATE WaitingList SET position = position - 1
        WHERE course = OLD.course AND position > removedPosition;
    END IF;

    RETURN OLD; -- We are retunring OLD not NULL after feedback   
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER unregistration_attempt
INSTEAD OF DELETE ON Registrations
FOR EACH ROW
EXECUTE FUNCTION unreg_studen();


