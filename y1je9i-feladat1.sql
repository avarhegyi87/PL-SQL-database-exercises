/*
The following procedure adds a city to the 'cities' table.
It accepts 3 parameters:
- new_city_name:    the name of the city (text)
- assigned_country: the name of the country it is located in
- bool_capital:     optional. 1 if it is a capital city, otherwise, can be ommitted

The procedure checks the following criteria:
- If other than 0 or 1 was input in the bool_capital parameter, the program will not run.
    --> Solution: write 0 (or omit the parameter) if the city is not a capital, otherwise, write 1.
- If no country is found with the provided 'assigned_country' parameter, the program will not run.
    --> Solution: add the country first to the country table, then retry adding the city with this program.
- If a city already exists with the provided name, the program will not run.
    --> Solution: if the current record is invalid, update it, otherwise no action needed.
- If you're trying to add a capital to a country that already has a capital registered in the countries table,
    the program will not run.
    --> Solution: add the city as a non-capital, or if it is the new capital in the country, 
        update the current one as non-capital then rerun this procedure.
*/

CREATE OR REPLACE PROCEDURE insert_city (new_city_name VARCHAR2, 
                                         assigned_country VARCHAR2, 
                                         bool_capital NUMBER DEFAULT 0) AS
    Invalid_Bool        EXCEPTION;
    Invalid_Country     EXCEPTION;
    City_Exists         EXCEPTION;
    Capital_Exists      EXCEPTION;
    hits                NUMBER;
    ctry_code           countries.country_code%TYPE;
    new_id              cities.city_id%TYPE;
BEGIN
    IF bool_capital <> 0 AND bool_capital <> 1 THEN
        RAISE Invalid_Bool;
    END IF;
    
    SELECT COUNT(*)
        INTO hits
        FROM countries
        WHERE UPPER(country_name) = UPPER(assigned_country);
    IF hits = 0 THEN
        RAISE Invalid_Country;
    END IF;
    
    SELECT COUNT(*) INTO hits FROM cities
        WHERE UPPER(city_name) = UPPER(new_city_name);
    IF hits > 0 THEN
        RAISE City_Exists;
    END IF;
    
    SELECT country_code INTO ctry_code FROM countries
        WHERE UPPER(country_name) = UPPER(assigned_country);
    
    SELECT MAX(city_id)+1 INTO new_id FROM cities;
    
    IF bool_capital = 1 THEN
        hits := 0;
        SELECT COUNT(*) INTO hits FROM cities
        WHERE UPPER(country_code) = UPPER(ctry_code)
        AND is_capital = 1;
        IF hits > 0 THEN
            RAISE Capital_Exists;
        END IF;
    END IF;
    
    INSERT INTO cities (city_id, city_name, country_code, is_capital)
        VALUES(new_id, INITCAP(new_city_name), UPPER(ctry_code), bool_capital);
        
    SELECT COUNT(*) INTO hits FROM cities WHERE UPPER(country_code) = UPPER(ctry_code);
    dbms_output.put_line('Record successfully entered as the ' || 
                         hits || '. city from ' || INITCAP(assigned_country));
    
EXCEPTION
    WHEN Invalid_Bool
        THEN dbms_output.put_line('The bool_capital parameter can only be ' || 
                                  '0 (not capital) or 1 (capital)');
    WHEN Invalid_Country
        THEN dbms_output.put_line('Country ' || assigned_country ||
                                  ' does not exist in the database.');
    WHEN City_Exists
        THEN dbms_output.put_line(new_city_name || ' is already in the table');
    WHEN Capital_Exists
        THEN dbms_output.put_line(assigned_country || ' already has a capital, ' || 
                                  'add ' || new_city_name || ' as non-capital, ' ||
                                  'or unassign the current capital then retry.');
END insert_city;
/

-- Should not insert as the 3rd parameter can be 0 or 1
EXEC insert_city('Lajosmizse', 'Hungary', 2);
-- Should not insert as Hungary already has a capital
EXEC insert_city('Lajosmizse', 'Hungary', 1);
-- Should not insert as Budapest already exists in the table
EXEC insert_city('Budapest', 'Hungary', 1);
-- Should not insert as Cayman Islands does not exist in the countries table
EXEC insert_city('Lajosmizse', 'Cayman Islands', 0);
-- Should be added as the 2nd city from Poland
EXEC insert_city('Rzeszow', 'Poland', 0);