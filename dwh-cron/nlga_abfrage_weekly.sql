select 'WOB' krankenhaus, v.encounter_num, round(to_number(to_char(v.start_date,'yyyy'),'9999')-to_number(to_char(p.birth_date,'yyyy'),'9999')) jahre, p.sex_cd, to_number(to_char(v.start_date,'IW'),'99') Woche, substr(cedis.concept_cd,9) cedis, substr(icd10.concept_cd,9) icd10, verbleib.concept_cd verbleib
FROM i2b2crcdata.patient_dimension p, 
i2b2crcdata.visit_dimension v 
LEFT OUTER JOIN (SELECT encounter_num, concept_cd FROM i2b2crcdata.observation_fact WHERE concept_cd LIKE 'CEDIS%'
AND modifier_cd = '@') cedis ON (v.encounter_num = cedis.encounter_num) 
LEFT OUTER JOIN (SELECT encounter_num, concept_cd FROM i2b2crcdata.observation_fact WHERE concept_cd LIKE 'ICD10%'
AND modifier_cd = '@') icd10 ON (v.encounter_num = icd10.encounter_num)
LEFT OUTER JOIN (select encounter_num, 
CASE 
WHEN concept_cd = 'AKTIN:DISCHARGE:1' THEN 'Tod'
WHEN concept_cd = 'AKTIN:DISCHARGE:2' THEN 'Entlassung gegen aerztlichen Rat'
WHEN concept_cd = 'AKTIN:DISCHARGE:3' THEN 'Behandlung durch Pat. abgebrochen'
WHEN concept_cd = 'AKTIN:DISCHARGE:4' THEN 'Entlassung nach Hause'
WHEN concept_cd = 'AKTIN:DISCHARGE:5' THEN 'Entlassung zu weiterbehandelnden Arzt'
WHEN concept_cd = 'AKTIN:DISCHARGE:6' THEN 'kein Arztkontakt'
WHEN concept_cd = 'AKTIN:DISCHARGE:OTH' THEN 'Sonstige Entlassung'
WHEN concept_cd = 'AKTIN:TRANSFER:1' THEN 'Aufnahme in Funktionsbereich'
WHEN concept_cd = 'AKTIN:TRANSFER:2' THEN 'Verlegung extern in Funktionsbereich'
WHEN concept_cd = 'AKTIN:TRANSFER:3' THEN 'Aufnahme auf Überwachungsstation'
WHEN concept_cd = 'AKTIN:TRANSFER:4' THEN 'Verlegung extern auf Überwachungsstation'
WHEN concept_cd = 'AKTIN:TRANSFER:5' THEN 'Aufnahme auf Normalstation'
WHEN concept_cd = 'AKTIN:TRANSFER:6' THEN 'Verlegung extern auf Normalstation'
ELSE NULL
END AS concept_CD
 from i2b2crcdata.observation_fact where (concept_cd like '%DISCHARGE%' or concept_cd like '%TRANSFER%') and modifier_cd = '@') 
Verbleib ON (v.encounter_num = verbleib.encounter_num)
WHERE v.patient_num = p.patient_num
AND  to_number(to_char(v.start_date,'WW'),'99') = to_number(to_char(current_date,'WW'),'99')-1;
