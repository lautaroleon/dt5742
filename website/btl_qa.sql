CREATE OR REPLACE FUNCTION pass(run_number bigint) RETURNS boolean AS $$
    SELECT count(*) > 32 FROM data WHERE run = run_number and pc_per_kev*5850/spe > 2000 AND pc_per_kev*5850/spe < 3000 AND spe > 3 AND spe < 4;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION pass_channel(key_number bigint) RETURNS boolean AS $$
    SELECT count(*) > 0 FROM data WHERE key = key_number and pc_per_kev*5850/spe > 2000 AND pc_per_kev*5850/spe < 3000 AND spe > 3 AND spe < 4;
$$ LANGUAGE SQL;

CREATE TYPE inst AS ENUM (
    'Caltech',
    'UVA',
    'Rome'
    'Milano'
    'CERN'
    'Peking'
);

CREATE TYPE sipm_type AS ENUM (
    'Type-2 HPK 15 um',
    'Type-2 HPK 20 um',
    'Type-2 HPK 25 um',
    'Type-2 HPK 25 um low Cg',
    'Type-1 HPK 25 um',
    'Type-3 HPK 25 um',
    'HPK',
    'FBK'
);

-- Table to keep track of the light yield of the BTL modules.
CREATE TABLE runs (
    run                 bigserial PRIMARY KEY,
    timestamp           timestamp with time zone default now(),
    voltage             real NOT NULL,
    institution         inst DEFAULT 'Caltech'::inst NOT NULL,
    git_sha1            text,
    git_dirty           text,
    filename            text,
    tec_resistance_a    real,
    tec_resistance_b    real,
    temp_a              real,
    temp_b              real
);

-- Table to keep track of the light yield of the BTL modules.
CREATE TABLE data (
    key                 bigserial PRIMARY KEY,
    channel             smallint,
    timestamp           timestamp with time zone default now(),
    barcode             bigint NOT NULL,
    pc_per_kev          real NOT NULL,
    spe                 real NOT NULL,
    lyso_fall_time    real,
    lyso_rise_time    real,
    lyso_charge_histogram_x  real[],
    lyso_charge_histogram_y  real[],
    spe_charge_histogram_x  real[],
    spe_charge_histogram_y  real[],
    avg_pulse_x         real[],
    avg_pulse_y         real[],
    run                 bigint NOT NULL references runs(run),
    spe_fit_pars        real[],
    spe_fit_par_errors  real[],
    lyso_fit_pars       real[],
    lyso_fit_par_errors real[],
    UNIQUE (channel,run)
);

-- Table to keep track of the light yield of the BTL modules.
CREATE TABLE modules (
    barcode             bigint PRIMARY KEY,
    timestamp           timestamp with time zone default now(),
    sipm                sipm_type NOT NULL,
    institution         inst DEFAULT 'Caltech'::inst NOT NULL,
    comments            text
);

-- create btl admin user
CREATE ROLE btl_admin WITH LOGIN;

-- btl admin user has all rights to everything in the database
GRANT ALL ON data TO btl_admin;
GRANT ALL ON runs TO btl_admin;
GRANT ALL ON modules TO btl_admin;
GRANT ALL ON SEQUENCE data_key_seq TO btl_admin;

-- create btl read user
CREATE ROLE btl_read;

-- btl read user has select rights on everything in the btl schema
GRANT SELECT ON data TO btl_read;
GRANT SELECT ON runs TO btl_read;
GRANT SELECT ON modules TO btl_read;
GRANT SELECT ON SEQUENCE data_key_seq TO btl_read;
GRANT SELECT ON SEQUENCE runs_run_seq TO btl_read;

-- create btl write user
CREATE ROLE btl_write;

-- btl write user has select rights on everything in the btl schema
GRANT SELECT, INSERT ON data TO btl_write;
GRANT SELECT, INSERT ON runs TO btl_write;
GRANT SELECT, INSERT ON modules TO btl_write;
GRANT SELECT, USAGE ON SEQUENCE data_key_seq TO btl_write;
GRANT SELECT, USAGE ON SEQUENCE runs_run_seq TO btl_write;

-- create btl user
CREATE ROLE btl WITH LOGIN;

-- this is the role used by the assembly centers to upload data
GRANT btl_read, btl_write TO btl;

-- create cms user
CREATE ROLE cms WITH LOGIN;

-- this is the role used by the website, should only have read access
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cms;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO cms;

-----------------------------
-- Set up ownership of tables
-----------------------------

ALTER TABLE data OWNER TO btl_admin;
