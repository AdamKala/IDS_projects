-- IDS project 2nd chapte
----------------------------
-- Martin Otradovec xotrad00
-- Adam Kala        xkalaa00
----------------------------

-- DROP TABLES

DROP TRIGGER PERFORMED_TESTS_CHECK_QUALIFICATION;
DROP TRIGGER PERFORMED_TESTS_RESULT;
DROP TRIGGER TESTS_LIMITS;
DROP TABLE planes CASCADE CONSTRAINTS;
DROP TABLE engineers CASCADE CONSTRAINTS;
DROP TABLE tests CASCADE CONSTRAINTS;
DROP TABLE models CASCADE CONSTRAINTS;
-- no need to cascade here, no constraints
DROP TABLE performed_tests;
DROP TABLE qualifications;

-- CREATE TABLES

-- "GENERATED BY DEFAULT" vs. "GENERATED ALWAYS"
-- => we use by default to allow imports with ids already generated

-- models, passenger planes & cargo planes
CREATE TABLE models (
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    name VARCHAR(255) NOT NULL,

    -- generalization / specialization
    -- all fields in the same table, using a discriminator to
    -- distinguish between passenger and cargo planes
    -- => - easy to maintain
    --    - easy to query (no need for additional joins),
    --    - not that many fields that the table structure would be unreadable

    -- discriminator
    type VARCHAR(10) CHECK(type IN ('passenger', 'cargo')) NOT NULL,

    -- when cargo plane
    load_capacity INT DEFAULT 0 CHECK(load_capacity >= 0) NOT NULL,
    -- when passenger plane
    passenger_capacity INT DEFAULT 0 CHECK(passenger_capacity >= 0) NOT NULL
);

-- table for planes
CREATE TABLE planes (
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    model_id INT NOT NULL
);

-- table for engineers
CREATE TABLE engineers (
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL
);

-- table for tests
CREATE TABLE tests (
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    -- limits can only be positive
    min_limit INT CHECK(min_limit > 0) NOT NULL,
    max_limit INT CHECK(max_limit > 0) NOT NULL
);

-- table for qualifications
CREATE TABLE qualifications (
    -- ERD correctioon: No need to have an additional ID here, just use composed primary.
    -- id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    engineer_id INT NOT NULL,
    model_id INT NOT NULL,

    PRIMARY KEY(engineer_id, model_id)
);

-- table for performed tests
CREATE TABLE performed_tests (
    -- We keep the primary key a seperate new ID here
    -- => performed tests can be easily identified by a single field
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,

    performed_at DATE DEFAULT CURRENT_TIMESTAMP NOT NULL,

    -- The submitted value for the test.
    value INT NOT NULL,

    -- derived column
    -- fake bool
    -- 1 = true
    -- 0 = false
    result NUMBER(1, 0),

    engineer_id INT,
    test_type_id INT NOT NULL,
    plane_id INT NOT NULL,

    CONSTRAINT performed_tests_foreign_unique unique(engineer_id, test_type_id, plane_id)
);

-- Add foreign key constraints

ALTER TABLE planes ADD CONSTRAINT fk_planes_models_id FOREIGN KEY (model_id) REFERENCES models(id) ON DELETE CASCADE;

ALTER TABLE qualifications ADD CONSTRAINT fk_qualifications_models_id FOREIGN KEY (model_id) REFERENCES models(id) ON DELETE CASCADE;
ALTER TABLE qualifications ADD CONSTRAINT fk_qualifications_engineers_id FOREIGN KEY (engineer_id) REFERENCES engineers(id) ON DELETE CASCADE;

ALTER TABLE performed_tests ADD CONSTRAINT fk_performed_tests_tests_id FOREIGN KEY(test_type_id) REFERENCES tests(id) ON DELETE CASCADE;
-- Keep the performed test when the engineer gets deleted
ALTER TABLE performed_tests ADD CONSTRAINT fk_performed_tests_engineers_id FOREIGN KEY(engineer_id) REFERENCES engineers(id) ON DELETE SET NULL;
ALTER TABLE performed_tests ADD CONSTRAINT fk_performed_tests_planes_id FOREIGN KEY(plane_id) REFERENCES planes(id) ON DELETE CASCADE;

-- Sample data

INSERT INTO models (name, type, passenger_capacity) VALUES ('Boeing 747', 'passenger', 50);
INSERT INTO models (name, type, passenger_capacity) VALUES ('Airbus A320', 'passenger', 60);
INSERT INTO models (name, type, passenger_capacity) VALUES ('Boeing 737', 'passenger', 20);
INSERT INTO models (name, type, load_capacity) VALUES ('Douglas M-2', 'cargo', 20);
INSERT INTO models (name, type, load_capacity) VALUES ('Airbus A330 MRTT', 'cargo', 100);

INSERT INTO planes (model_id) VALUES (1);
INSERT INTO planes (model_id) VALUES (2);
INSERT INTO planes (model_id) VALUES (3);
INSERT INTO planes (model_id) VALUES (4);
INSERT INTO planes (model_id) VALUES (5);

INSERT INTO engineers (first_name, last_name) VALUES ('Adam', 'Kala');
INSERT INTO engineers (first_name, last_name) VALUES ('Martin', 'Otradovec');
INSERT INTO engineers (first_name, last_name) VALUES ('Jan', 'Novotný');
INSERT INTO engineers (first_name, last_name) VALUES ('Karel', 'Kryl');
INSERT INTO engineers (first_name, last_name) VALUES ('Petr', 'Pavel');

INSERT INTO tests (min_limit, max_limit) VALUES (100, 200);
INSERT INTO tests (min_limit, max_limit) VALUES (50, 50);
INSERT INTO tests (min_limit, max_limit) VALUES (1, 2);
INSERT INTO tests (min_limit, max_limit) VALUES (10, 10);
INSERT INTO tests (min_limit, max_limit) VALUES (23, 67);

INSERT INTO qualifications (engineer_id, model_id) VALUES (1, 1);
INSERT INTO qualifications (engineer_id, model_id) VALUES (1, 3);
INSERT INTO qualifications (engineer_id, model_id) VALUES (1, 4);
INSERT INTO qualifications (engineer_id, model_id) VALUES (2, 2);
INSERT INTO qualifications (engineer_id, model_id) VALUES (3, 3);
INSERT INTO qualifications (engineer_id, model_id) VALUES (4, 4);
INSERT INTO qualifications (engineer_id, model_id) VALUES (5, 5);

INSERT INTO performed_tests (performed_at, value, engineer_id, test_type_id, plane_id) VALUES (TO_DATE('2013/10/23 11:11:33', 'yyyy/mm/dd hh24:mi:ss'), 150, 1, 1, 1);
INSERT INTO performed_tests (performed_at, value, engineer_id, test_type_id, plane_id) VALUES (TO_DATE('2005/05/18 05:32:44', 'yyyy/mm/dd hh24:mi:ss'), 50, 2, 2, 2);
INSERT INTO performed_tests (performed_at, value, engineer_id, test_type_id, plane_id) VALUES (TO_DATE('2009/09/11 21:02:02', 'yyyy/mm/dd hh24:mi:ss'), 1, 3, 3, 3);

-- No need to insert performed_at when the test happened right now
INSERT INTO performed_tests (value, engineer_id, test_type_id, plane_id) VALUES (10, 4, 4, 4);
INSERT INTO performed_tests (value, engineer_id, test_type_id, plane_id) VALUES (30, 5, 5, 5);

-- SELECT

-- Requirements:
-- (1) 2 JOIN queries with 2 tables
-- (2) 1 JOIN query with 3 tables
-- (3) 2 queries with GROUP BY & aggregation
-- (4) 1 query that contains EXISTS
-- (5) 1 query with IN
-- (6) 1 query with nested SELECT
-- => a min of 7 queries + comments

-- Query planes and their model names (planes, models). (1)
SELECT models.name, planes.id FROM models
JOIN planes on models.id = planes.model_id;

-- Query the count of planes that were successfully tested for each test. (performed tests, tests, planes). (1, 2, 3)
SELECT tests.id, COUNT(DISTINCT performed_tests.plane_id) FROM performed_tests
JOIN tests ON performed_tests.test_type_id = tests.id
JOIN planes ON performed_tests.plane_id = planes.id
WHERE performed_tests.result = 1
GROUP BY tests.id;

-- Query plane ids that a specific engineer (engineer with id = 1) has performed a test for (engineers, performed tests, planes). (2)
SELECT planes.id FROM planes
INNER JOIN performed_tests ON performed_tests.plane_id = planes.id
INNER JOIN engineers ON engineers.id = performed_tests.engineer_id
WHERE engineers.id = 1;

-- Query model names that can be tested by a certain engineer (engineer with id = 2). (4, 6)
SELECT m.name FROM engineers e, models m
WHERE (
    e.id = 2 AND EXISTS (
        SELECT * FROM qualifications
        WHERE qualifications.engineer_id = e.id AND qualifications.model_id = m.id
    )
);

-- Query average min limit of tests performed on planes of alphabetically first two plane models. (2, 5, 6)

-- Get planes joined with models
SELECT AVG(tests.min_limit) FROM planes
JOIN models ON planes.model_id = models.id
-- Join in performed tests & tests for the limit
JOIN performed_tests ON planes.id = performed_tests.plane_id
JOIN tests ON performed_tests.test_type_id = tests.id
-- Only go with the model names we want
WHERE models.name IN (
    -- Get the first two models
    SELECT models.name FROM models ORDER BY name FETCH NEXT 2 ROWS ONLY
);

-- Query average results for tests. (1, 3)
SELECT tests.id, AVG(performed_tests.result) FROM tests
JOIN performed_tests ON tests.id = performed_tests.test_type_id
GROUP BY tests.id;

-- Part no.4

-- 2 non-trivial (contains conditions, aggregations, joins and/or substatements) triggers with a demonstration
-- 2 non-trivial procedures with a demonstration
--  - 1 cursor, 1 exception handle, 1 variable that points to a row/column (table_name.column_name%TYPE, table_name%ROWTYPE)
-- 1 explicit index to optimize queries with a demonstration + docu (possible EXPLAIN PLAN usage)
-- 1 EXPLAIN PLAN on a query with 2 joins, 1 aggre function with GROUP BY + docu about the plan (index, join type + do an optimization with demonstration)
-- define privileges for another user
-- 1 materialized view for the other user with demonstration
-- 1 query with WITH & CASE + explanation

-- Triggers

-- Trigger#1

-- Check if an engineer has the right qualification to insert a performed test.
CREATE OR REPLACE TRIGGER PERFORMED_TESTS_CHECK_QUALIFICATION
    BEFORE INSERT OR UPDATE
    ON performed_tests
    FOR EACH ROW
DECLARE
    plane_model  models%ROWTYPE;
    engineer    engineers%ROWTYPE;

    is_qualified INT;

    not_qualified EXCEPTION;
    PRAGMA exception_init (not_qualified, -20001);
BEGIN
    -- Find model_id for the plane the performed test is on
    SELECT models.* INTO plane_model FROM planes
    JOIN models ON models.id = planes.model_id
    WHERE planes.id = :NEW.plane_id;

    SELECT engineers.* INTO engineer FROM engineers
    WHERE id = :NEW.engineer_id;

    -- The count of qualified engineers, either 0 or 1.
    SELECT COUNT(*) INTO is_qualified FROM qualifications
    WHERE qualifications.engineer_id = :NEW.engineer_id
    AND qualifications.model_id = plane_model.id;

    -- Check if engineer has required qualification.
    IF (is_qualified = 0) THEN
        dbms_output.put_line('Engineer ' || engineer.first_name || ' ' || engineer.last_name || ' (id: ' || :NEW.engineer_id || ') cannot test plane ' || :NEW.plane_id ||
                             ', not qualified to perform tests on model ' || plane_model.name || ' (id: ' ||
                             plane_model.id || ').');
        RAISE not_qualified;
    END IF;
END;
/

-- From sample data: Engineer Adam Kala with id 1 isn't qualified to review plane with id 2, model Airbus A320 (id 2).
-- => Throws an error.

-- INSERT INTO performed_tests (performed_tests.value, performed_tests.engineer_id, performed_tests.test_type_id, performed_tests.plane_id)
-- VALUES (110, 1, 1, 2);

-- However, he is qualified to review plane id 3, no error is thrown.

INSERT INTO performed_tests (performed_tests.value, performed_tests.engineer_id, performed_tests.test_type_id, performed_tests.plane_id)
VALUES (110, 1, 1, 3);

-- Trigger#2
-- Check whether performed_tests.value is in bounds of the test min/max values. If so, set result to 1, 0 otherwise.
CREATE OR REPLACE TRIGGER PERFORMED_TESTS_RESULT
    BEFORE INSERT OR UPDATE
    ON performed_tests
    FOR EACH ROW
DECLARE
    test tests%ROWTYPE;
BEGIN
    -- Get the test
    SELECT tests.* INTO test FROM tests
    WHERE id = :NEW.test_type_id;

    -- Go inclusive to support min_limit = max_limit
    IF (:NEW.value < test.min_limit OR :NEW.value > test.max_limit) THEN
        :NEW.result := 0;
    ELSE
        :NEW.result := 1;
    END IF;
END;
/

-- Compute result column, value is in bounds for test with id 1 (>100 & <200) => result = 1
INSERT INTO performed_tests (value, engineer_id, test_type_id, plane_id)
VALUES (150, 1, 1, 4);

-- Value is not in bounds for test with id 2 (=50) => result = 0
INSERT INTO performed_tests (value, engineer_id, test_type_id, plane_id)
VALUES (100, 1, 2, 4);

-- Bonus Trigger#3
-- Check if tests.min_limit <= tests.max_limit
CREATE OR REPLACE TRIGGER TESTS_LIMITS
    BEFORE INSERT OR UPDATE
    ON tests
    FOR EACH ROW
DECLARE
    invalid_test_limits EXCEPTION;
    PRAGMA exception_init (invalid_test_limits, -20002);
BEGIN
    IF (:NEW.min_limit > :NEW.max_limit) THEN
        dbms_output.put_line('Test min_limit (' || :NEW.min_limit || ') has to be equal or higher than max_limit (' || :NEW.max_limit || ').');
        RAISE invalid_test_limits;
    END IF;
END;
/

-- min_limit <= max_limit => no error

INSERT INTO tests (min_limit, max_limit)
VALUES (100, 100);

-- min_limit > max_limit => error

-- INSERT INTO tests (min_limit, max_limit)
-- VALUES (200, 10);

-- Procedures

-- Procedure#1
-- Procedure to catch plane models from "models"
CREATE OR REPLACE PROCEDURE fetch_plane_models
IS
    -- Define a cursor to fetch plane models
    CURSOR plane_models IS
        SELECT name, type, load_capacity, passenger_capacity
        FROM models;

    plane_model plane_models%ROWTYPE;
BEGIN
    OPEN plane_models;
    LOOP
        FETCH plane_models INTO plane_model;
        -- Exit the loop if there are no more rows to fetch
        EXIT WHEN plane_models%NOTFOUND;
        -- Display the fetched row in the console
        DBMS_OUTPUT.PUT_LINE('Model: ' || plane_model.name || ', Type: ' || plane_model.type ||
        CASE plane_model.type
            WHEN 'passenger' THEN ', Passenger Capacity: ' || plane_model.passenger_capacity
            ELSE ', Load Capacity: ' || plane_model.load_capacity
        END);
    END LOOP;
    CLOSE plane_models;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Prints out all the plane information to client output.
BEGIN
    fetch_plane_models();
END;

-- Procedure to update load capacity of the plane, based on their ID, type and the new capacity we want to insert
CREATE OR REPLACE PROCEDURE update_plane_model_capacity (
    p_type IN models.type%TYPE,
    p_id IN planes.id%TYPE,
    p_new_capacity IN INT
) IS
    INVALID_PLANE_TYPE EXCEPTION;
    PRAGMA exception_init ( INVALID_PLANE_TYPE, -20001 );
BEGIN
    -- If the type is cargo, we search for "cargo" and then update the capacity
    IF p_type = 'cargo' THEN
        UPDATE models
        SET models.load_capacity = p_new_capacity
        WHERE models.id = (
            SELECT model_id
            FROM planes
            WHERE id = p_id
        ) AND models.type = 'cargo';

    -- Same for the "passenger"
    ELSIF p_type = 'passenger' THEN
        UPDATE models
        SET models.passenger_capacity = p_new_capacity
        WHERE models.id = (
            SELECT model_id
            FROM planes
            WHERE id = p_id
        ) AND models.type = 'passenger';
    ELSE
        RAISE INVALID_PLANE_TYPE;
    END IF;
EXCEPTION
    WHEN INVALID_PLANE_TYPE THEN
        DBMS_OUTPUT.PUT_LINE('Invalid plane type.');

    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Plane not found.');
END;

BEGIN
    update_plane_model_capacity('cargo', 1, 5423);
    update_plane_model_capacity('passenger', 2, 321);
END;

-- Explain plan

-- Selects name from models
EXPLAIN PLAN FOR
SELECT name FROM models;

-- Execution Plan:
---------------
-- | Id | Operation         | Name   | Rows | Bytes | Cost (%CPU)| Time     |
---------------
-- |  0 | SELECT STATEMENT  |        |    8 |   248 |     2   (0)| 00:00:01 |
-- |  1 |  TABLE ACCESS FULL| MODELS |    8 |   248 |     2   (0)| 00:00:01 |
---------------

-- Executes the previous select
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Gets the name of the model, if its cargo or passenger plane
-- Makes the count of both planes types, then it groups by ID and NAME
EXPLAIN PLAN FOR
SELECT m.name, COUNT(CASE WHEN m.type = 'passenger' THEN 1 END) AS passenger_count,
       COUNT(CASE WHEN m.type = 'cargo' THEN 1 END) AS cargo_count
FROM models m
JOIN planes p ON m.id = p.model_id
GROUP BY m.id, m.name;

-- Executes the previous select
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Index for explain plan

-- Optimization can be done creating an index on the "type" column of the "models" table
-- This will allow the database to quickly receive only the rows that match the "type" condition in the CASE statement

CREATE INDEX idx_models_type ON models (type);

-- Re-execution of the query and comparing the results before and after
EXPLAIN PLAN FOR
SELECT m.name, COUNT(CASE WHEN m.type = 'passenger' THEN 1 END) AS passenger_count,
       COUNT(CASE WHEN m.type = 'cargo' THEN 1 END) AS cargo_count
FROM models m
JOIN planes p ON m.id = p.model_id
GROUP BY m.id, m.name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Privileges for another user
-- Gives xotrad00 all privileges on each table
-- GRANT ALL allows xotrad00 read, insert, update and delete data in each table

GRANT ALL ON models TO xotrad00;
GRANT ALL ON planes TO xotrad00;
GRANT ALL ON engineers TO xotrad00;
GRANT ALL ON tests TO xotrad00;
GRANT ALL ON qualifications TO xotrad00;
GRANT ALL ON performed_tests TO xotrad00;

-- Materialized view for the other user
-- Creates a materialized view named "mat_view" 
-- that counts the total number of performed tests for each model of plane.
CREATE MATERIALIZED VIEW mat_view AS
SELECT models.name, COUNT(performed_tests.id) AS total_tests
FROM models
JOIN planes ON models.id = planes.model_id
JOIN performed_tests ON planes.id = performed_tests.plane_id
GROUP BY models.name;

GRANT ALL ON mat_view TO xotrad00; 

-- Query with WITH & CASE 
-- Defines a common table expression (CTE) named 'test_values'
-- that calculates whether each performed test has passed or 
-- not based on its submitted value and the min/max limits of 
-- the corresponding test type. Then, the main query counts the 
-- total number of tests that passed.
WITH test_values AS (
  SELECT performed_tests.id, performed_tests.value,
    CASE
      WHEN performed_tests.value >= tests.min_limit AND performed_tests.value <= tests.max_limit THEN 1
      ELSE 0
    END AS passed
  FROM performed_tests
  JOIN tests ON performed_tests.test_type_id = tests.id
)
SELECT COUNT(*) AS total_passed_tests
FROM test_values
WHERE passed = 1;