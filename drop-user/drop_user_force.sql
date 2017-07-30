SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER OSERROR CONTINUE;
WHENEVER SQLERROR CONTINUE;

-- Oracle drop user can fail if there are active current connections to the schema 
-- This script will destroy all existing connections to the schema, then drop the user
DECLARE
    v_cnt    INTEGER := 0;
    v_schema VARCHAR2(50);
    v_sid    NUMBER;
    v_serial NUMBER;
BEGIN
    select upper('&1') into v_schema from dual;
    select count(*) into v_cnt from dba_users where username = v_schema;
    IF v_cnt > 0 THEN
        for i in (select * from v$session s where username = v_schema)
        loop
            v_sid := i.sid;
            v_serial := i.serial#;
            -- 'kill session' asks the sessions to kill themselves,
            -- Sometimes session cannot kill themselves, so 'disconnect session' has Oracle force a disconnect.
            -- https://oracle-base.com/articles/misc/killing-oracle-sessions
            dbms_output.put_line('Removing session ''' || v_sid || ',' || v_serial || '''.');
            BEGIN
                EXECUTE IMMEDIATE ('ALTER SYSTEM KILL SESSION ''' || v_sid || ',' || v_serial || ''' IMMEDIATE');
            EXCEPTION
                WHEN OTHERS
                THEN dbms_output.put_line('Error kill session ' || v_sid || ',' || v_serial || ' : ' || SQLERRM);
            END;
            BEGIN
                EXECUTE IMMEDIATE ('ALTER SYSTEM DISCONNECT SESSION ''' || v_sid || ',' || v_serial || ''' IMMEDIATE');
            EXCEPTION
                WHEN OTHERS
                THEN dbms_output.put_line('Error disconnect session ' || v_sid || ',' || v_serial || ' : ' || SQLERRM);
            END;
        end loop;
        dbms_output.put_line('Dropping user ' || v_schema || '...');
        EXECUTE IMMEDIATE ('drop user ' || v_schema || ' cascade');
        dbms_output.put_line('Done.');
    ELSE
        dbms_output.put_line('The schema ' || v_schema || ' does not exist.');
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        dbms_output.put_line(SQLERRM);
END;
/
exit;
