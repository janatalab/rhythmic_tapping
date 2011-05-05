% Analyzes PANAS data from rhythmic_tapping_v2 experiment
%
% rhythmic_tapping_panas

LOAD_DATA = 0;

% Load project globals
globals = rhythmTap_globals;

% Load the MAT-file containing the post-stim ratings
if LOAD_DATA
	datafstub = 'rhythmTap_grooveEnumByTapStats_17July2007_14:15.mat';
	datafname = fullfile(globals.paths.datapath, datafstub);
	
	fprintf('Loading data from: %s\n', datafname);
	load(datafname,'an'); % Load the data
end

params.ensemble = globals.ensemble;
analyze_panas(an{1}.results.data{3}, params)