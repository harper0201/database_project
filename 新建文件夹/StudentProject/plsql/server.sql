create or replace package MY_SERVER is
    type ref_cursor is ref cursor;
    function show_students_ref return ref_cursor;
    function show_courses_ref return ref_cursor;
    function show_course_credit_ref return ref_cursor;
    function show_classes_ref return ref_cursor;
    function show_enrollments_ref return ref_cursor;
    function show_score_grade_ref return ref_cursor;
    function show_prerequisites_ref return ref_cursor;
    function show_logs_ref return ref_cursor;

    function enroll_class_func(input_B# Students.B#%type,input_classid G_Enrollments.classid%type) return varchar2;
    function drop_class_func(input_B# Students.B#%type,input_classid G_Enrollments.classid%type) return varchar2;
    function delete_student_func(input_B# Students.B#%type) return varchar2;
    function check_class_func(id G_ENROLLMENTS.classid%type) return ref_cursor;
end MY_SERVER;

create or replace package body MY_SERVER is

    function show_students_ref return ref_cursor is
        rc ref_cursor;
    begin
        open rc for select * from STUDENTS;
        return rc;
    end;
    function show_courses_ref return ref_cursor is
        rc ref_cursor;
    begin
        open rc for select * from COURSES;
        return rc;
    end;
    function show_course_credit_ref return ref_cursor is
        rc ref_cursor;
    begin
        open rc for select * from COURSE_CREDIT;
        return rc;
    end;
    function show_classes_ref return ref_cursor is
        rc ref_cursor;
    begin
        open rc for select * from CLASSES;
        return rc;
    end;
    function show_enrollments_ref return ref_cursor is
        rc ref_cursor;
    begin
        open rc for select * from G_ENROLLMENTS;
        return rc;
    end;
    function show_score_grade_ref return ref_cursor is
        rc ref_cursor;
    begin
        open rc for select * from SCORE_GRADE;
        return rc;
    end;
    function show_prerequisites_ref return ref_cursor is
        rc ref_cursor;
    begin
        open rc for select * from PREREQUISITES;
        return rc;
    end;
    function show_logs_ref return ref_cursor is
        rc ref_cursor;
    begin
        open rc for select * from LOGS;
        return rc;
    end;

    function enroll_class_func(input_B# Students.B#%type,input_classid G_Enrollments.classid%type) return varchar2 IS
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
        result varchar2(200);
    begin
        select count(*) into B#_check from Students where B# = input_B#;
        select count(*) into G_check from G_Enrollments where G_B# = input_B#;

        if B#_check = 0 then
            first_check := false;
            result := 'The B# is invalid.';
            return result;
        elsif G_check = 0 then
            first_check := false;
            result := 'This is not a graduate students';
            return result;
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
            result := 'This classid is invalid';
            return result;
        elsif classtime_check = 0 then
            first_check := false;
            result := 'Cannot enroll into a class from a previous semester.';
            return result;
        elsif classfull_check !=0 then
            first_check := false;
            result := 'The class is already full.';
            return result;
        elsif student_check != 0 then
            first_check := false;
            result := 'The student is already in class';
            return result;
        elsif maxclass_check = 5 then
            first_check := false;
            result := 'Students cannot be enrolled in more than five classes in the same semester.';
            return result;
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
            result := 'The prerequisites are not satisfied.';
            return result;
        end if;

        if status = true and first_check = true then
            insert into G_Enrollments values(input_B#,input_classid,null);
            result := 'SUCCESS';
            return result;
        end if;

    end enroll_class_func;


    function delete_student_func(input_B# Students.B#%type) return varchar2 AS
        B#_check number;
        result varchar2(200);
    begin
        select count(*) into B#_check from Students where B# = input_B#;

        if B#_check = 0 then
            result := 'The B# is invalid.';
            return result;
        else
            delete from Students where B# = input_B#;
            result := 'SUCCESS';
            return result;
        end if;
    end;

    function drop_class_func(input_B# Students.B#%type,input_classid G_Enrollments.classid%type) return varchar2 AS
        status boolean;
        B#_check number;
        G_check number;
        classid_check number;
        classtime_check number;
        student_check number;
        maxclass_check number;
        result varchar2(200);
    begin
        select count(*) into B#_check from Students where B# = input_B#;
        select count(*) into G_check from G_Enrollments where G_B# = input_B#;

        if B#_check = 0 then
            status := false;
            result :='The B# is invalid.';
            return result;
        elsif G_check = 0 then
            status := false;
            result :='This is not a graduate students';
            return result;
        else
            status := true;
        end if;

        select count(*) into classid_check from Classes where classid = input_classid;
        select count(*) into classtime_check from Classes where classid = input_classid and year = '2021' and semester = 'Spring';
        select count(*) into student_check from G_Enrollments where classid = input_classid and G_B# = input_B#;
        select count(*) into maxclass_check from G_Enrollments e,Classes c where e.classid = c.classid and year = '2021' and semester = 'Spring' and e.G_B# = input_B#;

        if classid_check = 0 then
            status := false;
            result :='invalid classid';
            return result;
        elsif classtime_check = 0 then
            status := false;
            result :='Only enrollment in the current semester can be dropped.';
            return result;
        elsif student_check = 0 then
            status := false;
            result :='The student is not enrolled in class';
            return result;
        elsif maxclass_check = 1 then
            status := false;
            result :='This is the only class for this student in Spring 2021 and cannot be dropped';
            return result;
        else
            status := true;
        end if;

        if status = true then
            delete from G_Enrollments where G_B# = input_B# and classid = input_classid;
            result :='SUCCESS';
            return result;
        end if;
    end drop_class_func;

    function check_class_func(id G_ENROLLMENTS.classid%type) return ref_cursor is
        rc ref_cursor;
    begin
        open rc for
            select s.B#,s.first_name,s.last_name
            from G_ENROLLMENTS e, Students s where
                e.CLASSID = id and s.B# = e.G_B#;
        return rc;
    end;
end MY_SERVER;
