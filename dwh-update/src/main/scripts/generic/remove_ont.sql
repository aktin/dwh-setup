DELETE FROM i2b2metadata.table_access WHERE c_table_cd LIKE 'test%';
DELETE FROM i2b2metadata.i2b2 WHERE sourcesystem_cd='test';
DELETE FROM i2b2crcdata.concept_dimension WHERE sourcesystem_cd='test';
DELETE FROM i2b2metadata.table_access WHERE c_table_cd LIKE 'aktin%';
DELETE FROM i2b2metadata.i2b2 WHERE sourcesystem_cd='aktin';
DELETE FROM i2b2crcdata.concept_dimension WHERE sourcesystem_cd='aktin';