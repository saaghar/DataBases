import json
import psycopg2


class PortalConnection:
    def __init__(self):
        self.conn = psycopg2.connect(
            host="localhost",
            user="postgres",
            password="123456",
            dbname="postgres")
        self.conn.autocommit = True

 

# tar studenID som indata och returnerar jsonFil som innehåller info om studenter från PathToGraduation
# Get information
    def getInfo(self, student):
        with self.conn.cursor() as cur:
            sql = """
                SELECT jsonb_build_object(
                    'student', bi.idnr,
                    'name', bi.name,
                    'login', bi.login,
                    'program', bi.program,
                    'branch', bi.branch,
                    'finished', (
                        SELECT jsonb_agg(jsonb_build_object(
                            'course', fc.courseName,
                            'code', fc.course,
                            'credits', fc.credits,
                            'grade', fc.grade
                        )) FROM FinishedCourses AS fc WHERE fc.student = bi.idnr
                    ),
                    'registered', (
                        SELECT jsonb_agg(jsonb_build_object(
                            'course', r.course,
                            'code', r.course,
                            'status', r.status
                        )) FROM Registrations AS r WHERE r.student = bi.idnr
                    ),
                    'seminarCourses', pg.seminarcourses,
                    'mathCredits', pg.mathcredits,
                    'totalCredits', pg.totalcredits,
                    'canGraduate', pg.qualified
                ) AS info
                FROM BasicInformation bi
                LEFT JOIN PathToGraduation pg ON bi.idnr = pg.student
                WHERE bi.idnr = %s;
            """
            cur.execute(sql, (student,))
            result = cur.fetchone()
            if result:
                info = result[0]
            else:
                info = {
                    "student": student,
                    "name": None,
                    "login": None,
                    "program": None,
                    "branch": None,
                    "finished": [],
                    "registered": [],
                    "seminarCourses": 0,
                    "mathCredits": 0.0,
                    "totalCredits": 0.0,
                    "canGraduate": False
                }

        return json.dumps(info) # Return the dictionary directly



    # Task1: Register
    # Register a student on a course
    def register(self, student, courseCode):
        try:
            with self.conn.cursor() as cursor:
                sql = "INSERT INTO Registrations(student, course) VALUES (%s, %s);"
                cursor.execute(sql, (student, courseCode))
                return json.dumps({"success": True})
        except psycopg2.Error as e:
            return json.dumps({"success": False, "error": self.getError(e)})



    # Task2: Unregister
    # Unregister a student on a course
    def unregister(self, student, courseCode):
        try:
            with self.conn.cursor() as cursor:

                sql_injection = f"DELETE FROM Registrations WHERE student = '{student}' AND course = '{courseCode}';"
                cursor.execute(sql_injection)

                # Removed for the sql injection
                # sql = "DELETE FROM Registrations where student = %s and course = %s"
                # cursor.execute(sql, (student, courseCode))
                
                # Check if rows were deleted
                if cursor.rowcount == 0:
                    return json.dumps({"success": False, "error": "Student not registered or in waiting list, or course/student does not exist."})
                return json.dumps({"success": True})
        except Exception as e:
            return json.dumps({"success": False, "error": self.getError(e)})
 


# Error message
    def getError(self, e):
        message = str(e).replace("\n", " ").replace("\"", "\\\"")
        return json.dumps(message)


