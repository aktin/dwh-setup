UPDATE WORK_DB_LOOKUP SET c_db_fullschema = 'i2b2workdata' WHERE c_db_fullschema = 'public';
UPDATE ONT_DB_LOOKUP SET c_db_fullschema = 'i2b2metadata' WHERE c_db_fullschema = 'public';
UPDATE CRC_DB_LOOKUP SET c_db_fullschema = 'i2b2demodata' WHERE c_db_fullschema = 'public';
UPDATE IM_DB_LOOKUP SET c_db_fullschema = 'i2b2imdata' WHERE c_db_fullschema = 'public';
