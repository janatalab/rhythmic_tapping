expname = 'rhythmic_tapping_v2';
CONN_ID = 7; 

timeNow = clock;

project_root = '/data2/rhythm/rhythmic_tapping_v2';
project_path = project_root;
afs_project_root = '/afs/cmb.ucdavis.edu/share/petrlab/rhythmic_tapping/v2';
project_plots_path = [afs_project_root '/plots'];
assoc_fname = fullfile(project_root,sprintf('%s_assoc.txt', expname));

projectVarsSave = {'trials_by_type','expinfo','proc_subs','fdata','trialSets','sess','bt_tempo_estimates','summaryReport'};
projectSavePath = fullfile(project_root,'project_data',['rhythmTap_processedData_' date '_' ...
		    num2str(timeNow(4)) ':' num2str(timeNow(5)) ':' sprintf('%2.0f',timeNow(6))]);


SAVE_PROJECT = 0;
LOAD_PROJECT = 0;
data2load = 'rhythmTap_processedData_02-Mar-2007_19:40:17.mat';



PREPROCESS = 1;

%Ensemble response analysis toggles
READ_EXPINFO = 0;
ANALYSIS_LIST = 0;


%read in stims from Ensemble and store
STORE_STIMLIST_INFO = 0;

%stim parsing toggles
PARSE_STIM_RECORDING = 0;

SAVE_PARSED_STIMS = 0;

%signal/midi analysis toggles
CALC_ANI_RESPS = 0;
RHYTHM_PROFILER_RESPS = 0;
TAPPING_STATS = 0;
ESTIMATE_STIM_TEMPO = 0;

CALC_ANI_STIMS = 0;

LOAD_STIM_TEMPO = 0;

%plot toggles
PLOT_TAPPING_STATS_BY_SUBJECT = 0;

PLOT_METRIC_LEVELS_BY_TRIALCAT = 1;

VARTEST_SUMMARYREPORT = 0;

%the events in the event struct to ignore during parsing for each
%sub. The sublist is placed in the first encapsulated cell array
%and the corresponding index vectors to exclude are placed in the
%second encapsulated cell array.
ignoreMatchedEventForSub = {{'03yus88141','05vsb78121','11orj72111'},{[1 2],[1:23],[1:5]}};
ignoreParsedStimAudioForSub = {{'03yus88141'},{[2]}};


%the default number of practice trials
defaultNumPracticeTrials = 5;
%and the number of practice trials if a different number was
%actually recorded in Ensemble (due to anomalies at the beginning
%of the experiment like subjects closing the browser window, etc.)
numPracticeTrials = {{'03yus88141'},{4}};



clear spp mp;
spp.thresh_silence_dB = -60;
spp.thresh_silence_sec = 5;
spp.clip_pad_sec = 0;
spp.detect_cues = 1;
spp.throw_out_bad_cues = 0;
spp.save_wvf = 0;
spp.downsample_factor = 1;
spp.run_xcorr = 1;
spp.xcorr_fail_delete = 1;
spp.xcorr_channels = 1;
spp.mysql_conn_id = CONN_ID;
spp.expect.stim_dur_sec = 30;
spp.expect.min_clip_dur_sec = .2;
spp.path = fullfile(project_root,'dp_stimuli');

mp.event_pad_sec = 1.5;
mp.path = fullfile(project_root,'dp_responses');



 %indices in event data cell array for ANI and RP
ANI_IDX = 2;
RP_IDX = 3;
TAPPING_STATS_IDX = 4;
 
%some of the subjects were recorded at 48K for some reason
%place these in the following cell array
recorded_at_48K = {};

% Subjects to exclude
already_processed = {'01cgc83291','03mxv76151','03yus88141', ...
		    '04eee88251','04nnt88141','06pnn86051','07mok88271','07psk87031','08led84281','09rlc87111','10hul86041','12krn85161'};

subs_failing_xcorr = {'05vsb78121'};


exclude_subs = {'01fmt54011','01fss85301','01ttf50011', ...
		'01ttf51011','01ttf52011','01ttf53011',...
		'01ttf84011','01ttf99011','09nlr84261','12hnd81021',...
		subs_failing_xcorr{:}};

%must match trials_by_type fieldnames
graph_ioi_trialTypes = {'free_form_tap_silence','iso_tap_silence';...
                        'free_form_tap_low_groove','iso_tap_low_groove';...
		        'free_form_tap_mid_groove','iso_tap_mid_groove';...
		        'free_form_tap_high_groove','iso_tap_high_groove'};
		        
graph_ioi_rowLabels = {'silence','low\_groove','mid\_groove','high\_groove'};
graph_ioi_colLabels = {'free\_form\_tap','iso\_tap'};
 
varTest_rowLabels = {' Silence ',' Low Groove ',' Mid Groove ',' High Groove '};
varTest_colLabels = {' Free Form Tap ',' Iso Tap '};

save_ioi_graph = 1;

