#!/bin/bash
NONE="\033[00m"
GREEN="\033[01;32m"
BOLD="\033[1m"

tmpdir="/var/tmp/dubletten_cleanup"
sqlfile="select_patient_stm.sql"
filename="selected_patients.txt"
outfile="dubletten_delete_stm.sql"
localdir="/root/dubletten_cleanup_"$(date +"%Y%m%d_%H%M%S")

mkdir $localdir
mkdir $tmpdir

# Write select statement for sourcesystem_cd of dublicates to sql file.
echo "
	SELECT DISTINCT sourcesystem_cd, patient_num, encounter_num
	FROM i2b2crcdata.observation_fact ob
	WHERE sourcesystem_cd in (
		-- Komplementärmenge wählen
		SELECT sourcesystem_cd 
		FROM i2b2crcdata.observation_fact ob
		JOIN (
			-- die Goldstandard-Werte von visit_dimension holen
			SELECT encounter_num, patient_num
			FROM i2b2crcdata.visit_dimension
			WHERE encounter_num in (
				-- Table mit encounter-Dubletten
				SELECT encounter_num
				FROM i2b2crcdata.observation_fact
				WHERE concept_cd LIKE 'AKTIN:IPVI:%'  
				GROUP BY encounter_num
				HAVING count(encounter_num) > 1
			) 
		) as del
		ON ob.encounter_num = del.encounter_num AND ob.patient_num <> del.patient_num
	);" > $localdir/$sqlfile
echo "Suche Eintraege in observation_fact ohne zugehörigen Eintrag in visit_dimension (Dubletten)."
cp $localdir/$sqlfile $tmpdir

# execute select statement and write result (rows in observation_fact with no entry in visit_dimension for pat_num+enc_num) to new text file.  
chmod 777 $tmpdir/$sqlfile
su - postgres bash -c "psql -d i2b2 -f $tmpdir/$sqlfile -t" >> $tmpdir/$filename
num=$[$(wc -l < $tmpdir/$filename)-1]
echo "Anzahl gefundener Eintraege: ${num}"
cp $tmpdir/$filename $localdir/$filename

# No patient entries found, exit script.
if [ $num -eq 0 ]; then
	echo "Keine Eintraege zum Loeschen gefunden. Der Vorgang wird beendet."
	rm -r $tmpdir
	exit 1
fi

# Read each line (sourcesystem_cd, patient_num, encounter_num) of previously generated text file and append its delete statement to sql file. 
echo "Loesche gefundene Dubletten in observation_fact und ggf. zugehoerigen Patient in patient_dimension:"
while IFS='' read -r line || [[ -n "$line" ]]; do
    if [ ${#line} -gt 0 ]; then 
		sourcesystem_cd=$(echo $line | cut -f1 -d\| | tr -d '[:space:]')
		pat_num=$(echo $line | cut -f2 -d\| | tr -d '[:space:]')
		encounter_num=$(echo $line | cut -f3 -d\| | tr -d '[:space:]')
		echo "DELETE FROM i2b2crcdata.observation_fact WHERE sourcesystem_cd = '$sourcesystem_cd';" >> $localdir/$outfile
		echo "DELETE FROM i2b2crcdata.patient_dimension 
				WHERE sourcesystem_cd = '$sourcesystem_cd' AND patient_num NOT IN (
					SELECT patient_num
					FROM i2b2crcdata.visit_dimension
					GROUP BY patient_num
					HAVING COUNT(patient_num) > 0
				);" >> $localdir/$outfile
		echo "UPDATE i2b2crcdata.patient_dimension pd 
			SET sourcesystem_cd = (
				SELECT vd.sourcesystem_cd
				FROM i2b2crcdata.visit_dimension vd, i2b2crcdata.patient_dimension pd
				WHERE '$sourcesystem_cd' = pd.sourcesystem_cd AND '$sourcesystem_cd' <> vd.sourcesystem_cd AND '$pat_num' = vd.patient_num
			)
			WHERE pd.patient_num IN (
				SELECT pd.patient_num
				FROM i2b2crcdata.visit_dimension vd, i2b2crcdata.patient_dimension pd
				WHERE pd.patient_num = vd.patient_num AND pd.sourcesystem_cd = '$sourcesystem_cd'
			);" >> $localdir/$outfile
		echo -e "${BOLD}Loesche Eintraege mit:${NONE} patient_num: ${pat_num}, encounter_num: ${encounter_num}, sourcesystem_cd: ${sourcesystem_cd}"
	else
		echo ""
	fi
done < "$localdir/$filename"

cp $localdir/$outfile $tmpdir/$outfile
chmod 777 $tmpdir/$outfile

# execute delete statements
su - postgres bash -c "psql -d i2b2 -f $tmpdir/$outfile -t" &>/dev/null
echo -e "${GREEN}Loeschung der Dubletten erfolgreich abgeschlossen!${NONE}"

rm -r $tmpdir
