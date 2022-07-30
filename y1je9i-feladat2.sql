/*
This procedure takes a language as an argument, and it lists:
- The total number of the countries in the database where the given language is an official language, 
    with the total population of those countries.
- Lists those countries and their population separately (the program supposes that the full population speaks that language).

The program can throw the following errors if:
- The language provided by the user does not exist in the database.
- The language provided by the user exists in the database but is not used as an official language in any of the countries. 
*/

CREATE OR REPLACE PROCEDURE get_countries_by_lang (lang_full languages.language_name%TYPE) AS
    lang_id         languages.language_id%TYPE;
    ctry_id         official_lang.country_code%TYPE;
    ctry_name       countries.country_name%TYPE;
    ctry_pop        countries.country_population%TYPE;
    hits            NUMBER;
    total_pop       NUMBER;
    lang_notfound   EXCEPTION;
    ctry_notfound   EXCEPTION;
    /*First cursor to get the 2 char long language codes*/
    CURSOR cur_ctrylang IS
        SELECT DISTINCT country_code FROM official_lang
        WHERE language_id = (
            SELECT languages.language_id FROM languages 
            WHERE UPPER(language_name) = UPPER(lang_full));
    /*Second cursor to get the countries for each 1st cursor*/
    CURSOR cur_ctry IS
        SELECT country_name, country_population FROM countries
        WHERE UPPER(country_code) = UPPER(ctry_id);
BEGIN
    SELECT COUNT(languages.language_id) INTO hits FROM languages
        WHERE UPPER(language_name) = UPPER(lang_full);
    IF hits = 0 THEN
        RAISE lang_notfound;
    END IF;
    SELECT COUNT(countries.country_code), SUM(countries.country_population) 
        INTO hits, total_pop
        FROM official_lang 
        LEFT JOIN countries ON official_lang.country_code = countries.country_code
        INNER JOIN languages ON official_lang.language_id = languages.language_id
        WHERE UPPER(language_name) = UPPER(lang_full);
    IF hits = 0 THEN
        RAISE ctry_notfound;
    END IF;
    dbms_output.put_line(INITCAP(lang_full) || ' is an official langauge ' ||
                        'in ' || hits || ' countries by ' ||
                        total_pop || ' people.');
    
    -- Open first cursor for language codes
    OPEN cur_ctrylang;
    LOOP
        FETCH cur_ctrylang INTO ctry_id;
        EXIT WHEN cur_ctrylang%NOTFOUND;
        -- Open second cursor for countries
        OPEN cur_ctry;
        LOOP
            FETCH cur_ctry INTO ctry_name, ctry_pop;
            EXIT WHEN cur_ctry%NOTFOUND;
            dbms_output.put_line('Counry: ' || RPAD(ctry_name, 30) ||
                                'Population: ' || LPAD(ctry_pop, 12));
        END LOOP;
        CLOSE cur_ctry;
    END LOOP;
    CLOSE cur_ctrylang;
    
EXCEPTION
    WHEN lang_notfound
        THEN dbms_output.put_line('No ' || INITCAP(lang_full) || ' language in the database.');
    WHEN ctry_notfound
        THEN dbms_output.put_line(INITCAP(lang_full) || ' is not spoken in ' ||
                                'any of the countries in the database.');
    
END get_countries_by_lang;
/

-- Should not give a result, there is no such language in the database
EXEC get_countries_by_lang('Elven');
-- Should not give a result, this language is not an official language in any country on the database
EXEC get_countries_by_lang('Basque');
-- Should give back the a valid result
EXEC get_countries_by_lang('German');