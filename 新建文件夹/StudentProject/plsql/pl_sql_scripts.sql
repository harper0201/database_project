create or replace package MY_PROJECT is

    type ref_cursor is ref cursor;

    procedure show_students;
    procedure show_courses;
    procedure show_course_credit;
    procedure show_classes;
    procedure show_enrollments;
    procedure show_score_grade;
    procedure show_prerequisites;
    procedure show_logs;
    procedure list_students(cid IN CLASSES.CLASSID%type);
    procedure check_pre_course(deptcode Prerequisites.dept_code%type,course Prerequisites.course#%type);
    procedure enroll_class(input_B# Students.B#%type,input_classid G_Enrollments.classid%type);
    procedure drop_class(input_B# Students.B#%type,input_classid G_Enrollments.classid%type);
    procedure delete_student(input_B# Students.B#%type);
end MY_PROJECT;

create or replace package body MY_PROJECT is
    procedure show_students is
    begin
        for c in ( select B#, first_name, last_name, st_level, gpa, email, bdate from STUDENTS)
            loop
                dbms_output.put_line('B#: '|| c.B# || ' First Name: ' || c.first_name || ' Last Name: ' || c.LAST_NAME
                    || ' ST Level: ' || c.ST_LEVEL || ' GPA: ' || c.gpa || ' email: ' || c.EMAIL
                    || 'Birthdate: ' || c.bdate);
            end loop;
    end show_students;

    -- Courses(dept_code, course#, title)
    procedure show_courses is
    begin
        for c in (select * from COURSES) loop
                dbms_output.put_line('Dept Code: ' || c.DEPT_CODE || ' Course#: ' || c.COURSE# || ' Title: ' || c.title);
            end loop;
    end show_courses;
    -- Course_credit(course#, credits)
    procedure show_course_credit is
    begin
        for c in (select * from COURSE_CREDIT) loop
            dbms_output.put_line('Course#: ' || c.COURSE# || ' Credits: ' || c.CREDITS);
        end loop;
    end show_course_credit;
    -- Classes(classid, dept_code, course#, sect#, year, semester, limit, class_size, room)
    procedure show_classes is
    begin
        for c in (select * from CLASSES) loop
            dbms_output.put_line('ID: ' || c.CLASSID || ' Dept Code: ' || c.DEPT_CODE || ' Course#: ' || c.COURSE#
                                     || 'Sect#: ' || c.SECT# || ' Year: ' || c.YEAR || ' Semester: ' || c.SEMESTER
                                     || 'Limit: ' || c.LIMIT || ' Class Size: ' || c.CLASS_SIZE || ' Room: ' || c.ROOM);
        end loop;
    end show_classes;
    -- G_Enrollments(G_B#, classid, score)
    procedure show_enrollments is
    begin
        for c in (select * from G_ENROLLMENTS) loop
            dbms_output.put_line('G_B#: ' || c.G_B# || ' Class ID: ' || c.CLASSID || ' Score: ' || c.SCORE);
            end loop;
    end show_enrollments;

    -- Score_Grade(score, lgrade)
    procedure show_score_grade is
    begin
        for c in (select * from SCORE_GRADE) loop
            dbms_output.put_line('Score: ' || c.SCORE || ' lgrade: ' || c.LGRADE);
            end loop;
    end show_score_grade;
    -- Prerequisites(dept_code, course#, pre_dept_code, pre_course#)
    procedure show_prerequisites is
    begin
        for c in (select * from PREREQUISITES) loop
            dbms_output.put_line('Dept Code: ' || c.DEPT_CODE || ' Course#: ' || c.COURSE# || ' PreDeptCode: ' || c.PRE_DEPT_CODE
                                     || ' pre_course#: ' || c.PRE_COURSE#);
            end loop;
    end show_prerequisites;
    -- Logs(log#, user_name, op_time, table_name, operation, tuple_keyvalue)
    procedure show_logs is
    begin
        for c in (select * from LOGS) loop
            dbms_output.put_line('Log#: ' || c.LOG# || ' username: ' || c.USER_NAME || ' op_time: ' || c.OP_TIME
                                     || ' table_name: ' || c.TABLE_NAME || 'operation: ' || c.OPERATION || ' tuple_keyvalue: ' || c.TUPLE_KEYVALUE);
            end loop;
    end show_logs;

    -- for q3
    procedure list_students(cid IN CLASSES.CLASSID%type) is
        v_count NUMBER(1);
    begin
        select count(1) into v_count from CLASSES where CLASSID=cid;
        if v_count >= 1 THEN
            for c in (select * from G_ENROLLMENTS LEFT JOIN STUDENTS S on G_ENROLLMENTS.G_B# = S.B# where G_ENROLLMENTS.CLASSID = CID) loop
                    dbms_output.put_line('B#: ' || c.B# || ' First Name: ' || c.FIRST_NAME || ' Last Name: ' || c.LAST_NAME);
                end loop;
        ELSE
            DBMS_OUTPUT.put_line('The classid is invalid.');
        end if;
    end list_students;

    procedure enroll_class(input_B# Students.B#%type,input_classid G_Enrollments.classid%type) AS
        status boolean;
        first_check boolean;
        B#_check number;
        G_check number;
        classid_check number;
        classtime_check number;
        classfull_check number;
        student_check number;
        maxclass_check number;
        pre_count number;
        pre_dept_code Prerequisites.pre_dept_code%type;
        pre_course# Prerequisites.pre_course#%type;
        valified_count number;
        Cursor pre
            IS
            select distinct p.pre_dept_code,p.pre_course# into pre_dept_code,pre_course#
            from G_Enrollments g, Prerequisites p,Classes c
            where g.classid = input_classid and g.classid = c.classid and p.dept_code = c.dept_code and p.course# = c.course#;
        dept_code Classes.dept_code%type;
        course# Classes.course#%type;
        lgrade Score_Grade.lgrade%type;
        Cursor gra
            IS
            select c.dept_code,c.course#,sg.lgrade into dept_code,course#,lgrade
            from G_Enrollments g, Classes c, Score_grade sg
            where g.classid = c.classid and g.score = sg.score and g.G_B# = input_B# and sg.lgrade in('A','A+','A-','B','B+','B-','C','C+');

    begin
        select count(*) into B#_check from Students where B# = input_B#;
        select count(*) into G_check from G_Enrollments where G_B# = input_B#;

        if B#_check = 0 then
            first_check := false;
            dbms_output.put_line('The B# is invalid.');
        elsif G_check = 0 then
            first_check := false;
            dbms_output.put_line('This is not a graduate students');
        else
            first_check := true;
        end if;

        select count(*) into classid_check from Classes where classid = input_classid;
        select count(*) into classtime_check from Classes where classid = input_classid and year = '2021' and semester = 'Spring';
        select count(*) into classfull_check from Classes where classid = input_classid and class_size = limit;
        select count(*) into student_check from G_Enrollments where classid = input_classid and G_B# = input_B#;
        select count(*) into maxclass_check from G_Enrollments e,Classes c where e.classid = c.classid and year = '2021' and semester = 'Spring' and e.G_B# = input_B#;

        if classid_check = 0 then
            first_check := false;
            dbms_output.put_line('This classid is invalid');
        elsif classtime_check = 0 then
            first_check := false;
            dbms_output.put_line('Cannot enroll into a class from a previous semester.');
        elsif classfull_check !=0 then
            first_check := false;
            dbms_output.put_line('The class is already full.');
        elsif student_check != 0 then
            first_check := false;
            dbms_output.put_line('The student is already in class');
        elsif maxclass_check = 5 then
            first_check := false;
            dbms_output.put_line('Students cannot be enrolled in more than five classes in the same semester.');
        else
            first_check := true;
        end if;

        pre_count := 0;
        for p in pre
            LOOP
                pre_count := pre_count + 1;
            END LOOP;

        if pre_count = 0 then
            status := true;
        else
            status := false;
            valified_count := 0;

        end if;

        for p in pre
            LOOP
                for g in gra
                    LOOP
                        if p.pre_dept_code = g.dept_code and p.pre_course# = g.course# then
                            valified_count := valified_count + 1;
                        end if;
                    END LOOP;
            END LOOP;

        if pre_count = valified_count then
            status := true;
        else
            status := false;
        end if;

        if status = false and first_check = true then
            dbms_output.put_line('the prerequisites are not satisfied.');
        end if;

        if status = true and first_check = true then
            insert into G_Enrollments values(input_B#,input_classid,null);
            dbms_output.put_line('insert successfully.');
        end if;

    end enroll_class;

    procedure drop_class(input_B# Students.B#%type,input_classid G_Enrollments.classid%type) AS
        status boolean;
        B#_check number;
        G_check number;
        classid_check number;
        classtime_check number;
        student_check number;
        maxclass_check number;
    begin
        select count(*) into B#_check from Students where B# = input_B#;
        select count(*) into G_check from G_Enrollments where G_B# = input_B#;

        if B#_check = 0 then
            status := false;
            dbms_output.put_line('The B# is invalid.');
        elsif G_check = 0 then
            status := false;
            dbms_output.put_line('This is not a graduate students');
        else
            status := true;
        end if;

        select count(*) into classid_check from Classes where classid = input_classid;
        select count(*) into classtime_check from Classes where classid = input_classid and year = '2021' and semester = 'Spring';
        select count(*) into student_check from G_Enrollments where classid = input_classid and G_B# = input_B#;
        select count(*) into maxclass_check from G_Enrollments e,Classes c where e.classid = c.classid and year = '2021' and semester = 'Spring' and e.G_B# = input_B#;

        if classid_check = 0 then
            status := false;
            dbms_output.put_line('invalid classid');
        elsif classtime_check = 0 then
            status := false;
            dbms_output.put_line('Only enrollment in the current semester can be dropped.');
        elsif student_check = 0 then
            status := false;
            dbms_output.put_line('The student is not enrolled in class');
        elsif maxclass_check = 1 then
            status := false;
            dbms_output.put_line('This is the only class for this student in Spring 2021 and cannot be dropped');
        else
            status := true;
        end if;

        if status = true then
            delete from G_Enrollments where G_B# = input_B# and classid = input_classid;
            dbms_output.put_line('drop successfully.');
        end if;
    end drop_class;

    procedure delete_student(input_B# Students.B#%type) AS
        B#_check number;
    begin
        select count(*) into B#_check from Students where B# = input_B#;

        if B#_check = 0 then
            dbms_output.put_line('The B# is invalid.');
        else
            delete from Students where B# = input_B#;
            dbms_output.put_line('delete successfully.');
        end if;
    end delete_student;

    procedure check_pre_course(deptcode Prerequisites.dept_code%type,course Prerequisites.course#%type) AS
        type c_list  is varray(100) of varchar2(30);
        ans_list c_list := c_list();
        counter integer := 0;
    begin
        for e in (select * from Prerequisites where dept_code = deptcode and course# = course)
            LOOP
                counter := counter + 1;
                ans_list.extend;
                ans_list(counter) := e.pre_dept_code||e.pre_course#;
                dbms_output.put_line(e.pre_dept_code||''||e.pre_course#);
                for f in (select * from prerequisites where dept_code = e.pre_dept_code and course# = e.pre_course#)
                    LOOP
                        counter := counter + 1;
                        ans_list.extend;
                        ans_list(counter) := f.pre_dept_code||f.pre_course#;
                        dbms_output.put_line(f.pre_dept_code||''||f.pre_course#);
                    END LOOP;
            END LOOP;
        if (ans_list.count = 0) then
            dbms_output.put_line('dept_code||course# does not exist');
        end if;
    end check_pre_course;
end MY_PROJECT;
