%analysis list for rhythmic tapping


globals = rhythmTap_globals; 

%store form defs in a more easily accessed variable
form_defs = globals.ensemble.form_defs;


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
an{na}.name = 'session_x_trial_info';
an{na}.fun  = @ensemble_session_trial_info;
an{na}.params.verbose = 1;
an{na}.params.verbose = 1;
an{na}.params.ignoreMatchedEventForSub = {{'03yus88141', ...
		    '05vsb78121','11orj72111'},{[1 2],[1:23],[1:5]}};
an{na}.params.ignoreParsedStimAudioForSub = {{'03yus88141'},{[2]}};
an{na}.params.numPracticeTrials = 5;
an{na}.params.parse_audio_stims.clip_pad_sec = 0;
an{na}.params.parse_audio_stims.detect_cues = 1;
an{na}.params.parse_audio_stims.throw_out_bad_cues = 0;
an{na}.params.parse_audio_stims.save_wvf = 0;
an{na}.params.parse_audio_stims.run_xcorr = 1;
an{na}.params.parse_audio_stims.xcorr_fail_delete = 1;
an{na}.params.parse_audio_stims.xcorr_channels = 1;
an{na}.params.parse_audio_stims.mysql_conn_id = globals.ensemble.conn_id;
an{na}.params.parse_audio_stims.path = globals.paths.stim_recording_path;
an{na}.params.parse_audio_stims.filename = 'stim_rec_<subject_id>_<session_id>.L.wav';
an{na}.params.parse_midi_resps.filename = 'midi_resp_<subject_id>_<session_id>.mid';
an{na}.params.parse_midi_resps.path = globals.paths.resp_midi_path;		    
an{na}.requires = {struct('name','ensemble_load_expinfo','vars', ...
			  'response_data'),struct('name','ensemble_load_expinfo','vars','session_info')};

%tapping stat analysis/resp matching
na=na+1;
an{na}.name = 'match_resps_to_tapping';
an{na}.fun = @matchRespsToTappingStats;
an{na}.requires = {struct('name','ensemble_load_expinfo','vars', ...
			  'response_data'),struct('name','session_x_trial_info')};
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;
an{na}.params.trial_qids = [602 604 476 603 605];
an{na}.params.trial_conds = {'free_form_tap','free_form_tap', ...
		    'no_tap','iso_tap','iso_tap'};
%include only forms that belong to non-practice trials
an{na}.params.resps.filt.include.all.form_order = [23:28];
an{na}.params.resps.filt.include.all.form_id = ...
    [form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_FREE_FORM_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_SILENCE_FREE_FORM_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_ISO_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_SILENCE_ISO_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_NOTAP_EVAL_V2];
an{na}.params.tapping_stats.midi = globals.midi;
an{na}.params.tapping_stats.normalizeByPeakIOI = 1;
an{na}.params.tapping_stats.ioiMinThresh = 0.050;
an{na}.params.tapping_stats.ioiHistBinLim = [0 3];
an{na}.params.tapping_stats.ioiHistBinSize = 0.05;
an{na}.params.tapping_stats.stdev.range = [0.75 1.25];

params.ensemble.conn_id = 7;
params.run_analyses = [3];
an = ensemble_jobman(an,params);
return
