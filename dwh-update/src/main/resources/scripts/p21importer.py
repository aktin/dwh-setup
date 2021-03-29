# -*- coding: utf-8 -*-
"""
Created on Wed Jan 20 11:36:55 2021
@author: akombeiz
"""
#@VERSION=1.0
#@VIEWNAME=Importskript für stationäre Behandlungsdaten
#@MIMETYPE=zip
#@ID=p21import
"""
Script to verify and import p21 data into AKTIN DWH

AKTIN DWH calls script method and provides path to zip-file
Only the methods 'verify_file()' and 'import_file()' can be called by DWH

verify_file() checks validity of given zip-file regarding p21 requirements
and matches plausible encounters with found encounters in database

import_file() runs a modified version of verify_file() and iterates through
matched encounters. At each iteration, all p21 variables for the current
encounter are collected from the zip-file and coverted to
i2b2crcdata.observation_fact rows. Prior uploading each encounter, it is checked
if p21 data of encounter was already uploaded using this script and deleted if
necessary
"""

import os
import sys
import zipfile
import chardet
import pandas as pd
import sqlalchemy as db
import hashlib
import base64
import re
import traceback
from datetime import datetime

"""
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
VERIFY FILE
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
"""

def verify_file(path_zip):
    """
    Checks validity of a given zip-file regarding p21 requirements (path
    integrity, required column names, value formatting) and matches vaild
    encounters against optin encounters in i2b2. See docs of used methods for
    further details

    Parameters
    ----------
    path_zip : str
        Path to the zip-file

    Returns
    -------
    None.

    """
    check_file_path_integrity(path_zip)
    check_csv_names(path_zip)
    check_csv_column_headers(path_zip)
    list_plausible_encounter = get_plausible_encounter(path_zip)
    check_encounter_matching_with_db(list_plausible_encounter)


def check_file_path_integrity(path_zip):
    """
    Checks, if file of given path exists and is a zip-file

    Parameters
    ----------
    path_zip : str
        Path to the zip-file

    Raises
    ------
    SystemExit
        If path is invalid or file is not a zip-file

    Returns
    -------
    None.

    """
    if not os.path.exists(path_zip):
        raise SystemExit('file path is not valid')
    if not zipfile.is_zipfile(path_zip):
        raise SystemExit('file is not a zipfile')


def check_csv_names(path_zip):
    """
    Checks, if files named 'FALL.csv', 'FAB.csv', 'OPS.csv' and 'ICD.csv' exist
    within given zip-file (see DICT_P21_COLUMNS)

    Parameters
    ----------
    path_zip : str
        Path to the zip-file

    Raises
    ------
    SystemExit
        If one or more files are missing

    Returns
    -------
    None.

    """
    with zipfile.ZipFile(path_zip, 'r') as file_zip:
        set_required_csv = set(DICT_P21_COLUMNS.keys())
        set_matched_csv = set_required_csv.intersection(set(file_zip.namelist()))
        if set_matched_csv != set_required_csv:
            raise SystemExit('following csv are missing in zip: {0}'.format(set_required_csv.difference(set_matched_csv)))


def check_csv_column_headers(path_zip):
    """
    Checks if csv-files named 'FALL.csv', 'FAB.csv', 'OPS.csv' and 'ICD.csv' in
    zip-file contain the required columns (see DICT_P21_COLUMNS)

    Parameters
    ----------
    path_zip : str
        Path to the zip-file

    Raises
    ------
    SystemExit
        If one or more columns in csv-file are missing

    Returns
    -------
    None.

    """
    with zipfile.ZipFile(path_zip, 'r') as file_zip:
        for name_csv in list(DICT_P21_COLUMNS.keys()):
            headers_csv = pd.read_csv(file_zip.open(name_csv, mode='r'), nrows=0, index_col=0, sep=CSV_SEPARATOR, encoding=get_csv_encoding(file_zip, name_csv))
            set_required_columns = set(DICT_P21_COLUMNS[name_csv])
            set_matched_columns = set_required_columns.intersection(set(headers_csv))
            if set_matched_columns != set_required_columns:
                raise SystemExit('following columns are missing in {0}: {1}'.format(name_csv, set_required_columns.difference(set_matched_columns)))


def get_csv_encoding(file_zip, name_csv):
    """
    Reads the first {CSV_BYTES_CHECK_ENCODER} Bytes of a given csv file in
    given zip and returns the csv encoding as a str

    Parameters
    ----------
    file_zip : ZipFile
        Zip-file with p21 csv-files
    name_csv : str
        Name of the csv-file to check encoding of

    Returns
    -------
    str
        Encoding of given csv-file

    """
    return chardet.detect(file_zip.open(name_csv).read(CSV_BYTES_CHECK_ENCODER))['encoding']


def get_plausible_encounter(path_zip):
    """
    Extracts from FALL.csv all encounter ids, where corresponding columns values
    follow the p21 formatting requirements. Iterates through FAB.csv, ICD.csv
    and OPS.csv and extracts encounter ids, too. Checks extracted encounter ids
    against the ones in FALL.csv and deletes non-matched ids from FALL.csv

    Parameters
    ----------
    path_zip : str
        Path to the zip-file

    Raises
    ------
    SystemExit
        If empty list shall be returned

    Returns
    -------
    list_result : list
        List with plausible encounter ids (non-hashed)
        (plausible = all column values of encounter correspond to syntax
        requirements and encounter appears in every csv)

    """
    list_result = []
    with zipfile.ZipFile(path_zip, 'r') as file_zip:
        list_result = check_value_syntax_by_encounter_id(file_zip, 'FALL.csv')
        list_enc_full = list_result
        for name_csv in ['FAB.csv', 'ICD.csv', 'OPS.csv']:
            list_enc_csv = check_value_syntax_by_encounter_id(file_zip, name_csv)
            if not do_encounter_lists_match(list_enc_full, 'FALL.csv', list_enc_csv, name_csv):
                list_result = list(set(list_result).intersection(set(list_enc_csv)))
            del list_enc_csv
    if not list_result:
        raise SystemExit('no plausible encounter found')
    return list_result


def check_value_syntax_by_encounter_id(file_zip, name_csv):
    """
    Iterates in chunks trough a given csv-file and checks each chunk column for
    empty fields or wrong value formatting. Encounter ids of fields which do not
    meet format criteria are collected and excluded from further processing

    Parameters
    ----------
    file_zip : ZipFile
        Zip-file with p21 csv-files
    name_csv : str
        Name of the csv-file to check syntax in

    Returns
    -------
        List of encounter ids in csv, where all columns follow the p21 requirements

    """
    set_enc_all = set()
    set_enc_invalid_fields = set()
    for chunk in pd.read_csv(file_zip.open(name_csv, mode='r'), chunksize=CSV_CHUNKSIZE, sep=CSV_SEPARATOR, encoding=get_csv_encoding(file_zip, name_csv), dtype=str):
        chunk = chunk[DICT_P21_COLUMNS[name_csv]].fillna('')
        for column in DICT_P21_COLUMNS[name_csv]:
            set_enc_invalid_fields.update(get_invalid_fields_encounter(chunk, column))
        set_enc_all.update(chunk['KH-internes-Kennzeichen'].unique())
    return list(set_enc_all.difference(set_enc_invalid_fields))


def get_invalid_fields_encounter(chunk, column):
    """
    Creates a set of encounter ids where fields are empty for given column
    and creates a set of encounter ids where non-empty fields do not abide
    formatting requirements. If given column has a non-empty field
    requirement, a union of both sets is returned, otherwise only set
    with violated formatting (can also be empty)

    Parameters
    ----------
    chunk : pandas.DataFrame
        Chunk of csv-file
    column : str
        Csv column to check empty fields in

    Returns
    -------
        Set with encounter ids where corresponding fields in chunk violated p21 requirements

    """
    pattern = DICT_P21_COLUMN_PATTERN[column]
    set_empty_fields = set(chunk[chunk[column] == '']['KH-internes-Kennzeichen'].values)
    set_wrong_syntax = set(chunk[(chunk[column] != '') & (chunk[column].str.match(pattern) == False)]['KH-internes-Kennzeichen'].values)
    if len(set_wrong_syntax):
        print('following encounter ids are skipped (wrong format for {0}): {1}'.format(column, set_wrong_syntax))
    if len(set_empty_fields) and column in LIST_P21_COLUMN_NON_EMPTY:
        print('following encounter ids are skipped (empty field in {0}): {1}'.format(column, set_empty_fields))
        return set_wrong_syntax.union(set_empty_fields)
    return set_wrong_syntax


def do_encounter_lists_match(list_base, name_base, list_comp, name_comp):
    """
    Compares two lists of encounter_ids and prints out non-matches. Used to
    check, if plausible encounter ids appear in all given csv-files

    Parameters
    ----------
    list_base : list
        Base list of encounter ids (FALL.csv)
    name_base : TYPE
        Name of the base list
    list_comp : TYPE
        List to compare base list with (FAB.csv, OPS.csv, ICD.csv)
    name_comp : TYPE
        Name of the comparator list

    Returns
    -------
    bool
        True if lists match completely, otherwise False

    """
    set_base = set(list_base)
    set_comp = set(list_comp)
    if len(set_base.symmetric_difference(set_comp)):
        set_match = set_base.intersection(set_comp)
        if len(set_base.difference(set_match)):
            print('following encounter ids are skipped (in {0}, but not in {1}): {2}'.format(name_base, name_comp, set_base.difference(set_match)))
        if len(set_comp.difference(set_match)):
            print('following encounter ids are skipped (in {0}, but not in {1}): {2}'.format(name_comp, name_base, set_comp.difference(set_match)))
        return False
    else:
        return True


def check_encounter_matching_with_db(list_encounter):
    """
    Compares plausible encounter ids of zip-file with optin encounter ids of
    i2b2crcdata and prints matching results

    Parameters
    ----------
    list_encounter : list
        List with all plausible encounter ids of zip-file (result of
        get_plausible_encounter())

    Returns
    -------
    None.

    """
    try:
        engine = get_db_engine()
        with engine.connect() as connection:
            list_db_ide = get_AKTIN_optin_encounter(engine, connection)
        list_zip_ide = anonymize_enc(list_encounter)
        list_matches = get_zip_matches(list_db_ide, list_zip_ide)
        print_results(list_db_ide, list_zip_ide, list_matches)
    finally:
        engine.dispose()


def get_db_engine():
    """
    Extracts connection path (format: HOST:PORT/DB) out of given connection-url
    and creates engine object with given credentials (all via environment
    variables) to enable a database connection

    Returns
    -------
    sqlalchemy.engine
        Engine object which enables a connection with i2b2crcdata

    """
    pattern = 'jdbc:postgresql://(.*?)(\?searchPath=.*)?$'
    connection = re.search(pattern, I2B2_CONNECTION_URL).group(1)
    return db.create_engine('postgresql+psycopg2://{0}:{1}@{2}'.format(USERNAME, PASSWORD, connection))


def get_AKTIN_optin_encounter(engine, connection):
    """
    Runs a query on i2b2crcdata to get all encounter_ide in encounter_mapping
    where the corresponding patients do not appear in optinout_patients of
    AKTIN (either patients without pat_psn or patients with pat_psn, but without
    study_id = 'AKTIN'). Streams query results into list

    Parameters
    ----------
    engine : sqlalchemy.engine
        Engine object of get_db_engine()
    connection : sqlalchemy.connection
        Connection object of engine to run querys on

    Returns
    -------
    list_result : list
        List with all (hashed) encounter ids which are not marked as optout
        for AKTIN

    """
    list_result = []
    enc = db.Table('encounter_mapping', db.MetaData(), autoload_with=engine)
    opt = db.Table('optinout_patients', db.MetaData(), autoload_with=engine)
    query = db.select([enc.c['encounter_ide']]) \
        .select_from(enc.join(opt, enc.c['patient_ide'] == opt.c['pat_psn'], isouter=True)) \
        .where(db.or_(opt.c['study_id'] != 'AKTIN', opt.c['pat_psn'].is_(None)))
    #SELECT encounter_mapping.encounter_ide FROM encounter_mapping LEFT OUTER JOIN optinout_patients ON encounter_mapping.patient_ide = optinout_patients.pat_psn WHERE optinout_patients.study_id != %(study_id_1)s OR optinout_patients.pat_psn IS NULL
    result = connection.execution_options(stream_results=True).execute(query)
    while True:
        chunk = result.fetchmany(DB_CHUNKSIZE)
        if not chunk:
            break
        [list_result.append(el[0]) for el in chunk]
    return list_result


def anonymize_enc(list_enc):
    """
    Gets the root.preset from aktin.properties as well as stated cryptographic
    hash function and cryptographic salt and uses them to hash encounter ids
    of a given list
    (only used for hashing plausible encounter ids of zip-file)

    Parameters
    ----------
    list_enc : list
        List with encounter ids

    Returns
    -------
    list_enc_ide : list
        List with hashed encounter ids

    """
    list_enc_ide = []
    root = get_aktin_property('cda.encounter.root.preset')
    salt = get_aktin_property('pseudonym.salt')
    alg = get_aktin_property('pseudonym.algorithm')
    for enc in list_enc:
        list_enc_ide.append(one_way_anonymizer(alg, root, enc, salt))
    return list_enc_ide


def get_aktin_property(property_aktin):
    """
    Searches aktin.properties for given key and returns the corresponding value

    Parameters
    ----------
    property_aktin : str
        Key of the requested property

    Returns
    -------
    str
        Corresponding value of requested key or empty string if not found

    """
    if not os.path.exists(PATH_AKTIN_PROPERTIES):
        raise SystemExit('file path for aktin.properties is not valid')
    with open(PATH_AKTIN_PROPERTIES) as properties:
        for line in properties:
            if "=" in line:
                key, value = line.split("=", 1)
                if(key == property_aktin):
                    return value.strip()
        return ''


def one_way_anonymizer(name_alg, root, extension, salt):
    """
    Hashes given encounter id with given algorithm, root.preset and salt. If
    no algorithm was stated, sha1 is used

    Parameters
    ----------
    name_alg : str
        Name of cryptographic hash function from aktin.properties
    root : str
        Root preset from aktin.properties
    extension : str
        Encounter id to hash
    salt : str
        Cryptographic salt from aktin.properties

    Returns
    -------
    str
        Hashed encounter id

    """
    name_alg = convert_crypto_alg_name(name_alg) if name_alg else 'sha1'
    composite = '/'.join([str(root), str(extension)])
    composite = salt + composite if salt else composite
    buffer = composite.encode('UTF-8')
    alg = getattr(hashlib, name_alg)()
    alg.update(buffer)
    return base64.urlsafe_b64encode(alg.digest()).decode('UTF-8')


def convert_crypto_alg_name(name_alg):
    """
    Converts given name of java cryptograhpic hash function to python demanted
    format, example:
        MD5 -> md5
        SHA-1 -> sha1
        SHA-512/224 -> sha512_224

    Parameters
    ----------
    name_alg : str
        Name to convert to python format

    Returns
    -------
    str
        Converted name of hash function

    """
    return str.lower(name_alg.replace('-','',).replace('/','_'))


def get_zip_matches(list_db_ide, list_zip_ide):
    """
    Compares two lists and returns matches. Used to get encounters which are
    plausible in zip-file and appear in database

    Parameters
    ----------
    list_db_ide : list
        List with hashed optin encounter ids from database
    list_zip_ide : list
        List with hashed plausible encounter ids from zip-file

    Returns
    -------
    list
        List with matched hashed encounter ids

    """
    return list(set(list_zip_ide).intersection(set(list_db_ide)))


def get_zip_non_matches(list_db_ide, list_enc_ide, list_enc):
    """
    Compares two lists and returns non-matches as items from third list.
    Used to get encounters which are plausible in zip-file but do not appear
    in database (hashed ids are compared, but unhashed ids are returned)

    Parameters
    ----------
    list_db_ide : list
        List with hashed optin encounter ids from database
    list_enc_ide : list
        List with hashed plausible encounter ids from zip-file.
    list_enc : list
        List with unhashed plausible encounter ids from zip-file
        (item order equals list_enc_ide)

    Returns
    -------
    list
        List with non-matched unhashed encounter ids

    """
    set_non_matches = set(list_enc_ide).difference(set(list_db_ide))
    indeces_non_matches = []
    for non_match in set_non_matches:
        indeces_non_matches.append(list_enc_ide.index(non_match))
    return [list_enc[index] for index in indeces_non_matches]


def print_results(list_db, list_zip, list_matches):
    """
    Prints matching results of given lists
    (total lists sizes, percentual matches and non-matched items)

    Parameters
    ----------
    list_db : list
        List with hashed optin encounter ids from database
    list_zip : list
        List with hashed plausible encounter ids from zip-file
    list_matches : list
        List with matched hashed encounter ids

    Returns
    -------
    None.

    """
    count_db = len(list_db)
    count_zip = len(list_zip)
    count_matches = len(list_matches)
    print('\nPlausible Fälle in Zip: {0}'.format(count_zip))
    print('Fälle in Datenbank: {0}'.format(count_db))
    print('Mögliche Matches mit Datenbank: {0}'.format(count_matches))
    print('Anteil gematchter plausibler Fälle: {0}%'.format("{:.2f}".format(count_matches/count_zip*100)))


"""
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
IMPORT FILE
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
"""


def import_file(path_zip):
    """
    Imports p21 data of all plausible and database matched encounters of a
    given zip-file to i2b2crcdata.observation_fact. Checks, if p21 data of
    encounters were already uploaded using this script and deletes entries if
    necessary

    Parameters
    ----------
    path_zip : str
        Path to the zip-file

    Returns
    -------
    None.

    """
    df_zip_ide = get_zip_encounter_df(path_zip)
    try:
        engine = get_db_engine()
        with engine.connect() as connection:
            df_match = get_matched_encounter_df(engine, connection, df_zip_ide)
            del df_zip_ide
            table_observation = db.Table('observation_fact', db.MetaData(), autoload_with=engine)
            with zipfile.ZipFile(path_zip, 'r') as file_zip:
                for row in pd.read_csv(file_zip.open('FALL.csv', mode='r'), chunksize=1, sep=CSV_SEPARATOR, encoding=get_csv_encoding(file_zip, 'FALL.csv'), dtype=str):
                    id_encounter = row['KH-internes-Kennzeichen'].iloc[0]
                    if id_encounter in df_match['encounter_id'].values:
                        num_enc, num_pat = get_enc_nums_from_df(id_encounter, df_match)
                        list_upload_rows = collect_and_convert_encounter_data(file_zip, row, num_enc, num_pat)
                        check_and_delete_uploaded_encounter(connection, table_observation, num_enc)
                        upload_encounter_data(connection, table_observation, list_upload_rows)
                        df_match.drop(df_match.loc[df_match['encounter_num'] == num_enc].index, inplace=True)
    finally:
        engine.dispose()


def get_zip_encounter_df(path_zip):
    """
    Collects all plausible encounter ids from given zip-file and returns
    DataFrame with hashed and unhashed ids

    Parameters
    ----------
    path_zip : str
        Path to the zip-file

    Returns
    -------
    pandas.DataFrame
        DataFrame with hashed and unhashed plausible encounter ids

    """
    list_plausible_encounter = get_plausible_encounter(path_zip)
    list_zip_ide = anonymize_enc(list_plausible_encounter)
    return pd.DataFrame(list(zip(list_plausible_encounter, list_zip_ide)), columns=['encounter_id', 'encounter_ide'])


def get_matched_encounter_df(engine, connection, df_zip_ide):
    """
    Compares plausible encounter ids of zip-file with optin encounter ids of
    i2b2crcdata and returns DataFrame with matched encounter and corresponding
    patient_num and encounter_num

    Parameters
    ----------
    engine : sqlalchemy.engine
        Engine object of get_db_engine()
    connection : sqlalchemy.connection
        Connection object of engine to run querys on
    df_zip_ide : pandas.DataFrame
        DataFrame with hashed and unhashed plausible encounter ids from zip-file

    Returns
    -------
    df_merged : pandas.DataFrame
        DataFrame with matched unhashed encounter ids and corresponding
        patient_num and encounter_num

    """
    df_db_ide = get_AKTIN_optin_pat_and_enc(engine, connection)
    df_merged = pd.merge(df_db_ide, df_zip_ide, on=['encounter_ide'])
    df_merged = df_merged.drop(['encounter_ide'], axis=1)
    return df_merged


def get_AKTIN_optin_pat_and_enc(engine, connection):
    """
    Runs a query on i2b2crcdata for all encounter_ide in encounter_mapping
    which do not appear in optinout_patients and returns encounter_ide
    and corresponding patient_num and encounter_num. Streams query results in
    DataFrame
    Is similar to get_AKTIN_optin_encounter() but collects encounter_num and
    patient_num in addition to encounter_ide with return type being a DataFrame
    instead of a list

    Parameters
    ----------
    engine : sqlalchemy.engine
        Engine object of get_db_engine()
    connection : sqlalchemy.connection
        Connection object of engine to run querys on

    Returns
    -------
    df_result : pandas.DataFrame
        DataFrame with all (hashed) encounter ids which are not marked as optout
        for AKTIN study and corresponding encounter_num and patient_num

    """
    enc = db.Table('encounter_mapping', db.MetaData(), autoload_with=engine)
    pat = db.Table('patient_mapping', db.MetaData(), autoload_with=engine)
    opt = db.Table('optinout_patients', db.MetaData(), autoload_with=engine)
    query = db.select([enc.c['encounter_ide'], enc.c['encounter_num'], pat.c['patient_num']]) \
        .select_from(enc.join(pat, enc.c['patient_ide'] == pat.c['patient_ide'])
                     .join(opt, pat.c['patient_ide'] == opt.c['pat_psn'], isouter=True)) \
        .where(db.or_(opt.c['study_id'] != 'AKTIN', opt.c['pat_psn'].is_(None)))
    #SELECT encounter_mapping.encounter_ide, encounter_mapping.encounter_num, patient_mapping.patient_num FROM encounter_mapping JOIN patient_mapping ON encounter_mapping.patient_ide = patient_mapping.patient_ide LEFT OUTER JOIN optinout_patients ON patient_mapping.patient_ide = optinout_patients.pat_psn WHERE optinout_patients.study_id != %(study_id_1)s OR optinout_patients.pat_psn IS NULL
    df_result = stream_query_into_df(connection, query)
    return df_result


def stream_query_into_df(connection, query):
    """
    Runs a given query on a given connection and streams result into a DataFrame.
    Only useage is to stream results (possibly large data) of
    get_AKTIN_optin_pat_and_enc()

    Parameters
    ----------
    connection : sqlalchemy.connection
        Connection object of engine to run querys on
    query : sqlalchemy.Select
        Sqlalchemy query object

    Returns
    -------
    df_result : pandas.DataFrame
        DataFrame with results of executed query

    """
    df_result = pd.DataFrame()
    result = connection.execution_options(stream_results=True).execute(query)
    while True:
        chunk = result.fetchmany(DB_CHUNKSIZE)
        if not chunk:
            break
        if df_result.empty:
            df_result = pd.DataFrame(chunk)
        else:
            df_result = df_result.append(chunk, ignore_index=True)
    df_result.columns = result.keys()
    return df_result


def get_enc_nums_from_df(id_encounter, df_match):
    """
    Extracts from df_match corresponding encounter_num and patient_num for
    given encounter id

    Parameters
    ----------
    id_encounter : str
        Encounter id to get corresponding encounter_num and patient_num from
    df_match : TYPE
        DataFrame with matched unhashed encounter ids and corresponding
        patient_num and encounter_num

    Returns
    -------
    num_encounter : str
        Encounter_num of encounter
    num_patient : str
        Patient_num of encounter

    """
    num_encounter = int(df_match.loc[df_match['encounter_id'] == id_encounter]['encounter_num'].iloc[0])
    num_patient = int(df_match.loc[df_match['encounter_id'] == id_encounter]['patient_num'].iloc[0])
    return num_encounter, num_patient


def collect_and_convert_encounter_data(file_zip, row, num_enc, num_pat):
    """
    Collects all p21 data for a given encounter and converts it into
    uploadable i2b2crcdata.observation_fact rows

    Parameters
    ----------
    file_zip : ZipFile
        Zip-file with p21 csv-files.
    row : TYPE
        Single row DataFrame of FALL.csv with encounter to collect data for
    num_enc : str
        Corresponding encounter_num of encounter
    num_pat : str
        Corresponding patient_num of encounter

    Returns
    -------
    list
        List of observation_fact rows with collected p21 variables of a given
        encounter

    """
    dict_csv = collect_csv_data_of_encounter(file_zip, row)
    return convert_dict_csv_to_upload_rows(dict_csv, num_enc, num_pat)


def collect_csv_data_of_encounter(file_zip, row):
    """
    Collects p21 variables from csv-files for a given encounter.
    Iterates through FAB.csv, ICD.csv and OPS.csv and collects all p21 rows for
    a given encounter in a seperate DataFrame (not FALL.csv, because input row
    has all available data from FALL.csv). P21 encounter data is stored as a
    dict with [csv name]:[DataFrame of csv with p21 columns of encounter]

    Parameters
    ----------
    file_zip : ZipFile
        Zip-file with p21 csv-files.
    row : pandas.DataFrame
        Single row DataFrame of FALL.csv with encounter to collect data for

    Returns
    -------
    dict_csv : dict
        Dictionary with [csv name]:[DataFrame of csv with p21 columns of encounter]

    """
    dict_csv = {'FALL.csv': row[DICT_P21_COLUMNS['FALL.csv']]}
    id_enc = row['KH-internes-Kennzeichen'].iloc[0]
    for name_csv in ['FAB.csv', 'ICD.csv', 'OPS.csv']:
        df_csv = pd.DataFrame()
        for chunk in pd.read_csv(file_zip.open(name_csv, mode='r'), chunksize=CSV_CHUNKSIZE, sep=CSV_SEPARATOR, encoding=get_csv_encoding(file_zip, name_csv), dtype=str):
            if any(chunk['KH-internes-Kennzeichen'].isin([id_enc])):
                chunk = chunk[chunk['KH-internes-Kennzeichen'].isin([id_enc])][DICT_P21_COLUMNS[name_csv]]
                df_csv = chunk if df_csv.empty else df_csv.append(chunk)
        dict_csv[name_csv] = df_csv
    return dict_csv


def convert_dict_csv_to_upload_rows(dict_csv, num_enc, num_pat):
    """
    Converts a given dictionary with p21 DataFrames to a list of uploadable
    i2b2crcdata.observation_fact rows

    Parameters
    ----------
    dict_csv : dict
        Dictionary with [csv name]:[DataFrame of csv with p21 columns] of given encounter
    num_enc : str
        Encounter_num of encounter
    num_pat : str
        Patient_num of encounter

    Returns
    -------
    list_dict_upload : list
        List of dict (observation_fact rows) with collected p21 variables of
        given encounter

    """
    for key in dict_csv.keys():
        dict_csv[key] = dict_csv[key].fillna('')
    date_admission = str(dict_csv['FALL.csv']['Aufnahmedatum'].iloc[0])
    list_dict_upload = []
    list_dict_upload.extend(insert_upload_data_FALL(dict_csv['FALL.csv'], date_admission))
    list_dict_upload.extend(insert_upload_data_FAB(dict_csv['FAB.csv']))
    list_dict_upload.extend(insert_upload_data_ICD(dict_csv['ICD.csv'], date_admission))
    list_dict_upload.extend(insert_upload_data_OPS(dict_csv['OPS.csv']))
    list_dict_upload.extend(create_script_rows())
    date_import = datetime.now(tz=None).strftime('%Y-%m-%d %H:%M:%S.%f')
    date_admission = datetime.strptime(date_admission, '%Y%m%d%H%M').strftime('%Y-%m-%d %H:%M')
    for index, row in enumerate(list_dict_upload):
        list_dict_upload[index] = add_fixed_values(row, num_enc, num_pat, date_admission, date_import)
    return list_dict_upload


def insert_upload_data_FALL(df_csv, date_admission):
    """
    Converts p21 variables from FALL.csv of given encounter into a list
    of i2b2crcdata.observation_fact rows. Only mandatory column values are
    created for each row. Default values (like provider_id or sourcesystem_cd)
    are added at the end of convert_dict_csv_to_upload_rows() through
    add_fixed_values()

    Notes:
        In Fall.csv, only the columns 'Aufnahmedatum','Aufnahmegrund' and
        'Aufnahmeanlass' are mandatory

        Other columns may be empty and are only added, if the columns contains
        a value

        Columns 'Entlassungsdatum' and 'Entlassungsgrund' are only added, if
        both columns contain a value

        Columns 'Fallzusammenführung' and 'Fallzusammenführungsgrund' are only
        added, if both columns contain a value and 'Fallzusammenführung' equals
        'J'

        Column 'Behandlungstage-vorstationär' is only added, if
        'Behandlungsbeginn-vorstationär' contains a value, but is not mandatory
        for 'Behandlungsbeginn-vorstationär' to be added

        Same goes for 'Behandlungstage-nachstationär' with
        'Behandlungsende-nachstationär'

    Parameters
    ----------
    df_csv : pandas.DataFrame
        Single row DataFrame of FALL.csv with p21 variables of encounter
    date_admission : str
        Admission date of encounter. Only used for modifier "EffectiveTime"
        of "Geburtjahr" (LOINC:80904-6)

    Returns
    -------
    list_observation_dicts : list
        List of observation_fact rows with added FALL.csv data

    """
    list_observation_dicts = []
    list_observation_dicts.extend(create_rows_admission(df_csv['Aufnahmeanlass'].iloc[0], df_csv['Aufnahmegrund'].iloc[0]))
    if df_csv['IK-der-Krankenkasse'].iloc[0]:
        list_observation_dicts.append(create_row_insurance(df_csv['IK-der-Krankenkasse'].iloc[0]))
    if df_csv['Geburtsjahr'].iloc[0]:
        list_observation_dicts.extend(create_rows_birthyear(df_csv['Geburtsjahr'].iloc[0], date_admission))
    if df_csv['Geschlecht'].iloc[0]:
        list_observation_dicts.append(create_row_sex(df_csv['Geschlecht'].iloc[0]))
    if df_csv['PLZ'].iloc[0]:
        list_observation_dicts.append(create_row_zipcode(df_csv['PLZ'].iloc[0]))
    if df_csv['Fallzusammenführung'].iloc[0] == 'J' and df_csv['Fallzusammenführungsgrund'].iloc[0]:
        list_observation_dicts.append(create_row_encounter_merge(df_csv['Fallzusammenführungsgrund'].iloc[0]))
    if df_csv['Verweildauer-intensiv'].iloc[0]:
        list_observation_dicts.append(create_row_critical_care(df_csv['Verweildauer-intensiv'].iloc[0]))
    if df_csv['Entlassungsdatum'].iloc[0] and df_csv['Entlassungsgrund'].iloc[0]:
        list_observation_dicts.append(create_row_discharge(df_csv['Entlassungsdatum'].iloc[0], df_csv['Entlassungsgrund'].iloc[0]))
    if df_csv['Beatmungsstunden'].iloc[0]:
        list_observation_dicts.append(create_row_ventilation(df_csv['Beatmungsstunden'].iloc[0]))
    if df_csv['Behandlungsbeginn-vorstationär'].iloc[0]:
        list_observation_dicts.append(create_row_therapy_start_prestation(df_csv['Behandlungsbeginn-vorstationär'].iloc[0], df_csv['Behandlungstage-vorstationär'].iloc[0]))
    if df_csv['Behandlungsende-nachstationär'].iloc[0]:
        list_observation_dicts.append(create_row_therapy_end_poststation(df_csv['Behandlungsende-nachstationär'].iloc[0], df_csv['Behandlungstage-nachstationär'].iloc[0]))
    return list_observation_dicts


def create_rows_admission(cause, reason):
    """
    Creates observation_fact rows for encounter admission. Cause and reason
    are both added as seperate rows with seperate concept_cd.

    Parameters
    ----------
    cause : str
        Value of 'Aufnahmeanlass' in FALL.csv
    reason : str
        Value of 'Aufnahmegrund' in FALL.csv

    Returns
    -------
    list
        List with dicts (observation_fact rows) for encounter admission

    """
    concept_cause = ':'.join(['P21:ADMC', str.upper(cause)])
    concept_reason = ':'.join(['P21:ADMR', str.upper(reason)])
    return [{'concept_cd': concept_cause, 'modifier_cd': '@', 'valtype_cd': '@', 'valueflag_cd': '@'},
            {'concept_cd': concept_reason, 'modifier_cd': '@', 'valtype_cd': '@', 'valueflag_cd': '@'}]


def create_row_insurance(insurance):
    """
    Creates observation_fact row for insurance number of encounter

    Parameters
    ----------
    insurance : str
        Value of 'IK-der-Krankenkasse' in FALL.csv

    Returns
    -------
    dict
        Observation_fact row for insurance number

    """
    return {'concept_cd': 'AKTIN:IKNR', 'modifier_cd': '@', 'valtype_cd': 'T', 'tval_char': insurance}


def create_rows_birthyear(birthyear, date_admission):
    """
    Creates observation_fact rows for encounter birthyear. LOINC code is used
    as concept_cd

    Parameters
    ----------
    birthyear : str
        Value of 'Geburtsjahr' in FALL.csv
    date_admission : str
        Admission date of encounter (%Y%m%d%H%M). Is saved unformatted as
        modifier 'effectiveTime'

    Returns
    -------
    list
        List with dicts (observation_fact rows) for encounter birthyear

    """
    return [{'concept_cd': 'LOINC:80904-6', 'modifier_cd': '@', 'valtype_cd': 'N', 'nval_num': birthyear, 'units_cd': 'yyyy'},
            {'concept_cd': 'LOINC:80904-6', 'modifier_cd': 'effectiveTime', 'valtype_cd': 'T', 'tval_char': date_admission}]


def create_row_sex(sex):
    """
    Creates observation_fact row for sex of encounter patient. Patient sex isa
    dded as a concept_cd

    Parameters
    ----------
    sex : str
        Value of 'Geschlecht' in FALL.csv

    Returns
    -------
    dict
        Observation_fact row for patient sex

    """
    concept_sex = ':'.join(['P21:SEX', str.upper(sex)])
    return {'concept_cd': concept_sex, 'modifier_cd': '@', 'valtype_cd': '@', 'valueflag_cd': '@'}


def create_row_zipcode(zipcode):
    """
    Creates observation_fact row for zipcode of encounter patient

    Parameters
    ----------
    zipcode : str
         Value of 'PLZ' in FALL.csv

    Returns
    -------
    dict
        Observation_fact row for patient zipcode

    """
    return {'concept_cd': 'AKTIN:ZIPCODE', 'modifier_cd': '@', 'valtype_cd': 'N', 'nval_num': zipcode}


def create_row_encounter_merge(reason):
    """
    Creates observation_fact row for reason of encounter merge (row is only
    created, if encounter merge occured, as no merge == no reason)

    Parameters
    ----------
    val_merge : str
         Value of 'Fallzusammenführungsgrund' in FALL.csv

    Returns
    -------
    dict
        Observation_fact row for encounter merge

    """
    concept_merge = ':'.join(['P21:MERGE', str.upper(reason)])
    return {'concept_cd': concept_merge, 'modifier_cd': '@', 'valtype_cd': '@', 'valueflag_cd': '@'}


def create_row_critical_care(intensive):
    """
    Creates observation_fact row for stayed duration in critical care of
    encounter patient

    Parameters
    ----------
    intensive : str
        Value of 'Verweildauer-intensiv' in FALL.csv

    Returns
    -------
    dict
       Observation_fact row for duration in critical care

    """
    intensive = intensive.replace(',', '.')
    return {'concept_cd': 'P21:DCC', 'modifier_cd': '@', 'valtype_cd': 'N', 'nval_num': intensive, 'units_cd': 'd'}


def create_row_discharge(date_end, reason):
    """
    Creates observation_fact row for encounter discharge. Reason is added as
    concept_cd. End date has to be formatted in '%Y-%m-%d %H:%M'

    Parameters
    ----------
    date_end : str
        Value of 'Entlassungsdatum' in FALL.csv (%Y%m%d%H%M)
    reason : str
        Value of 'Entlassungsgrund' in FALL.csv

    Returns
    -------
    list
        List with dicts (observation_fact rows) for encounter discharge

    """
    date_end = convert_date_to_i2b2_format(date_end)
    concept_reason = ':'.join(['P21:DISR', str.upper(reason)])
    return {'concept_cd': concept_reason, 'start_date': date_end, 'modifier_cd': '@', 'valtype_cd': '@', 'valueflag_cd': '@'}


def create_row_ventilation(ventilation):
    """
    Creates observation_fact row for duration of respiratory ventilation of
    encounter patient

    Parameters
    ----------
    ventilation : str
        Value of 'Beamtungsstunden' in FALL.csv

    Returns
    -------
    dict
        Observation_fact row for duration of ventilation

    """
    ventilation = ventilation.replace(',', '.')
    return {'concept_cd': 'P21:DV', 'modifier_cd': '@', 'valtype_cd': 'N', 'nval_num': ventilation, 'units_cd': 'h'}


def create_row_therapy_start_prestation(date_start, days):
    """
    Creates observation_fact rows for prestationary therapy start of encounter.
    Start date has to be converted in '%Y-%m-%d %H:%M'. Hours and minutes are
    added as 00:00. Variable days is optional and will be not inserted as
    row value if empty.

    Parameters
    ----------
    date_start : str
        Value of 'Behandlungsbeginn-vorstationär' in FALL.csv (%Y%m%d)
    days : str
        Value of 'Behandlungstage-vorstationär' in FALL.csv

    Returns
    -------
    result : dict
        Observation_fact row for prestationary therapy start

    """
    date_start = convert_date_to_i2b2_format(''.join([date_start, '0000']))
    if days:
        result = {'concept_cd': 'P21:PREADM', 'start_date': date_start, 'modifier_cd': '@', 'valtype_cd': 'N', 'nval_num': days, 'units_cd': 'd'}
    else:
        result = {'concept_cd': 'P21:PREADM', 'start_date': date_start, 'modifier_cd': '@', 'valtype_cd': '@', 'valueflag_cd': '@'}
    return result


def create_row_therapy_end_poststation(date_end, days):
    """
    Creates observation_fact rows for poststaionary therapy end of encounter.
    End date has to be converted in '%Y-%m-%d %H:%M'. Hours and minutes are
    added as 00:00. Variable days is optional and will be not inserted as
    row value if empty.

    Parameters
    ----------
    date_end : str
        Value of 'Behandlungsende-nachstationär' in FALL.csv (%Y%m%d)
    days : str
        Value of 'Behandlungstage-nachstationär' in FALL.csv

    Returns
    -------
    result : dict
        Observation_fact row for  poststationary therapy end

    """
    date_end = convert_date_to_i2b2_format(''.join([date_end, '0000']))
    if days:
        result = {'concept_cd': 'P21:POSTDIS', 'start_date': date_end, 'modifier_cd': '@', 'valtype_cd': 'N', 'nval_num': days, 'units_cd': 'd'}
    else:
        result = {'concept_cd': 'P21:POSTDIS', 'start_date': date_end, 'modifier_cd': '@', 'valtype_cd': '@', 'valueflag_cd': '@'}
    return result


def insert_upload_data_FAB(df_csv):
    """
    Converts p21 variables from FAB.csv of given encounter into a list
    of i2b2crcdata.observation_fact rows. Only mandatory column values are
    created for each row. Default values (like provider_id or sourcesystem_cd)
    are added at the end of convert_dict_csv_to_upload_rows() through
    add_fixed_values()

    Notes:
        Columns of dataFrame are snapped together and iterated through with a
        call on create_rows_department() in each iteration

    Parameters
    ----------
    df_csv : pandas.DataFrame
        DataFrame of FAB.csv with p21 variables of encounter

    Returns
    -------
    list_observation_dicts : list
        List of observation_fact rows with added FAB.csv data

    """
    list_observation_dicts = []
    zip_csv = zip(df_csv['Fachabteilung'], df_csv['Kennung-Intensivbett'], df_csv['FAB-Aufnahmedatum'], df_csv['FAB-Entlassungsdatum'])
    for i, row in enumerate(zip_csv):
        list_observation_dicts.append(create_row_department(i+1, row[0], row[1], row[2], row[3]))
    return list_observation_dicts


def create_row_department(num_instance, department, intensive, date_start, date_end):
    """
    Creates observation_fact rows for one stay in a certain department of
    encounter patient. End date and start date have to be formatted in
    '%Y-%m-%d %H:%M'. End date is not mandatory and will be written as None
    if empty

    Parameters
    ----------
    num_instance : int
        Instance_num in observation_fact
    department : str
        Value of 'Fachabteilung' in FAB.csv
    intensive : str
        Value of 'Kennung-Intensivbett' in FAB.csv
    date_start : str
        Value of 'FAB-Aufnahmedatum' in FAB.csv (%Y%m%d%H%M)
    date_end : str
        Value of 'FAB-Entlassungsdatum' in FAB.csv (%Y%m%d%H%M)

    Returns
    -------
    dict
        Observation fact row for stay in given department of encounter

    """
    date_start = convert_date_to_i2b2_format(date_start)
    date_end = convert_date_to_i2b2_format(date_end) if date_end else None
    concept_dep = 'P21:DEP:CC' if intensive == 'J' else 'P21:DEP'
    return {'concept_cd': concept_dep, 'start_date': date_start, 'modifier_cd': '@', 'instance_num': num_instance, 'valtype_cd': 'T', 'tval_char': department, 'end_date': date_end}


def insert_upload_data_ICD(df_csv, date_admission):
    """
    Converts p21 variables from ICD.csv of given encounter into a list
    of i2b2crcdata.observation_fact rows. Only mandatory column values are
    created for each row. Default values (like provider_id or sourcesystem_cd)
    are added at the end of convert_dict_csv_to_upload_rows() through
    add_fixed_values()

    Notes:
        Columns of dataFrame are snapped together and iterated through with a
        call on create_rows_icd() in each iteration

        Last index of i from first enumeration is saved

        A new zip is created for columns of Sekundärdiagnose and iterated
        through, calling create_row_icd_sek() each iteration, but with the
        difference that the call only happens if 'Sekundär-Kode' is not empty
        in the iteration. Also, the index from first enumration is used as
        a starting index, avoid data distortion if a diagnosis appears
        both as Haupt- and Sekundärdiagnose (index is used as instance_num)

    Parameters
    ----------
    df_csv : pandas.DataFrame
        DataFrame of ICD.csv with p21 variables of encounter
    date_admission : str
        Admission date of encounter (%Y%m%d%H%M). Used for 'effectiveTimeLow'
        modifier

    Returns
    -------
    list_observation_dicts : list
        List of observation_fact rows with added ICD.csv data

    """
    list_observation_dicts = []
    zip_csv = zip(df_csv['ICD-Kode'], df_csv['Diagnoseart'], df_csv['ICD-Version'], df_csv['Lokalisation'], df_csv['Diagnosensicherheit'])
    for i, row in enumerate(zip_csv):
        list_observation_dicts.extend(create_rows_icd(i+1, row[0], row[1], row[2], row[3], row[4], date_admission))
    num_iter = i+2

    zip_csv = zip(df_csv['Sekundär-Kode'], df_csv['ICD-Kode'], df_csv['ICD-Version'], df_csv['Sekundär-Lokalisation'], df_csv['Sekundär-Diagnosensicherheit'])
    for i, row in enumerate(zip_csv):
        list_observation_dicts.extend(create_row_icd_sek(num_iter+i, row[0], row[1], row[2], row[3], row[4], date_admission)) if row[0] else None
    return list_observation_dicts


def create_rows_icd(num_instance, code_icd, diag_type, version, localisation, certainty, date_adm):
    """
    Creates observation_fact rows for an encounter diagnosis. The ICD code
    itself is added as a concept_cd. Variables localisation and certainty are
    optional and row creation is skipped if these are empty.

    Parameters
    ----------
    num_instance : int
        Instance_num in observation_fact
    code_icd : str
        Value of 'ICD-Kode' in ICD.csv
    diag_type : str
        Value of 'Diagnoseart' in ICD.csv
    version : str
        Value of 'ICD-Version' in ICD.csv
    localisation : str
        Value of 'Lokalisation' in ICD.csv
    certainty : str
        Value of 'Diagnosensicherheit' in ICD.csv
    date_adm : str
        Admission date of encounter (%Y%m%d%H%M). Is safed unformatted
        as modifier 'EffectiveTimeLow'

    Returns
    -------
    result : list
         List with dicts (observation_fact rows) for given diagnosis

    """
    concept_icd = ':'.join(['ICD10GM', convert_icd_code_to_i2b2_format(code_icd)])
    result = [{'concept_cd': concept_icd, 'modifier_cd': '@', 'instance_num': num_instance, 'valtype_cd': '@', 'valueflag_cd': '@'},
              {'concept_cd': concept_icd, 'modifier_cd': 'diagType', 'instance_num': num_instance, 'valtype_cd': 'T', 'tval_char': diag_type},
              {'concept_cd': concept_icd, 'modifier_cd': 'cdVersion', 'instance_num': num_instance, 'valtype_cd': 'N', 'nval_num': version, 'units_cd': 'yyyy'},
              {'concept_cd': concept_icd, 'modifier_cd': 'effectiveTimeLow', 'instance_num': num_instance, 'valtype_cd': 'T', 'tval_char': date_adm}]
    if localisation:
        result.append({'concept_cd': concept_icd, 'modifier_cd': 'localisation', 'instance_num': num_instance, 'valtype_cd': 'T', 'tval_char': localisation})
    if certainty:
        result.append({'concept_cd': concept_icd, 'modifier_cd': 'certainty', 'instance_num': num_instance, 'valtype_cd': 'T', 'tval_char': certainty})
    return result


def create_row_icd_sek(num_instance, code_icd, code_parent, version, localisation, certainty, date_adm):
    """
    Creates observation_fact rows for a Sekundärdiagnose of an encounter.
    Each Sekundärdiagnose must have a corresponding Hauptdiagnose. Calls
    create_rows_icd(), but with diag_type='SD' and adds an own sdFrom-modifier

    Parameters
    ----------
    num_instance : int
        Instance_num in observation_fact
    code_icd : str
        Value of 'Sekundär-Kode' in ICD.csv
    code_parent : str
        Value of 'ICD-Kode' in ICD.csv
    version : str
        Value of 'ICD-Version' in ICD.csv
    localisation : str
        Value of 'Sekundär-Lokalisation' in ICD.csv
    certainty : str
        Value of 'Sekundär-Diagnosensicherheit' in ICD.csv
    date_adm : str
        Admission date of encounter (%Y%m%d%H%M). Is safed unformatted
        as modifier 'EffectiveTimeLow'

    Returns
    -------
    result : list
         List with dicts (observation_fact rows) for given Sekundärdiagnose

    """
    result = create_rows_icd(num_instance, code_icd, 'SD', version, localisation, certainty, date_adm)
    concept_parent = ':'.join(['ICD10GM', convert_icd_code_to_i2b2_format(code_parent)])
    concept_icd = ':'.join(['ICD10GM', convert_icd_code_to_i2b2_format(code_icd)])
    result.append({'concept_cd': concept_icd, 'modifier_cd': 'sdFrom', 'instance_num': num_instance, 'valtype_cd': 'T', 'tval_char': concept_parent})
    return result


def insert_upload_data_OPS(df_csv):
    """
    Converts p21 variables from OPS.csv of given encounter into a list
    of i2b2crcdata.observation_fact rows. Only mandatory column values are
    created for each row. Default values (like provider_id or sourcesystem_cd)
    are added at the end of convert_dict_csv_to_upload_rows() through
    add_fixed_values()

    Notes:
        Columns of dataFrame are snapped together and iterated through with a
        call on create_rows_ops() in each iteration

    Parameters
    ----------
    df_csv : pandas.DataFrame
        DataFrame of OPS.csv with p21 variables of encounter

    Returns
    -------
    list_observation_dicts : list
        List of observation_fact rows with added OPS.csv data

    """
    list_observation_dicts = []
    zip_csv = zip(df_csv['OPS-Kode'], df_csv['OPS-Version'], df_csv['Lokalisation'], df_csv['OPS-Datum'])
    for i, row in enumerate(zip_csv):
        list_observation_dicts.extend(create_rows_ops(i+1, row[0], row[1], row[2], row[3]))
    return list_observation_dicts


def create_rows_ops(num_instance, code_ops, version, localisation, date_ops):
    """
    Creates observation_fact rows for carried out procedures on encounter
    patient. The OPS code itself is added as a concept_cd. OPS date has to be
    formatted in '%Y-%m-%d %H:%M'. Variable localisation is optional and its row
    creation is skipped if localisation is empty.

    Parameters
    ----------
    num_instance : int
        Instance_num in observation_fact
    code_ops : str
        Value of 'OPS-Kode' in OPS.csv
    version : str
        Value of 'OPS-Version' in OPS.csv
    localisation : str
        Value of 'Lokalisation' in OPS.csv
    date_ops : str
        Value of 'OPS-Datum' in OPS.csv (%Y%m%d%H%M)

    Returns
    -------
    result : list
         List with dicts (observation_fact rows) for carried out procedures

    """
    date_ops = convert_date_to_i2b2_format(date_ops)
    concept_ops = ':'.join(['OPS', convert_ops_code_to_i2b2_format(code_ops)])
    result = [{'concept_cd': concept_ops, 'start_date': date_ops, 'modifier_cd': '@', 'instance_num': num_instance, 'valtype_cd': '@', 'valueflag_cd': '@'},
              {'concept_cd': concept_ops, 'start_date': date_ops, 'modifier_cd': 'cdVersion', 'instance_num': num_instance, 'valtype_cd': 'N', 'nval_num': version, 'units_cd': 'yyyy'}]
    if localisation:
        result.append({'concept_cd': concept_ops, 'start_date': date_ops, 'modifier_cd': 'localisation', 'instance_num': num_instance, 'valtype_cd': 'T', 'tval_char': localisation})
    return result


def convert_date_to_i2b2_format(num_date):
    """
    Converts a string date from %Y%m%d%H%M to %Y-%m-%d %H:%M. Used to convert
    p21 dates from zip-file to i2b2crcdata.observation_fact format

    Parameters
    ----------
    num_date : str
        Date in format %Y%m%d%H%M

    Returns
    -------
    str
        Date in format %Y-%m-%d %H:%M

    """
    return datetime.strptime(str(num_date), '%Y%m%d%H%M').strftime('%Y-%m-%d %H:%M')


def convert_icd_code_to_i2b2_format(code_icd):
    """
    Converts ICD code to i2b2crcdata.observation_fact format by checking and
    adding (if necessary) '.'-delimiter at index 3

    Example:
        F2424 -> F24.24
        F24.24 -> F24.24

    Parameters
    ----------
    code_icd : str
        ICD code to convert

    Returns
    -------
    str
        ICD code with added delimiter

    """
    return ''.join([code_icd[:3], '.', code_icd[3:]] if code_icd[3] != '.' else code_icd)


def convert_ops_code_to_i2b2_format(code_ops):
    """
    Converts OPS code to i2b2crcdata.observation_fact format by checking and
    adding (if necessary) '-'-delimiter at index 1 and '.'-delimiter at index 5.
    Second delimiter is only added, if more than three digits follow first
    delimiter

    Example:
        964922 -> 9-649.22
        9-64922 -> 9-649.22
        9649.22 -> 9-649.22
        9-649.22 -> 9-649.22
        1-5020 -> 1-502.0
        1-501 -> 1-501
        1051 -> 1-501

    Parameters
    ----------
    code_ops : str
        OPS code to convert

    Returns
    -------
    code_ops : str
        OPS code with added delimiter

    """
    code_ops = ''.join([code_ops[:1], '-', code_ops[1:]] if code_ops[1] != '-' else code_ops)
    if len(code_ops) > 5:
        code_ops = ''.join([code_ops[:5], '.', code_ops[5:]] if code_ops[5] != '.' else code_ops)
    return code_ops


def create_script_rows():
    """
    Creates observation_fact rows for script metadata (input from environment
    variables)

    Returns
    -------
    list
        List with dicts (observation_fact rows) for script metadata

    """
    return [{'concept_cd': 'P21:SCRIPT', 'modifier_cd': '@', 'valtype_cd': '@', 'valueflag_cd': '@'},
            {'concept_cd': 'P21:SCRIPT', 'modifier_cd': 'scriptVer', 'valtype_cd': 'T', 'tval_char': SCRIPT_VERSION},
            {'concept_cd': 'P21:SCRIPT', 'modifier_cd': 'scriptId', 'valtype_cd': 'T', 'tval_char': SCRIPT_ID}]


def add_fixed_values(dict_row, num_enc, num_pat, date_adm, date_import):
    """
    Adds static values to a single observation_fact row and checks, if required
    columns were created in row. Adds required columns with default values
    if necessary

    Parameters
    ----------
    dict_row : dict
        Observation_fact row to add fixed values to
    num_enc : str
        Encounter_num of encounter
    num_pat : str
        Patient_num of encounter
    date_adm : str
        Admission date of encounter (%Y-%m-%d %H:%M)
    date_import : str
        Current Timestamp (%Y-%m-%d %H:%M)

    Returns
    -------
    dict_row : dict
        Observation_fact row with added required columns

    """
    dict_row['encounter_num'] = num_enc
    dict_row['patient_num'] = num_pat
    dict_row['provider_id'] = 'P21'
    if 'start_date' not in dict_row:
        dict_row['start_date'] = date_adm
    if 'instance_num' not in dict_row:
        dict_row['instance_num'] = 1
    if 'tval_char' not in dict_row:
        dict_row['tval_char'] = None
    if 'nval_num' not in dict_row:
        dict_row['nval_num'] = None
    if 'valueflag_cd' not in dict_row:
        dict_row['valueflag_cd'] = None
    if 'units_cd' not in dict_row:
        dict_row['units_cd'] = '@'
    if 'end_date' not in dict_row:
        dict_row['end_date'] = None
    dict_row['location_cd'] = '@'
    dict_row['import_date'] = date_import
    dict_row['sourcesystem_cd'] = CODE_SOURCE
    return dict_row


def check_and_delete_uploaded_encounter(connection, table_obs, num_enc):
    """
    Runs a query to check if this script was already used to upload p21 data
    in i2b2crcdata.observation_fact of given encounter and deletes uploaded
    data from database if true

    Notes:
        Check is done by looking, if modifier 'scriptId' of concept
        'P21:SCRIPT' of given encounter equals the id of this script

        If this is the case, the sourcesystem_cd of concept 'P21:SCRIPT'
        is returned

        All entries with given sourecsystem_cd and encounter_num are deleted
        from i2b2crcdata.observation_fact (unique sourcesystem_cd is created
        for uploaded data using this script)

    Parameters
    ----------
    connection : sqlalchemy.connection
        Connection object of engine to run querys on
    table_obs : sqlalchemy.Table
        Table object of i2b2crcdata.observation_fact
    num_enc : str
        encounter_num of encounter

    Raises
    ------
    SystemExit
        If encounter has multiple sources for given script id or if delete
        operation fails

    Returns
    -------
    None.

    """
    query = db.select([table_obs.c['sourcesystem_cd']]) \
        .where(table_obs.c['encounter_num'] == str(num_enc)) \
        .where(table_obs.c['concept_cd'] == 'P21:SCRIPT') \
        .where(table_obs.c['modifier_cd'] == 'scriptId') \
        .where(table_obs.c['tval_char'] == SCRIPT_ID)
    #SELECT observation_fact.sourcesystem_cd FROM observation_fact WHERE observation_fact.encounter_num = %(encounter_num_1)s AND observation_fact.concept_cd = %(concept_cd_1)s AND observation_fact.modifier_cd = %(modifier_cd_1)s AND observation_fact.tval_char = %(tval_char_1)s
    result = connection.execute(query).fetchall()
    if result:
        if len(result) != 1:
            raise SystemExit('multiple sourcesystems for encounter found')
        sourcesystem_cd = result[0][0]
        statement_delete = table_obs.delete() \
            .where(table_obs.c['encounter_num'] == str(num_enc)) \
            .where(table_obs.c['sourcesystem_cd'] == sourcesystem_cd)
        #DELETE FROM observation_fact WHERE observation_fact.encounter_num = %(encounter_num_1)s AND observation_fact.sourcesystem_cd = %(sourcesystem_cd_1)s
        transaction = connection.begin()
        try:
            connection.execute(statement_delete)
            transaction.commit()
        except:
            transaction.rollback()
            traceback.print_exc()
            raise SystemExit('delete operation for encounter failed')


def upload_encounter_data(connection, table_obs, list_dict):
    """
    Uploads observation_fact rows (as a list of dict) into database table
    i2b2crcdata.observation_fact for given encounter

    Parameters
    ----------
    connection : sqlalchemy.connection
        Connection object of engine to run querys on
    table_obs : sqlalchemy.Table
        Table object of i2b2crcdata.observation_fact
    list_dict : list
        List of observation_fact rows with collected p21 variables of a given
        encounter

    Raises
    ------
    SystemExit
        If upload operation fails

    Returns
    -------
    None.

    """
    transaction = connection.begin()
    try:
        connection.execute(table_obs.insert(), list_dict)
        transaction.commit()
    except:
        transaction.rollback()
        traceback.print_exc()
        raise SystemExit('insert operation for encounter failed')


"""
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
MAIN
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
"""

if __name__ == '__main__':

    # required file names in zip-file and required columns for each file
    DICT_P21_COLUMNS = {
        'FALL.csv': ['KH-internes-Kennzeichen', 'IK-der-Krankenkasse', 'Geburtsjahr', 'Geschlecht', 'PLZ', 'Aufnahmedatum',
                     'Aufnahmegrund', 'Aufnahmeanlass', 'Fallzusammenführung', 'Fallzusammenführungsgrund', 'Verweildauer-intensiv',
                     'Entlassungsdatum', 'Entlassungsgrund', 'Beatmungsstunden', 'Behandlungsbeginn-vorstationär',
                     'Behandlungstage-vorstationär', 'Behandlungsende-nachstationär', 'Behandlungstage-nachstationär'],
        'FAB.csv': ['KH-internes-Kennzeichen', 'Fachabteilung', 'FAB-Aufnahmedatum', 'FAB-Entlassungsdatum', 'Kennung-Intensivbett'],
        'ICD.csv': ['KH-internes-Kennzeichen', 'Diagnoseart', 'ICD-Version', 'ICD-Kode', 'Lokalisation', 'Diagnosensicherheit',
                    'Sekundär-Kode', 'Sekundär-Lokalisation', 'Sekundär-Diagnosensicherheit'],
        'OPS.csv': ['KH-internes-Kennzeichen', 'OPS-Version', 'OPS-Kode', 'OPS-Datum', 'Lokalisation']
    }

    # columns which must not contain an empty field
    LIST_P21_COLUMN_NON_EMPTY = [
        'KH-internes-Kennzeichen',
        'Aufnahmedatum',
        'Aufnahmegrund',
        'Aufnahmeanlass',
        'Fachabteilung',
        'FAB-Aufnahmedatum',
        'Kennung-Intensivbett',
        'Diagnoseart',
        'ICD-Version',
        'ICD-Kode',
        'OPS-Version',
        'OPS-Kode',
        'OPS-Datum'
    ]

    # format requirements for each column
    DICT_P21_COLUMN_PATTERN = {
        'KH-internes-Kennzeichen': '^\w*$',
        'IK-der-Krankenkasse': '^\w*$',
        'Geburtsjahr': '^(19|20)\d{2}$',
        'Geschlecht': '^[mwdx]$',
        'PLZ': '^\d{5}$',
        'Aufnahmedatum': '^\d{12}$',
        'Aufnahmegrund': '^(0[1-9]|10)\d{2}$',
        'Aufnahmeanlass': '^[EZNRVAGB]$',
        'Fallzusammenführung': '^(J|N)$',
        'Fallzusammenführungsgrund': '^OG|MD|KO|RU|WR|MF|P[WRM]|Z[OMKRW]$',
        'Verweildauer-intensiv': '^\d*(,\d{2})?$',
        'Entlassungsdatum': '^\d{12}$',
        'Entlassungsgrund': '^\d{2}.{1}$',
        'Beatmungsstunden': '^\d*(,\d{2})?$',
        'Behandlungsbeginn-vorstationär': '^\d{8}$',
        'Behandlungstage-vorstationär': '^\d$',
        'Behandlungsende-nachstationär': '^\d{8}$',
        'Behandlungstage-nachstationär': '^\d$',
        'Fachabteilung': '^(HA|BA|BE)\d{4}$',
        'FAB-Aufnahmedatum': '^\d{12}$',
        'FAB-Entlassungsdatum': '^\d{12}$',
        'Kennung-Intensivbett': '^(J|N)$',
        'Diagnoseart': '^(HD|ND|SD)$',
        'ICD-Version': '^20\d{2}$',
        'ICD-Kode': '^[A-Z]\d{2}(\.)?.{0,3}$',
        'Lokalisation': '^[BLR]$',
        'Diagnosensicherheit': '^[AVZG]$',
        'Sekundär-Kode': '^[A-Z]\d{2}(\.)?.{0,3}$',
        'Sekundär-Lokalisation': '^[BLR]$',
        'Sekundär-Diagnosensicherheit': '^[AVZG]$',
        'OPS-Version': '^20\d{2}$',
        'OPS-Kode': '^\d{1}(\-)?\d{2}(.{1})?(\.)?.{0,2}$',
        'OPS-Datum': '^\d{12}$'
    }

    CSV_SEPARATOR = ';'
    CSV_BYTES_CHECK_ENCODER = 1024
    CSV_CHUNKSIZE = 1000
    DB_CHUNKSIZE = 1000

    USERNAME = os.environ["username"]
    PASSWORD = os.environ["password"]
    I2B2_CONNECTION_URL = os.environ["connection-url"]
    ZIP_UUID = os.environ["uuid"]
    SCRIPT_ID = os.environ["script_id"]
    SCRIPT_VERSION = os.environ["script_version"]
    PATH_AKTIN_PROPERTIES = os.environ["path_aktin_properties"]
    CODE_SOURCE = '_'.join(['i', SCRIPT_ID, ZIP_UUID])

    if len(sys.argv) != 3:
        raise SystemExit("sys.argv don't match")

    if sys.argv[1] == 'verify_file':
        verify_file(sys.argv[2])
    elif sys.argv[1] == 'import_file':
        import_file(sys.argv[2])
    else:
        raise SystemExit("unknown method function")
