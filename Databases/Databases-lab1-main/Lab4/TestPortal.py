import PortalConnection


def pause():
    input("Press Enter to continue...")
    print("")


def test_student_info(student_id):
    print(f"Student Info for {student_id}:")
    print(c.getInfo(student_id))
    pause()


def test_register_student(student_id, course_code):
    print(f"Attempting to register student {student_id} for course {course_code}:")
    response = c.register(student_id, course_code)
    print(response)
    test_student_info(student_id)


def test_unregister_student(student_id, course_code):
    print(f"Attempting to unregister student {student_id} for course {course_code}:")
    response = c.unregister(student_id, course_code)
    print(response)
    test_student_info(student_id)


def test_double_registration(student_id, course_code):
    print(f"Attempting to double register student {student_id} for course {course_code}:")
    print(c.register(student_id, course_code))
    print(c.register(student_id, course_code))  # This should fail and return an error
    pause()


def test_register_without_prerequisites(student_id, course_code):
    print(f"Attempting to register student {student_id} for course {course_code} without prerequisites:")
    print(c.register(student_id, course_code))
    pause()


def test_unregister_from_restricted_course(student_id, course_code):
    print(f"Attempting to unregister and then re-register student {student_id} for a restricted course {course_code}:")
    print(c.unregister(student_id, course_code))
    print(c.register(student_id, course_code))
    pause()


def test_unregister_re_register_same_position(student_id, course_code, queue_position):
    print(f"Attempting to unregister and then re-register student {student_id} for the same course {course_code} to check position:")
    print(c.unregister(student_id, course_code))
    position_after_unregister = c.getInfo(student_id)[queue_position]
    print(c.register(student_id, course_code))
    position_after_register = c.getInfo(student_id)[queue_position]
    assert position_after_unregister == position_after_register, "The positions are not the same"
    pause()


def test_unregister_from_overfull_course(student_id, course_code):
    print(f"Attempting to unregister student {student_id} from an overfull course {course_code}:")
    print(c.unregister(student_id, course_code))
    # we need to check the course status in the database to ensure no one was moved from the queue
    pause()


def test_sql_injection(student_id, injection_string):
    print(f"Attempting SQL injection during unregister for student {student_id} and string {injection_string}")
    print(c.unregister(student_id, injection_string))
    # we would need to check the database directly to see the effect of the SQL injection
    pause()


if __name__ == "__main__":
    c = PortalConnection.PortalConnection()

    student_id = "2222222222"
    unrestricted_course_code = "CCC111"
    restricted_course_code = "CCC222" 
    overfull_course_code = "CCC333"  
    sql_injection_string = "CCC222'; DELETE FROM Registered;--"  # Final example of SQL injection
    sql_injection_string_2 = "CCC222' OR '1'='1';--"  # Example two of SQL injection
    queue_position = 1

    # test_student_info(student_id)
    # test_register_student(student_id, unrestricted_course_code)
    # test_double_registration(student_id, unrestricted_course_code)
    # test_unregister_student(student_id, unrestricted_course_code)
    # test_unregister_student(student_id, unrestricted_course_code)  # This should fail and return an error
    # test_register_without_prerequisites(student_id, restricted_course_code)
    # test_unregister_from_restricted_course(student_id, restricted_course_code)
    # test_unregister_re_register_same_position(student_id, restricted_course_code, queue_position)
    # test_unregister_from_overfull_course(student_id, overfull_course_code)
    test_sql_injection(student_id, sql_injection_string)
