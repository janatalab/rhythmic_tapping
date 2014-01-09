% export_rhythmTap_normalization_stims
%
% Copies stimuli used in the rhythmic tapping normalization experiment to
% an output directory

% 09Jan2014 - Petr Janata - for collab with Michael Hove

defs = rhythmicTap_normalization_globals;

% Open a connection to the database
conn_id = mysql_make_conn(defs.mysql);

% Only export the -6 dB stimuli
filt_st.include.all.name = '\(-6 dB\)$';

% Copy the stimuli
ensemble_copy_stimuli2dir('conn_id', conn_id, ...
  'experiment_title', defs.ensemble.experiment_title, ...
  'stimroot', defs.paths.stimroot, ...
  'outpath', defs.paths.stimuli, ...
  'filt', filt_st);

% Close the connection to the database
mysql_check_conn(conn_id,'close');