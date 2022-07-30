/*
This trigger logs any modification done on the 'countries' table, let it be insertion, updating or deletion.
The following details are logged:
- The date of the modification.
- The user who committed the modification.
- The country code of the modified record.
- The details of the modificatoin: type (insertion, updating, deletion) and the values affected.
*/

-- Create the logging table
CREATE TABLE log_countries (
    mod_date        DATE,
    username        VARCHAR2(100),
    modified_key    VARCHAR2(2),
    information     VARCHAR2(150)
);

CREATE OR REPLACE TRIGGER mod_countries
BEFORE INSERT OR UPDATE OR DELETE on countries
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    vTransaction    VARCHAR(10);
    vKey            countries.country_code%TYPE;
    vInfo           log_countries.information%TYPE;
BEGIN
    CASE
        WHEN UPDATING THEN
            vKey := :new.country_code;
            vInfo := 'MÓDOSÍTVA: ' || :new.country_code || ' ' ||
                    :old.country_name  ||' -> ' || :new.country_name || '; ' ||
                    :old.country_population  ||' -> ' || :new.country_population || '; ' ||
                    :old.form_of_gov  ||' -> ' || :new.form_of_gov || '; ' ||
                    :old.leader_id  ||' -> ' || :new.leader_id || '; ' ||
                    :old.continent_id  ||' -> ' || :new.continent_id;
        WHEN DELETING THEN
            vInfo := 'TÖRÖLVE: ' || :old.country_code || ' ' || :old.country_name;
            vKey := :old.country_code;
        WHEN INSERTING THEN
            vInfo := 'BESZÚRVA: ' || :new.country_code || ' ' || :new.country_name || ', ' ||
                    :new.country_population || ', ' || :new.form_of_gov || ', ' ||
                    :new.leader_id || ', ' || :new.continent_id;
            vKey := :new.country_code;
    END CASE;
    
    INSERT INTO log_countries VALUES(sysdate, user, vKey, vInfo);
    COMMIT;
END mod_countries;
/

UPDATE countries SET country_population = '826' WHERE country_code = 'VA';
UPDATE countries SET country_population = '825' WHERE country_code = 'VA';
INSERT INTO countries (country_code, country_name, country_population, form_of_gov, leader_id, continent_id) 
    VALUES ('CA', 'Canada', '38526000', 'constitutional_monarchy', '6', '2');
UPDATE countries SET country_population = '38526760' WHERE country_code = 'CA';
DELETE FROM countries WHERE country_code = 'CA';

