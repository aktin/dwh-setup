-- This maintenance script should be run in periodic intervals. e.g. daily/weekly
-- update patient age column
UPDATE patient_dimension SET age_in_years_num = DATE_PART('year',AGE(birth_date));

-- update death date and vital status from AKTIN data set
