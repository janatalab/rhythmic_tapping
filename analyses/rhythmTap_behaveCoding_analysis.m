%analysis list for rhythmic tapping

dateStr = strrep(date,'-','');

globals = rhythmTap_globals; 

%store form defs in a more easily accessed variable
form_defs = globals.ensemble.form_defs;


if (~exist('an','var'))
  load /data2/rhythm/rhythmic_tapping_v2/project_data/rhythmTap_processedData_3-May-2007
end

% Create an array of analysis structures
%clear an;
na = 0;

na=na+1;
an{na}.name = 'ensemble_load_expinfo';
an{na}.fun  = @ensemble_load_expinfo;
an{na}.params.ensemble.experiment_title='rhythmic_tapping_v2';
an{na}.params.ensemble.remove_incomplete_sessions = 1;
an{na}.params.filt = globals.ensemble.filt;
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;

%STIM/RESP PARSING

na=na+1;
an{na}.name = 'ensemble_session_x_trial_info';
an{na}.fun  = @ensemble_session_trial_info;
an{na}.params.verbose = 1;
an{na}.params.ignoreMatchedEventForSub = {{'03yus88141', ...
		    '05vsb78121','11orj72111'},{[1 2],[1:23],[1:5]}};
an{na}.params.ignoreParsedStimAudioForSub = {{'03yus88141'},{[2]}};
an{na}.params.parse_audio_stims.clip_pad_sec = 0;
an{na}.params.parse_audio_stims.detect_cues = 1;
an{na}.params.parse_audio_stims.throw_out_bad_cues = 0;
an{na}.params.parse_audio_stims.save_wvf = 0;
an{na}.params.parse_audio_stims.run_xcorr = 1;
an{na}.params.parse_audio_stims.xcorr_fail_delete = 1;
an{na}.params.parse_audio_stims.xcorr_channels = 1;
an{na}.params.parse_audio_stims.mysql_conn_id = globals.ensemble.conn_id;
an{na}.params.parse_audio_stims.path =  globals.paths.stim_recording_path;

an{na}.params.parse_audio_stims.filename = 'stim_rec_<subject_id>_<session_id>.L.wav';
an{na}.params.parse_midi_resps.filename = 'midi_resp_<subject_id>_<session_id>.mid';
an{na}.params.parse_midi_resps.path = globals.paths.resp_midi_path;		    
an{na}.requires = {struct('name','ensemble_load_expinfo','vars', ...
			  'response_data'),struct('name','ensemble_load_expinfo','vars','session_info')};

na=na+1;
an{na}.name = 'behavioral_coding_analysis';
an{na}.fun  = @behaviorCodingAnalysis;
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;
an{na}.params.perform = {'load_behaviors'};% {'parse_behaviors','save_behaviors'}; %
an{na}.params.behaveTable_fname = 'behaveTable_12Aug2009.mat';
an{na}.params.behaveTable_path = '/data2/rhythm/rhythmic_tapping_v2/project_data';
an{na}.params.behave_parser.behaveCodingPath = '/afs/cmb.ucdavis.edu/share/petrlab/rhythmic_tapping/v2/behavioral_coding/observer_codes_5Aug2009';
an{na}.params.behave_parser.setDurations = 1;
an{na}.params.behave_parser.log_fname = fullfile(globals.paths.logpath,['parser_behavioral_coding_errors_' dateStr '.log']);
an{na}.params.outputTextFile = 'behaveCoding_matlabParsed_17Aug2009.txt';
an{na}.params.behave_parser.expect.type = {'numeric'};
an{na}.params.behave_parser.expect.expr = {' <= 35'};
an{na}.params.behave_parser.expect.vars = {'Duration'};
an{na}.params.behave_parser.expect.behaviors = {'hand tapping'};
an{na}.params.outputFormat = 'body_group_by_coder';
an{na}.params.numPracticeTrials = 5;
an{na}.params.timeResolution = 0.1;
an{na}.params.secondTapeStartTrial = {'08bin87131',26};
an{na}.params.ignoreSubs = {'08bin87131','03mxv76151','11orj72111','03yus88141','04nnt88141'};
an{na}.params.audioStartLog = '/afs/cmb.ucdavis.edu/share/petrlab/rhythmic_tapping/v2/behavioral_coding/audio_start_times.txt';
an{na}.requires = {struct('name','ensemble_session_x_trial_info')};

na=na+1;
an{na}.name = 'check_behave_coding';
an{na}.fun  = @checkBehaveCoding;
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;
an{na}.requires = {struct('name','behavioral_coding_analysis')};

jmanParams.run_analyses = [3];
jmanParams.ensemble.conn_id = globals.ensemble.conn_id;
an = ensemble_jobman(an,jmanParams);
