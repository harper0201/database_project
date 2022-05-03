-- q1
create sequence log_record_id
    increment by 1
    start with 1000 nomaxvalue nocache nocycle;

create or replace trigger drop_class_trigger
    after delete on G_Enrollments
    for each row
declare
    log# Logs.log#%type;
    user_name Logs.user_name%type;
    table_name Logs.table_name%type default 'G_Enrollments';
    operation Logs.operation%type default 'delete';
    tuple_keyvalue Logs.tuple_keyvalue%type;
begin
    log# := log_record_id.nextval;
    select user into user_name from dual;
    tuple_keyvalue := :old.G_B#||','||:old.classid;
    insert into logs values(log#,user_name,sysdate,table_name,operation,tuple_keyvalue);
    update classes set
        class_size = class_size - 1 where
            classid = : old.classid;
end;

create or replace trigger delete_student_trigger
    before delete on Students
    for each row
declare
    log# Logs.log#%type;
    user_name Logs.user_name%type;
    table_name Logs.table_name%type default 'Students';
    operation Logs.operation%type default 'delete';
    tuple_keyvalue Logs.tuple_keyvalue%type;
begin
    log# := log_record_id.nextval;
    select user into user_name from dual;
    tuple_keyvalue := :old.B#;
    insert into logs values(log#,user_name,sysdate,table_name,operation,tuple_keyvalue);
    delete from G_Enrollments where G_B# = :old.B#;
end;

create or replace trigger enroll_class_trigger
    after insert on G_Enrollments
    for each row
declare
    log# Logs.log#%type;
    user_name Logs.user_name%type;
    table_name Logs.table_name%type default 'G_Enrollments';
    operation Logs.operation%type default 'insert';
    tuple_keyvalue Logs.tuple_keyvalue%type;
begin
    log# := log_record_id.nextval;
    select user into user_name from dual;
    tuple_keyvalue := :new.G_B#||','||:new.classid;
    insert into logs values(log#,user_name,sysdate,table_name,operation,tuple_keyvalue);
    update classes set
        class_size = class_size + 1 where
            classid = : new.classid;
end;