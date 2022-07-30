/*
1) The program creates a new view, called 'LEADERS_PER_COUNTRY',
    listing all the countries from the 'COUNTRIES' table and the full name of its leader.
    The country code is also included, because it is not an auto-incremented number,
    but a two-character-long string, strongly connected to the country, 
    it cannot be auto-generated when simply providing the name of the new country to add.

2) The 'NEWCOUNTRY' trigger fires when the user tries to insert a new country and a leader
    in the 'LEADERS_PER_COUNTRY' view. As that is not possible, 
    it instead inserts the new country in the 'COUNTRIES' table, provided that:
    - The country does not exist in the 'COUNTRIES' table yet.
    - The provided leader exists in the 'LEADERS' table.
    - The provided leader is not already in power of another country.

3) The 'MOD_LEADER_NAME' trigger fires when the user tries to update the 'LEADERS_PER_COUNTRY' view.
    As that is not possible, the trigger instead updates the 'LEADERS' table, provided that:
    - A leader with the same name does not yet exist within the 'LEADERS' table.
*/

CREATE OR REPLACE VIEW leaders_per_country AS
    SELECT country_code, country_name, first_name, last_name
    FROM countries LEFT JOIN leaders USING(leader_id);

CREATE OR REPLACE TRIGGER newcountry
    INSTEAD OF INSERT ON leaders_per_country
DECLARE
    hits                NUMBER;
    lid                 leaders.leader_id%TYPE;
    Country_Exists      EXCEPTION;
    Leader_Not_Exists   EXCEPTION;
    Leader_In_Power     EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO hits FROM countries 
        WHERE UPPER(country_name) = UPPER(:new.country_name);
    IF hits > 0 THEN
        RAISE Country_Exists;
    END IF;
    
    SELECT COUNT(*) INTO hits FROM leaders
        WHERE UPPER(:new.first_name || ' ' || :new.last_name) = 
            UPPER(first_name || ' ' || last_name);
    IF hits = 0 THEN
        RAISE Leader_Not_Exists;
    END IF;
    
    SELECT leader_id INTO lid FROM leaders
        WHERE UPPER(first_name || ' ' || last_name) = 
        UPPER(:new.first_name || ' ' || :new.last_name);
    
    SELECT COUNT(*) INTO hits FROM countries
        WHERE leader_id = lid;
    IF hits > 0 THEN
        RAISE Leader_In_Power;
    END IF;
    
    INSERT INTO countries(country_code, country_name, leader_id)
        VALUES(:new.country_code, :new.country_name, lid);
        
EXCEPTION
    WHEN Country_Exists
        THEN dbms_output.put_line(INITCAP(:new.country_name) || 
            ' is already in the database, cannot add it again.');
    WHEN Leader_Not_Exists
        THEN dbms_output.put_line('Leader ' || :new.first_name || ' ' ||
            :new.last_name || ' is not in the database yet, cannot add the country. ' || 
            'Add the leader first, then retry adding the country.');
    WHEN Leader_In_Power
        THEN dbms_output.put_line(INITCAP(:new.first_name) || ' ' || 
            INITCAP(:new.last_name) || ' already leads another country');
END;
/

CREATE OR REPLACE TRIGGER mod_leader_name
    INSTEAD OF UPDATE ON leaders_per_country
    FOR EACH ROW
DECLARE
    hits            NUMBER;
    lid             leaders.leader_id%TYPE;
    Leader_Exists   EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO hits FROM leaders
        WHERE UPPER(first_name || ' ' || last_name) = 
        UPPER(:new.first_name || ' ' || :new.last_name);
    IF hits > 0 THEN
        RAISE Leader_Exists;
    END IF;
    
    SELECT leader_id INTO lid FROM leaders
        WHERE UPPER(first_name || ' ' || last_name) = 
        UPPER(:old.first_name || ' ' || :old.last_name);
        
    UPDATE leaders SET
        first_name = INITCAP(:new.first_name),
        last_name = INITCAP(:new.last_name)
    WHERE leader_id = lid;
    
EXCEPTION
    WHEN Leader_Exists
        THEN dbms_output.put_line(INITCAP(:new.first_name) || ' ' || 
            INITCAP(:new.last_name) || 
            ' is already in the leaders list, cannot add it again.');
END;
/

-- should not add it, because this country is already in the database
INSERT INTO leaders_per_country VALUES('HU', 'Hungary', 'Viktor', 'Orban');
-- should not add it, because this leader is not in 'LEADERS' yet
INSERT INTO leaders_per_country VALUES('RO', 'Romania', 'Klaus', 'Iohannis');
-- should not add it, because this leader leads another country
INSERT INTO leaders_per_country VALUES('RO', 'Romania', 'Viktor', 'Orban');
-- should add it, this leader is created, and doesn't lead a country yet
INSERT INTO leaders_per_country VALUES('BR', 'Brazil', 'Jair', 'Bolsonaro');
-- for deleting the newly added row
DELETE FROM countries WHERE country_code = 'BR';

-- should not update, there is already another leader with the new name
UPDATE leaders_per_country SET
    first_name = 'Mateusz', last_name = 'Morawiecki'
    WHERE first_name = 'Viktor' AND last_name = 'Orban';
COMMIT;
-- should update without any problem
UPDATE leaders_per_country SET
    first_name = 'Peter', last_name = 'Marki-Zay'
    WHERE first_name = 'Viktor' AND last_name = 'Orban';
COMMIT;
-- should update without any problem after the previous update
UPDATE leaders_per_country SET
    first_name = 'Viktor', last_name = 'Orban'
    WHERE first_name = 'Peter' AND last_name = 'Marki-Zay';
COMMIT;