BBBD Data Processing Scripts
=============================

STRUCTURE
---------
bids/raw/       - Scripts to write raw BIDS-formatted data (experiments 1-5)
bids/derived/   - Scripts to write derived BIDS-formatted data (experiments 1-5)
matrix/         - Scripts to write matrix-format data files (experiments 1-5)
config/         - Reference files bundled with the scripts (channel locs, demographics, etc.)
bbbd_run_all.m  - Runs all scripts in sequence
config.m        - Central configuration file (edit this before running)

SETUP
-----
Open config.m and set the five paths at the top:

  data_dir        - root folder containing experiment_1, experiment_2, ... subfolders
                    each subfolder must have: raw/, processed/, metadata/ subdirectories
  output_dir      - folder where all BBBD output will be written
  bbbd_source_dir - folder containing phenotype/descriptor files per experiment
  eeglab_path     - path to EEGLAB toolbox directory
  biosig_path     - path to BioSig toolbox directory (used by bbbd_123_derived_continuous only)

NOTE: config/ already contains BioSemi64.mat, doIntervention_indexing.mat,
experiment4_demographic.mat, and experiment5_demographic.mat.
You must manually place int_metadata.mat (the combined participant metadata file)
at config/int_metadata.mat before running experiments 4 and 5.

HOW TO RUN
----------
1. Open MATLAB and set the working directory to this folder (data_code/).
2. Edit config.m with your paths.
3. Run bbbd_run_all.m to execute all scripts in order, or run individual
   scripts directly as needed.

Scripts run in the following order per experiment group:
  1. raw_eye_heart       (physiological + eyetracking raw)
  2. raw_eeg             (EEG raw)
  3. derived_continuous  (continuous derived signals)
  4. derived_discrete    (discrete event timestamps)

DEPENDENCIES
------------
- EEGLAB (eeglab2024.2 or compatible)
- BioSig toolbox (required by bbbd_123_derived_continuous.m only)
