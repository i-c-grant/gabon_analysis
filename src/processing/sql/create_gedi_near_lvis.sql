CREATE TABLE gedi_near_lvis_lope AS 
SELECT DISTINCT ON (gedi.shot_number) gedi.*
FROM gabon_agbd_all gedi
JOIN lvis_lope lvis
ON ST_DWithin(gedi.geom_other_lvis_crs, lvis.geom, 50);

CREATE TABLE gedi_near_lvis_mabounie AS 
SELECT DISTINCT ON (gedi.shot_number) gedi.*
FROM gabon_agbd_all gedi
JOIN lvis_mabounie lvis
ON ST_DWithin(gedi.geom_other_lvis_crs, lvis.geom, 50);

CREATE TABLE gedi_near_lvis_rabi AS 
SELECT DISTINCT ON (gedi.shot_number) gedi.*
FROM gabon_agbd_all gedi
JOIN lvis_rabi lvis
ON ST_DWithin(gedi.geom_other_lvis_crs, lvis.geom, 50);

CREATE TABLE gedi_near_lvis_mondah AS 
SELECT DISTINCT ON (gedi.shot_number) gedi.*
FROM gabon_agbd_all gedi
JOIN lvis_mondah lvis
ON ST_DWithin(gedi.geom_mondah_crs, lvis.geom, 50);

ALTER TABLE gedi_near_lvis_lope
ADD COLUMN rh100 DOUBLE PRECISION;

-- Create tables with average AGB_pred from nearby LVIS points
CREATE TABLE gedi_avg_lvis_agb_mabounie_25m AS 
SELECT 
    gedi.*,
    AVG(lvis.agb_pred) AS avg_lvis_agb_pred
FROM gabon_agbd_all gedi
JOIN lvis_mabounie lvis
ON ST_DWithin(gedi.geom_other_lvis_crs, lvis.geom, 25)
GROUP BY gedi.fid;

CREATE TABLE gedi_avg_lvis_agb_rabi_25m AS 
SELECT 
    gedi.*,
    AVG(lvis.agb_pred) AS avg_lvis_agb_pred
FROM gabon_agbd_all gedi
JOIN lvis_rabi lvis
ON ST_DWithin(gedi.geom_other_lvis_crs, lvis.geom, 25)
GROUP BY gedi.fid;

CREATE TABLE gedi_avg_lvis_agb_mondah_25m AS 
SELECT 
    gedi.*,
    AVG(lvis.agb_pred) AS avg_lvis_agb_pred
FROM gabon_agbd_all gedi
JOIN lvis_mondah lvis
ON ST_DWithin(gedi.geom_mondah_crs, lvis.geom, 25)
GROUP BY gedi.fid;

CREATE TEMPORARY TABLE temp_lvis_gedi_stats_mabounie AS
WITH lvis_stats AS (
    SELECT 
        gedi.shot_number,
        AVG(lvis.rh100) AS lvis_avg_rh100,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_median_rh100,
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_pct_90_rh100,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_pct_95_rh100,
	MAX(lvis.rh100) AS lvis_max_rh100
    FROM gedi_near_lvis_mabounie gedi
    JOIN lvis_mabounie lvis
    ON ST_DWithin(gedi.geom_other_lvis_crs, lvis.geom, 25)
    GROUP BY gedi.shot_number
)
SELECT 
    g.*,
    ls.lvis_avg_rh100,
    ls.lvis_median_rh100,
    ls.lvis_pct_90_rh100,
    ls.lvis_pct_95_rh100,
    ls.lvis_max_rh100
FROM gedi_near_lvis_mabounie g
LEFT JOIN lvis_stats ls ON g.shot_number = ls.shot_number;

CREATE TEMPORARY TABLE temp_lvis_gedi_stats_lope AS
WITH lvis_stats AS (
    SELECT 
        gedi.shot_number,
        AVG(lvis.rh100) AS lvis_avg_rh100,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_median_rh100,
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_pct_90_rh100,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_pct_95_rh100,
	MAX(lvis.rh100) AS lvis_max_rh100
    FROM gedi_near_lvis_lope gedi
    JOIN lvis_lope lvis
    ON ST_DWithin(gedi.geom_other_lvis_crs, lvis.geom, 25)
    GROUP BY gedi.shot_number
)
SELECT 
    g.*,
    ls.lvis_avg_rh100,
    ls.lvis_median_rh100,
    ls.lvis_pct_90_rh100,
    ls.lvis_pct_95_rh100,
    ls.lvis_max_rh100
FROM gedi_near_lvis_lope g
LEFT JOIN lvis_stats ls ON g.shot_number = ls.shot_number;

CREATE TEMPORARY TABLE temp_lvis_gedi_stats_rabi AS
WITH lvis_stats AS (
    SELECT 
        gedi.shot_number,
        AVG(lvis.rh100) AS lvis_avg_rh100,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_median_rh100,
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_pct_90_rh100,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_pct_95_rh100,
	MAX(lvis.rh100) AS lvis_max_rh100
    FROM gedi_near_lvis_rabi gedi
    JOIN lvis_rabi lvis
    ON ST_DWithin(gedi.geom_other_lvis_crs, lvis.geom, 25)
    GROUP BY gedi.shot_number
)
SELECT 
    g.*,
    ls.lvis_avg_rh100,
    ls.lvis_median_rh100,
    ls.lvis_pct_90_rh100,
    ls.lvis_pct_95_rh100,
    ls.lvis_max_rh100
FROM gedi_near_lvis_rabi g
LEFT JOIN lvis_stats ls ON g.shot_number = ls.shot_number;

CREATE TEMPORARY TABLE temp_lvis_gedi_stats_mondah AS
WITH lvis_stats AS (
    SELECT 
        gedi.shot_number,
        AVG(lvis.rh100) AS lvis_avg_rh100,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_median_rh100,
        PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_pct_90_rh100,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY lvis.rh100) AS lvis_pct_95_rh100,
	MAX(lvis.rh100) AS lvis_max_rh100
    FROM gedi_near_lvis_mondah gedi
    JOIN lvis_mondah lvis
    ON ST_DWithin(gedi.geom_mondah_crs, lvis.geom, 25)
    GROUP BY gedi.shot_number
)
SELECT 
    g.*,
    ls.lvis_avg_rh100,
    ls.lvis_median_rh100,
    ls.lvis_pct_90_rh100,
    ls.lvis_pct_95_rh100,
    ls.lvis_max_rh100
FROM gedi_near_lvis_mondah g
LEFT JOIN lvis_stats ls ON g.shot_number = ls.shot_number;

-- Create permanent tables without 'temp_' prefix and with '_with_rh' suffix
CREATE TABLE lvis_gedi_stats_mabounie_with_rh AS
SELECT * FROM temp_lvis_gedi_stats_mabounie;

CREATE TABLE lvis_gedi_stats_lope_with_rh AS
SELECT * FROM temp_lvis_gedi_stats_lope;

CREATE TABLE lvis_gedi_stats_rabi_with_rh AS
SELECT * FROM temp_lvis_gedi_stats_rabi;

CREATE TABLE lvis_gedi_stats_mondah_with_rh AS
SELECT * FROM temp_lvis_gedi_stats_mondah;

-- Clean up temporary tables
DROP TABLE temp_lvis_gedi_stats_mabounie;
DROP TABLE temp_lvis_gedi_stats_lope;
DROP TABLE temp_lvis_gedi_stats_rabi;
DROP TABLE temp_lvis_gedi_stats_mondah;
