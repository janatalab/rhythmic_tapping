%analysis list for rhythmic tapping
globals = rhythmTap_globals; 

dbstop if error

if (~exist('an'))
load (fullfile(globals.paths.datapath,...
	       'rhythmTap_response_rprofile_analysis_21May2008_11:21.mat'));

%for two subjects used in original paper submission
%load (fullfile(globals.paths.datapath,...
%'rhythmTap_response_rprofile_analysis_paper_26Nov2007_8:55.mat'));



end

globals = rhythmTap_globals;

%store form defs in a more easily accessed variable
form_defs = globals.ensemble.form_defs;


% Create an array of analysis structures
%clear an;
na = 0;

na=na+1; %1
an{na}.name = 'ensemble_load_expinfo';
an{na}.fun  = @ensemble_load_expinfo;
an{na}.params.ensemble.experiment_title='rhythmic_tapping_v2';
an{na}.params.ensemble.remove_incomplete_sessions = 1;
an{na}.params.filt = globals.ensemble.filt;
% masking out only one sub for now
%an{na}.params.filt.include.all.subject_id = {'01siz84311'}; %,'07psk87031'}; %{'01cgc83291'} %{'08bin87131'}; %{'07psk87031'};
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;

%STIM/RESP PARSING
na=na+1; %2
an{na}.name = 'session_x_trial_info';
an{na}.fun  = @ensemble_session_trial_info;
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

na=na+1; %3
an{na}.name = 'get_trial_info';
an{na}.fun = @getRhythmTapTrialInfo;
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;
an{na}.params.summaryByTrialCond = {}; %{'iso_tap'}; %set this to obtain summary stats bystim ID
an{na}.params.getTappingStats = 1;
an{na}.params.tapping_stats = globals.tapping_stats;
%an{na}.params.tapping_stats.midi = globals.midi;
%an{na}.params.tapping_stats.normalizeByPeakIOI = 1;
%an{na}.params.tapping_stats.ioiMinThresh = 0.050;
%an{na}.params.tapping_stats.ioiHistBinLim = [0 3];
%an{na}.params.tapping_stats.ioiHistBinSize = 0.05;
%an{na}.params.tapping_stats.stdev.range = [0.75 1.25];
an{na}.params.tapping_stats.stdev.nBins = 6;
an{na}.requires = {struct('name','session_x_trial_info'),...
		  struct('name','ensemble_load_expinfo','vars','stimulus_metadata')};

na=na+1; %4
an{na}.name = 'plot_tappingStats_groupByStimID';
an{na}.fun = @plot_tappingStatsArray;
an{na}.params.hand = 'both';
an{na}.params.plot.squeezeLims = 0;
an{na}.params.plot.xlim = [0 3];
an{na}.params.plot.infoBox = {'FWHM','std','varAboutPeak'};
an{na}.params.plot.xlabel = 'ITI (sec)';
an{na}.params.plot.ylabel = 'Number of Occurrences';
an{na}.params.plotFname = 'iso_tap_hists_summed_across_subs';
an{na}.params.savePlots = 1;
an{na}.params.plotPath = fullfile(globals.paths.plot_root,'ioi_hist_summed_by_stim_id');
an{na}.requires = {struct('name','get_trial_info','vars','tappingStats_groupBy_stimulus_id')};

na=na+1; %5
an{na}.name = 'midiResp_rhythm_profiler';
an{na}.fun = @midiResp_rhythm_profiler;
an{na}.params.process = {'loadRP','calcMeans','recalcTappingStats'};
an{na}.params.savePath = globals.paths.resp_rp_path;
an{na}.params.saveCalc = 1;
an{na}.params.nmat2aud.Fs = 100;
an{na}.params.nmat2aud.padStop = 0;
an{na}.params.nmat2aud.ioiThresh = globals.midi.ioiThresh;
an{na}.params.nmat2aud.extractNotes = globals.midi.validMidiNotes;
an{na}.params.nmat2aud.scaleByVelocity = 1;
an{na}.params.tapping_stats = globals.tapping_stats;
an{na}.params.peakFinder.thresh = 0.25;
an{na}.params.ipem_proc = globals.respIPEMParams;
%param for running coherence calc
an{na}.params.ipem_proc.rp.perform.calc = 1;
an{na}.params.ipem_proc.rp.perform.calcTemporalExpect = 1;
an{na}.params.ipem_proc.rp.perform.calcVonMises = 1;
an{na}.params.ipem_proc.rp.perform.calcPhaseCoherence = 1;
an{na}.params.storeIpemProc = {'rp'};
an{na}.requires = {struct('name','get_trial_info','vars','tappingStats_by_trial'),...
		   struct('name','ensemble_load_expinfo','vars','stimulus_metadata')};

na=na+1; %6
an{na}.name = 'plot_resp_rhythm_profile';
an{na}.fun = @plot_resp_rhythm_profile;
an{na} = rmfield(an{na},'params');
an{na}.params.rpPath = globals.paths.resp_rp_path;
an{na}.params.savePlotsBy = 'trial_and_sub';
an{na}.params.exclude.tappingCondition = {'no_tap'};
an{na}.params.tappingConditions = {'iso_tap','free_form_tap'};
%an{na}.params.sessTrialList.filt.include.any.subject_id = {'01siz84311'}; ...
    %,'07psk87031'};%{'01cgc83291'} %{'08bin87131'}; %{'07psk87031'};
an{na}.params.stimulusMetadata.filt.include.all.stimulus_id = [5410]; % [6497];
%the nmat2aud process should be moved to midiResp_rhythm_profiler
%when it is run the next time.
an{na}.params.nmat2aud = globals.midi;
an{na}.params.nmat2aud.scaleByVelocity = 1;
an{na}.params.nmat2aud.Fs = 100;
an{na}.params.nmat2aud.padStop = 2;
an{na}.params.perform = {}; %{'plotMeanEnergy','plotPeakITI_vs_peakReson'};
an{na}.params.plot.peakFinder.thresh = 0.25;
an{na}.params.plot.peakFinder.perform = {};
an{na}.params.plot.peakFinder.lpFreq  = 20;
an{na}.params.plot.freqLegend = 1;
an{na}.params.plot.legendParams.minHz = 1;
an{na}.params.plot.legendParams.maxHz = 5;
an{na}.params.plot.legendParams.numKeys = 8;
%an{na}.params.plot.maxResonFreqPlot = 10;
an{na}.params.plot.inputSigType = 'impulse';
an{na}.params.plot.perform = {'resonEnergy','meanEnergy','stdEnergy','findPeaks','plotMeanEnergy','showInput'};
an{na}.params.plot.colorbar = 1;
an{na}.params.plot.color = 0;
an{na}.params.plot.separatePages = 0;
an{na}.params.plot.savePlot = 1;
an{na}.params.plot.savePath = ...
    fullfile(globals.paths.resp_rp_plotPath,'all_subs_by_stimulus');
an{na}.params.plot.timeTickRes = 2.0;
an{na}.params.plot.xminortick = 'off';
an{na}.params.plot.numResonTicks = 8;
an{na}.requires = {struct('name','get_trial_info','vars','tappingStats_by_trial'),struct('name','ensemble_load_expinfo','vars','stimulus_metadata')};

na=na+1; %7
an{na}.name = 'plot_resp_meanRhythmProfile_byStimID_v2';
an{na}.fun = @plot_resp_meanRhythmProfile_byStimID_v2;
an{na}.params.stimAnalysisMatFile = fullfile(globals.paths.datapath,'rhythmTap_stimulus_rprofile_analysis_27_11:30.mat');
an{na}.params.stimAnMeanRPJob = 'get_stim_meanRhythmProfiles';
an{na}.params.rpPath = globals.paths.resp_rp_path;
%an{na}.params.filename = 'meanEnergies_byTrialSub.mat';
%an{na}.params.peakFinder.thresh = 0.25;
an{na}.params.peakFinder = globals.respIPEMParams.rp.resonatorBank.peakFinder;
an{na}.params.numResonTicks = 8;
an{na}.params.tapping_cond = {{'iso_tap'},{'free_form_tap'}};
an{na}.params.labels = {'iso tap','free form tap'};
an{na}.params.ipem = globals.stimIPEMParams;
%an{na}.params.plot.lineSpec = {'b-','r-','k-'};
an{na}.params.plot.plotStyle = 'fill';
an{na}.params.plot.lineSpec = {[1 0 1],[0 1 0],[0 0 0]};
an{na}.params.plot.plotStd  = [1 1 0];
an{na}.params.plot.numResonTicks = 15;
an{na}.params.savePlot = 1;
an{na}.params.savePath = fullfile(globals.paths.resp_rp_plotPath,'mmp_resp_vs_stim');
an{na}.params.filename = 'mpp_resp_vs_stim_15Jul2009_6p';
an{na}.requires = {struct('name','ensemble_load_expinfo','vars','stimulus_metadata'),struct('name','midiResp_rhythm_profiler','type','mean_energies')};

params.ensemble.conn_id = 7;
params.run_analyses = [7];
an = ensemble_jobman(an,params);
return
