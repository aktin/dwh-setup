
UPDATE i2b2crcdata.patient_dimension SET vital_status_cd='TD' WHERE vital_status_cd='D' AND death_date IS NOT NULL;
UPDATE i2b2crcdata.patient_dimension SET vital_status_cd='TI' WHERE vital_status_cd='I' AND death_date IS NOT NULL;
UPDATE i2b2crcdata.patient_dimension SET vital_status_cd='ND' WHERE vital_status_cd='D' AND death_date IS NULL;
UPDATE i2b2crcdata.patient_dimension SET vital_status_cd='NI' WHERE vital_status_cd='I' AND death_date IS NULL;



UPDATE i2b2crcdata.visit_dimension SET active_status_cd='TD' WHERE active_status_cd IS NULL;
UPDATE i2b2crcdata.visit_dimension SET active_status_cd='TI' WHERE active_status_cd='I';
UPDATE i2b2crcdata.visit_dimension SET active_status_cd='TC' WHERE active_status_cd='C';

