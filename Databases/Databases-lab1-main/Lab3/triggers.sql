
-- Trigger 1 for student registration --
CREATE OR REPLACE FUNCTION reg_student()
RETURNS TRIGGER AS $$
DECLARE
    missing_prerequisite TEXT;
    new_position INT;
    current_position INT;
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
    SELECT position INTO current_position FROM WaitingList WHERE student = NEW.student AND course = NEW.course;
    IF current_position IS NOT NULL THEN
        RAISE EXCEPTION 'Student % is already on the waiting list for course % with a position %.', NEW.student, NEW.course, current_position;
    END IF;
    
    -- Check if the student has already passed the course
    IF EXISTS (SELECT FROM Taken WHERE student = NEW.student AND course = NEW.course AND Taken.grade != 'U') THEN
        RAISE EXCEPTION 'Student % has already taken and passed course %.', NEW.student, NEW.course;
    END IF;

    -- Identify missing prerequisites for the course
    SELECT string_agg(pr.requiredcourse, ', ') INTO missing_prerequisite
    FROM Prerequisites pr
    WHERE pr.targetcourse = NEW.course
    AND NOT EXISTS (
        SELECT FROM Taken 
        WHERE Taken.student = NEW.student AND Taken.course = pr.requiredcourse AND Taken.grade != 'U'
    );

    IF missing_prerequisite IS NOT NULL THEN
        RAISE EXCEPTION 'Student % has not passed the prerequisite courses: %.', NEW.student, missing_prerequisite;
    END IF;
    
    -- Check if there's room in the course
    IF (SELECT COUNT(*) FROM Registered WHERE course = NEW.course) >= 
       (SELECT capacity FROM LimitedCourses WHERE code = NEW.course) THEN
        SELECT COALESCE(MAX(position), 0) + 1 INTO new_position FROM WaitingList WHERE course = NEW.course;
        INSERT INTO WaitingList (student, course, position) VALUES (
            NEW.student, NEW.course, new_position
        );
        RAISE NOTICE 'Student % is added to the waiting list for course % at position % due to course fully booked.', NEW.student, NEW.course, new_position;
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
    next_student RECORD;
    course_capacity INT;
    registered_count INT;
    removed_position INT;
    is_registered BOOLEAN;
    is_waiting BOOLEAN;
BEGIN
    -- Check if the student is in the Registered table
    SELECT EXISTS(SELECT 1 FROM Registered WHERE student = OLD.student AND course = OLD.course) INTO is_registered;
    IF is_registered THEN
        DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
        RAISE NOTICE 'Student % has been successfully unregistered from course %.', OLD.student, OLD.course;
    END IF;

    -- Check if the student is on the WaitingList
    SELECT EXISTS(SELECT 1 FROM WaitingList WHERE student = OLD.student AND course = OLD.course) INTO is_waiting;
    IF is_waiting THEN
        SELECT position INTO removed_position FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
        DELETE FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
        RAISE NOTICE 'Student % has been successfully removed from the waiting list for course % at position %.', OLD.student, OLD.course, removed_position;
    END IF;

    -- Check if there's now room in the course due to the unregistration
    SELECT capacity INTO course_capacity FROM LimitedCourses WHERE code = OLD.course;
    SELECT COUNT(*) INTO registered_count FROM Registered WHERE course = OLD.course;

    -- If there's room now, move the next eligible student from the waiting list to registered
    IF registered_count < course_capacity THEN
        SELECT * INTO next_student FROM WaitingList 
        WHERE course = OLD.course
        ORDER BY position ASC
        LIMIT 1;

        IF FOUND THEN
            DELETE FROM WaitingList WHERE student = next_student.student AND course = OLD.course;
            INSERT INTO Registered (student, course) VALUES (next_student.student, OLD.course);
            UPDATE WaitingList SET position = position - 1
            WHERE course = OLD.course AND position > next_student.position;
        END IF;
    END IF;

    IF removed_position IS NOT NULL THEN
        UPDATE WaitingList SET position = position - 1
        WHERE course = OLD.course AND position > removed_position;
    END IF;

    RETURN OLD; -- We are retunring OLD not NULL after feedback   
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER unregistration_attempt
INSTEAD OF DELETE ON Registrations
FOR EACH ROW
EXECUTE FUNCTION unreg_studen();
