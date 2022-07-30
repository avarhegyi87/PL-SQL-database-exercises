/*
This function returns the population of the capital of a country (provided by the user)
Inputs:
- country: the name of the country
Returns:
- the population of its capital as a number
Exceptions:
- Returns -1 if the country does not exist in the database.
- Returns -2 if two countries exist with the same name.
- Returns -3 if the country exists in the database but its capital does not.
- Returns -4 if the country exists in the datbase and has more than 1 capital.
*/

CREATE OR REPLACE FUNCTION get_capital_population (country VARCHAR2) RETURN NUMBER AS
    ctry_id             countries.country_code%TYPE;
    hits                NUMBER;
    population          NUMBER;
    Capital_Not_Found   EXCEPTION;
    Multiple_Capitals   EXCEPTION;
BEGIN
    SELECT country_code INTO ctry_id FROM countries 
        WHERE UPPER(country_name) = UPPER(country);
    
    SELECT COUNT(*) INTO hits FROM cities 
        WHERE UPPER(country_code) = UPPER(ctry_id)
        AND cities.is_capital = 1;
    
    IF hits = 0 THEN
        RAISE Capital_Not_Found;
    ELSIF hits > 1 THEN
        RAISE Multiple_Capitals;
    ELSE
        SELECT city_population INTO population FROM cities
            WHERE UPPER(country_code) = UPPER(ctry_id)
            AND cities.is_capital = 1;
        RETURN population;
    END IF;
    
EXCEPTION
    WHEN No_Data_Found
        THEN RETURN -1;
    WHEN Too_Many_Rows
        THEN RETURN -2;
    WHEN Capital_Not_Found
        THEN RETURN -3;
    WHEN Multiple_Capitals
        THEN RETURN -4;
END get_capital_population;
/

BEGIN
    -- No such country, should return -1
    dbms_output.put_line('Population of the capital of Tatooine: ' || get_capital_population('Tatooine'));
    -- Two such countries exist: (Mainland China [People's Republic of Chine] and Taiwan [Republic of China]), the function should return -2
    dbms_output.put_line('Population of the capital of China: ' || get_capital_population('China'));      
    -- No capital registered in the database, the function should return -3
    dbms_output.put_line('Population of the capital of Egypt: ' || get_capital_population('Egypt'));
    -- The Republic of South Africa has 3 capitals (really!), the function should return -4
    dbms_output.put_line('Population of the capital of South Africa: ' || get_capital_population('South Africa'));
    -- The function should return the population of Budapest without error
    dbms_output.put_line('Population of the capital of Hungary: ' || get_capital_population('Hungary'));
END;