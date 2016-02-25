--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = i2b2metadata, pg_catalog;

--
-- Data for Name: table_access; Type: TABLE DATA; Schema: i2b2metadata; Owner: i2b2metadata
--

COPY table_access (c_table_cd, c_table_name, c_protected_access, c_hlevel, c_fullname, c_name, c_synonym_cd, c_visualattributes, c_totalnum, c_basecode, c_metadataxml, c_facttablecolumn, c_dimtablename, c_columnname, c_columndatatype, c_operator, c_dimcode, c_comment, c_tooltip, c_entry_date, c_change_date, c_status_cd, valuetype_cd) FROM stdin;
test_a5f0b74b	i2b2	N	1	\\i2b2\\4e239cb8:EmergencyNote\\	AKTIN Notaufnahmeprotokoll	N	FA 	\N	\N	\N	concept_cd	concept_dimension	concept_path	T	LIKE	\\i2b2\\4e239cb8:EmergencyNote\\	\N	\\i2b2\\4e239cb8:EmergencyNote\\	\N	\N	\N	\N
\.


--
-- PostgreSQL database dump complete
--

