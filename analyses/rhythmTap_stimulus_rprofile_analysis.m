%this analysis stream calculates, saves, and plots rhythm profiles of
%all stimuli used in the rhythmic_tapping experiment. A
%stimulus/response parsing job is included in the stream so that
%tapping data plots can be overlayed onto the stimulus rhythm profiles.
%A cleaner solution for the tapping data would be to have a single
%job perform the parsing and save the data to a standard location
%where it can be retrieved.
%
% May, 2007 - Stefan Tomic

globals = rhythmTap_globals; 

if(~exist('an','var'))
  load(fullfile(globals.paths.datapath,'rhythmTap_stimulus_rprofile_analysis_18July2007_00:41.mat'),'an');
end

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
an{na}.params.filt.include.all.stimulus_id = [1933]; %[5410];
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;

na=na+1;
an{na}.params.verbose = 1;
an{na}.name = 'rhythm profiler';
an{na}.fun = @ipem_proc_series;
an{na}.params = globals.stimIPEMParams;
an{na}.params.glob.force_recalc = {'ani','rp'};
an{na}.params.glob.save_calc = {}; %not saving any
                                             %calculations for now
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;
an{na}.requires = {struct('name','ensemble_load_expinfo','vars','stimulus_metadata')};

%STIM/RESP PARSING
na=na+1;
an{na}.name = 'session_x_trial_info';
an{na}.fun  = @ensemble_session_trial_info;
an{na}.params.verbose = 1;
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
	
na=na+1;
an{na}.name = 'plot_stim_rhythm_profile';
an{na}.fun = @plot_stim_rhythm_profile;
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;
an{na}.params.stimAttributes.filt.include.all.name = {'real_music_low_groove','real_music_mid_groove','real_music_high_groove'};
an{na}.params.stimAttributes.filt.exclude.any.stimulus_id = globals.ensemble.silence_stim_id;
%an{na}.params.getTrialsParams.plotTappingConditions = {'iso_tap','free_form_tap'};
an{na}.params.getTrialsParams.plotTappingConditions = {'iso_tap'};
an{na}.params.process = {}; %{'trialSig'};
an{na}.params.stims.filt.exclude.any.stimulus_id = globals.ensemble.silence_stim_id;
%an{na}.params.stims.filt.include.any.stimulus_id = [5886 6251 6371 6247 6250 3];
an{na}.params.stims.filt.include.any.stimulus_id = [1933];%[5410 8 5410 6403]; %[8];
an{na}.params.separatePlotFiles = 1;
an{na}.params.nmat2aud.Fs = 44100;
an{na}.params.nmat2aud.padStop = 2;
an{na}.params.nmat2aud.ioiThresh = globals.midi.ioiThresh;
an{na}.params.ipem = globals.stimIPEMParams;
an{na}.params.ipem.glob.force_recalc = {};
an{na}.params.plot.freqLegend = 1;
an{na}.params.plot.legendParams.minHz = 1;
an{na}.params.plot.legendParams.maxHz = 5;
an{na}.params.plot.legendParams.numKeys = 8;
an{na}.params.plot.overlayType = 'impulse';
an{na}.params.plot.colorbar = 1;
an{na}.params.plot.savePath = globals.paths.stim_rp_plotPath;
an{na}.params.plot.color = 0;
an{na}.params.plot.timeLim = [0 20];
an{na}.params.plot.timeTickRes = 2.0;
an{na}.params.plot.numResonTicks = 15;
an{na}.params.plot.fig.rectPlotWidth = 0.48;
an{na}.params.plot.peakFinder = an{2}.params.rp.resonatorBank.peakFinder;
an{na}.params.plot.perform = {'plotBandOutputs','plotBandEnergies','resonEnergy','meanEnergy','stdEnergy','findPeaks'};
%an{na}.params.plot.perform = {'plotBandOutputs','resonEnergy','meanEnergy','stdEnergy','findPeaks','showInput','ratioProb'};

an{na}.params.plot.inputSigType = 'impulse';
an{na}.params.plot.separatePages = 1;
an{na}.params.separateStimIDPages = 1;
an{na}.params.plot.savePlot = 1;
an{na}.params.plot.plotFname = 'orig_beta_response.ps';
an{na}.requires = {struct('name','ensemble_load_expinfo','vars','stimulus_metadata'),struct('name','ensemble_load_expinfo','vars','stimulus_x_attribute_metadata'),struct('name','session_x_trial_info')};

na=na+1;
an{na}.name = 'get_stim_meanRhythmProfiles';
an{na}.fun = @get_stim_meanRhythmProfiles;
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;
an{na}.params.stimAttributes.filt.include.all.name = {'real_music_low_groove','real_music_mid_groove','real_music_high_groove'};
an{na}.params.stimAttributes.filt.exclude.any.stimulus_id = globals.ensemble.silence_stim_id;
an{na}.params.getTrialsParams.plotTappingConditions = {'iso_tap','free_form_tap'};
an{na}.params.stims.filt.exclude.any.stimulus_id = globals.ensemble.silence_stim_id;
an{na}.params.nmat2aud.Fs = 44100;
an{na}.params.nmat2aud.padStop = 2;
an{na}.params.nmat2aud.ioiThresh = globals.midi.ioiThresh;
an{na}.params.ipem.glob = an{2}.params.glob;
an{na}.params.ipem.ani  = an{2}.params.ani;
an{na}.params.ipem.rp   = an{2}.params.rp;
an{na}.params.peakFinder.thresh = 0.25;
an{na}.requires = {struct('name','ensemble_load_expinfo','vars','stimulus_metadata'),struct('name','ensemble_load_expinfo','vars','stimulus_x_attribute_metadata'),struct('name','session_x_trial_info')};

na=na+1;
an{na}.name = 'plot_stimRPMovieFrames';
an{na}.fun = @ensemble_processStims
an{na}.params.filt.exclude.any.stimulus_id = globals.ensemble.silence_stim_id;
%an{na}.params.filt.include.any.stimulus_id = [3 5886 6247 6250 6251 6371];
an{na}.params.funcName = 'plot_stimRPMovieFrames';
an{na}.params.funcParams.ipem.glob = an{2}.params.glob;
an{na}.params.funcParams.ipem.ani = an{2}.params.ani;
an{na}.params.funcParams.ipem.rp = an{2}.params.rp;
an{na}.params.funcParams.movieRootPath = ...
    fullfile(globals.paths.local_plot_root,'movies','rpEnergy_playHead_tappingData');
an{na}.params.funcParams.ensemble.conn_id = ...
    globals.ensemble.conn_id;
an{na}.params.funcParams.nmat2aud.Fs = 44100;
an{na}.params.funcParams.nmat2aud.padStop = 0;
an{na}.params.funcParams.nmat2aud.ioiThresh = globals.midi.ioiThresh;
an{na}.params.funcParams.nmat2aud.extractNotes = globals.midi.validMidiNotes;
an{na}.params.funcParams.process = {'tapdata'};
an{na}.params.funcParams.tappingConditions = {'iso_tap'};
an{na}.params.funcParams.plot.frameFmt = 'jpeg';
an{na}.params.funcParams.plot.fps = 15;
an{na}.params.funcParams.plot.lineWidth = 3;
an{na}.params.funcParams.plot.numResonTicks = 8;
an{na}.params.funcParams.plot.savePlot = 1;
an{na}.requires = {struct('name','ensemble_load_expinfo','vars','stimulus_metadata'),struct('name','ensemble_load_expinfo','vars','stimulus_x_attribute_metadata'),struct('name','session_x_trial_info')};




params.ensemble.conn_id = 7;
params.run_analyses = [2];
an = ensemble_jobman(an,params);
return
