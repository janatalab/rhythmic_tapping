% analyze_experiment.m
%
% Currently for rhythmic tapping experiment.
% attempting to generalize script so that it can be
% easily edited for all experiments
%
%
%
% Assumes data are in the experiment database on atonal.ucdavis.edu
% 08/19/05 Petr Janata -- started script
% 12/06 modified for rhythmic_tapping experiment


params_rhythmic_tapping;

dbclear all
dbstop if error
%dbstop in graph_ioiHistByTrialSetGrid at 41
%dbstop in parse_audio_clips at 334  
%dbstop in graph_ioiHistByTrialSetGrid at 55
%dbstop in tappingStats at 38 if isempty(nmat)
%dbstop in parse_audio_clips at 355 if xcorr_did_not_pass
%dbstop in tappingStats at 23 if (params.IOIScaleFactor == 0)
%dbstop in plot_summaryIOIHistByTrialType at 84
%dbstop in tappingStats at 9
%dbstop in calc_ani at 38
%dbstop in graph_ioiHistByTrialSet at 128
%dbstop in fullWidthHalfMax at 27
%dbstop in varTest2_summaryReport at 12
%dbstop in ioiVarTest2 at 22
%dbstop in plot_summaryIOIHistByTrialType at 134
%dbstop in analyze_rhythmic_tapping_v2 at 414
% Connect to host

if LOAD_PROJECT
  load (fullfile(project_path,'project_data',data2load));
end




mysql_make_conn('','',CONN_ID);

if READ_EXPINFO
  % Get some basic information about the data that are available, such as the
  % number of subjects run and the number of different script versions
  
  trials_by_type = get_rt_trials_by_type;
  
  expinfo = mysql_get_expinfo(expname,'','',CONN_ID);
  experiment_subs = expinfo.subs.ids;
  
  % Remove subjects on exclusion list
  if ~isempty(exclude_subs)
    [proc_subs,proc_sub_idxs] = setdiff(experiment_subs,exclude_subs);
    proc_subs = proc_subs';
  else 
    proc_subs = experiment_subs;
  end
  nsub_proc = length(proc_subs);
  
  % Extract the response table
  fprintf('Extracting data from response table: %s\n', expinfo.resp_table);
  fdata = extract_resp_table_w_trials(expname,expinfo.resp_table,proc_subs,CONN_ID);
                %fdata contains all response table records. The form_names
                %field is a cell array that contains each of the form names
		%form_data field is a cell array that contains response
                %records. Each cell in form_data corresponds to a form.
                 
  
end % if READ_EXPINFO


if PREPROCESS
  
  %sort the list of trial ids into a cell array of the same
  %dimensions as graph_ioi_trialTypes
  for irow = 1:size(graph_ioi_trialTypes,1)
    for icol = 1:size(graph_ioi_trialTypes,2)
      
      trialSets{irow,icol} = getfield(trials_by_type,graph_ioi_trialTypes{irow,icol});
      
    end  
  end
 
end



if ANALYSIS_LIST

  rhythmTap_analysis_list;
  
end


if STORE_STIMLIST_INFO

  %need to find a cleaner way of getting stim list from here in the future
  stimIDs = an{1}.results{5}.data{1};
  for iStim = 1:length(stimIDs)
    stimList(iStim) = init_event;
    stimList{iStim}.data = init_stim('stim_id',stimIDs(iStim));
    pa = params_aud('stim_id',stimIDs(iStim));
    stimList{iStim}.data{1}.data = new_aud(pa);
    
    durSamples = size(stimList{iStim}.data{1}.data{1}.wvf,2);
    thisFs = stimList{iStim}.data{1}.data{1}.Fs;
    stimDurSec = durSamples./thisFs;
    
    stimList{iStim}.data{1}.dur = stimDurSec;
  end

end

if SAVE_PROJECT
  
  save_project_vars;
  
end



if PARSE_STIM_RECORDING

  
  sess_idx = 1;
  

  for isub = 1:nsub_proc
 

    clear events;
      
    sql_sub_sess = ['select session_id from session left join experiment ' ...
		       ' using (experiment_id) where ' ...
	               sprintf('subject_id = ''%s'' and session.experiment_id= %d',char(proc_subs(isub)),expinfo.expid)];
    sub_sess = mysql(CONN_ID,sql_sub_sess);
    
    for isess = 1:length(sub_sess)
    

      sql_get_trial_info = [ sprintf('select stimulus_id,trial_id from %s where ',expinfo.resp_table) ...
			sprintf('subject_id = ''%s'' and session_id =%d ',char(proc_subs(isub)),sub_sess(isess)) ...
			'and stimulus_id is not null ' ...
			'group by stimulus_id, response_order order by response_order'];
    
      [sub_stim_ids,sub_trial_ids] = mysql(CONN_ID,sql_get_trial_info);
    
      for istim = 1:length(sub_stim_ids) 
	stim_struct = init_stim('stim_id',sub_stim_ids(istim),'trial_id',sub_trial_ids(istim));
	events(istim) = init_event('data',stim_struct);
      end  

      sess(sess_idx) = init_session('experiment_id',expinfo.expid,'subject_id',char(proc_subs(isub)),'session_id',sub_sess(isess),'data',events);

      name_tag = [char(proc_subs(isub)) '_' sprintf('%d',sub_sess(isess))];
    
      spp.path = fullfile(project_root,'dp_stimuli');
      spp.filename = ['stim_rec_' name_tag '.L.wav'];
      mp.path = fullfile(project_root,'dp_responses');
      mp.filename = ['midi_resp_' name_tag  '.mid'];

      disp(['Checking locations of stimuli and response recordings' ...
	    ' in filesystem...']);
      
      %if there were anomalies in the recording, this handles
      %ignoring certain events/parsed audio clips
      [hasEventExclusions,ignoreCellIdx] = ismember(char(proc_subs(isub)),ignoreMatchedEventForSub{1});
      if(ignoreCellIdx ~= 0)
	spp.ignoreEventIdxs = ...
	    ignoreMatchedEventForSub{2}{ignoreCellIdx};
      end
      
      [hasStimAudioExclusions,ignoreCellIdx] = ismember(char(proc_subs(isub)),ignoreParsedStimAudioForSub{1});
      if(ignoreCellIdx ~= 0)
	spp.ignoreParsedAudioIdxs = ignoreParsedStimAudioForSub{2}{ignoreCellIdx};
      end    
      
      spp = checkFileExistence(spp);
      mp = checkFileExistence(mp);
      
      disp(sprintf('\nParsing stimuli recording for subject %s, session %d\n',char(proc_subs(isub)),sub_sess(isess)));
      %set the correct_input_Fs for each subject
      %this is used to correct the sampling rate of recordings
      %made at 48K which are read in as 44.1K
      if(isfield(spp,'correct_input_Fs'))
	rmfield(spp,'correct_input_Fs'); 
      end
      if(ismember(proc_subs(isub),recorded_at_48K))
	spp.correct_input_Fs = 48000; 
      end
      
      
      [sess{sess_idx}.data,xcorr_result] = parse_audio_clips(sess{sess_idx}.data, spp);
   
      %throw out practice trials
      %this is the first few trials recorded in Ensemble and DP for
      %Rhythmic Tapping
      %Some code was added to deal with anomalies/problems that may
      % have occurred during practice trials (hence a different num of
      % practice trials may have been recorded for the subject)
      [numIsSet,subIdx] = ismember(sess{isess}.subject_id,numPracticeTrials{1});
      if(numIsSet)
	practiceIdxs = 1:numPracticeTrials{2}{subIdx};
      else
	practiceIdxs = 1:defaultNumPracticeTrials;
      end
      sess{sess_idx}.data(practiceIdxs) = [];

      xcorr_result = 1;
      %only parse midi responses if xcorr_result is true (passed) or isempty (in
      %which case it wasn't run)
      if(isempty(xcorr_result) | xcorr_result)
	disp(sprintf('\nParsing midi responses for subject %s, session %d\n',char(proc_subs(isub)),sub_sess(isess)));
	sess{sess_idx}.data = parse_midi_responses(sess{sess_idx}.data,mp);
      end
      
      sess_idx = sess_idx + 1;
    end
  end

  if SAVE_PROJECT
    save_project_vars;
  end
  
end


if CALC_ANI_RESPS
  
  
  %NEED TO REWRITE THIS TO PROCESS RESPS
  
  
  params_m2a.use_unit_impulse = 1;
 
  %for isess = 1:length(sub_sess)
  for isess = 2:2 
    %for ievent = 1: length(sess{isess}.data)
    for ievent = 10:10
	if(strcmp(sess{isess}.data{ievent}.data{1}.type,'midi'))
	  
	  %aud_struct = midi_to_aud(sess{ievent}.data{1}.data{1},params);
	elseif(strcmp(sess{isess}.data{ievent}.data{1}.data{1}.type,'aud'))
	  stim_id = sess{isess}.data{ievent}.data{1}.stim_id;
	  pa = params_aud('stim_id',stim_id);
	  aud_struct = new_aud(pa);
	  p_ani = params_ani('normalize_wav',1,'DownSampleFactor',5);
	  ani = calc_ani(aud_struct{1},p_ani);
	  sess{isess}.data{ievent}.data{1}.data{ANI_IDX} = ani;
	end
      end
    
    end

    if SAVE_PROJECT
      save_project_vars;
    end
    
    
end



if RHYTHM_PROFILER_RESPS
 
  params_rp = params_rhythm_profiler;
  
  for isess = 1:length(sub_sess)
    for ievent = 1: length(sess{isess}.data)
      ani = sess{isess}.data{ievent}.data{1}.data{ANI_IDX};
      rp = rhythm_profiler(ani,params_rp);
      sess{isess}.data{ievent}.data{1}.data{RP_IDX} = rp;
    end
  end
  
  if SAVE_PROJECT
    save_project_vars;
  end
    
end


if TAPPING_STATS
  
  pTappingStats = paramsTappingStats('leftHandMidiNote',60,'rightHandMidiNote',74,'ioiHistBinLim',[0 3],'ioiHistBinSize',.010,'ioiMinThresh',0.050);

  for isess = 1:length(sess)
 
    for ievent = 1:length(sess{isess}.data)
      eventData = sess{isess}.data{ievent}.data{1};
      if(strcmp(eventData.type,'resp'))
	midiStruct = eventData.data{1};
	if(~ismember(eventData.trial_id,trials_by_type.no_tap_music))
	  tappingStatsStruct = tappingStats(midiStruct,pTappingStats);
	  sess{isess}.data{ievent}.data{1}.data{TAPPING_STATS_IDX} = tappingStatsStruct;
	end
      end      
    end
  end
  
  if SAVE_PROJECT
    save_project_vars;
  end
  
  
end


if PLOT_TAPPING_STATS_BY_SUBJECT
   
     
for isess = 1:length(sess)
  
    plotSubDir = 'ioiTrialGridPlots';
    plotpath = fullfile(project_plots_path,plotSubDir);
    
    if(~exist(plotpath,'dir'))
      mkdir(project_plots_path,plotSubDir);
    end
    
  
       
    p_graph_ioiHistByTrialSetGrid = graph_ioiHistByTrialSetGrid_params('trialSetNames',graph_ioi_trialTypes,...
						  'trialSets',trialSets,...
						  'tsIdx',TAPPING_STATS_IDX,...
						  'title',sess{isess}.subject_id,...
						  'graphType','image',...
						  'squeezeLims',0,...
						  'xlabel','IOI',...
						  'ylabel','Trial Number',...
						  'rowLabels',graph_ioi_rowLabels,...
						  'colLabels',graph_ioi_colLabels,...
						  'colorbarLabel','Number of Occurrences',...
						  'save',save_ioi_graph,...
						  'path',plotpath,...
						  'filename',['ioi_' sess{isess}.subject_id]);
    
       
    graph_ioiHistByTrialSetGrid(sess{isess}.data,p_graph_ioiHistByTrialSetGrid);
    


end

if SAVE_PROJECT
  save_project_vars;
end

end

if CALC_ANI_STIMS
 
  %for iStim = 1:length(stimList)
  for iStim = 1:3  
    aud_struct = stimList{iStim}.data{1}.data{1};
    p_ani = params_ani('normalize_wav',1,'DownSampleFactor',5,...
		       'PlotFlag',0,'NumOfChannels',40);
    ani = calc_ani(aud_struct,p_ani);
      
    stimList{iStim}.data{1}.data{ANI_IDX} = ani;
    
    
  end
  
  if SAVE_PROJECT
    save_project_vars;
  end
  
end


if ESTIMATE_STIM_TEMPO
  
  
  
  clear bt_tempo_estimates;
  
  %taking some shortcuts here to get at the data. This will
  %need to be revised in the future.
  stim_id_list = an{1}.results{5}.data{1};
  bt_tempo_estimates(:,1) = stim_id_list;

  nstims = length(stim_id_list);
  tic
  for stim_idx = 1:nstims
    disp(sprintf('Processing stim %d/%d, stimulus ID %d',stim_idx,nstims,stim_id_list(stim_idx)));
    bt_tempo_estimates(stim_idx,2) = bt_estimate_tempo(stim_id_list(stim_idx));
    toc
    
    %periodically save
    if (mod(stim_idx,5) == 0 | stim_idx == nstims)
      save(fullfile(project_root,'stimulus_bt_tempo_estimates'),'bt_tempo_estimates');
    end
    
    
  end
 
  if SAVE_PROJECT
    save_project_vars;
  end
  
  
end

if LOAD_STIM_TEMPO
  
  
  load(fullfile(project_root,'stimulus_bt_tempo_estimates'),'bt_tempo_estimates');
  
   
end


if PLOT_METRIC_LEVELS_BY_TRIALCAT

  summaryReport = {};
  p_plot_summaryIOIHistByTrialType = {};
  ioiGraphUpperLim = 1.25;
  ioiGraphLowerLim = 0.75;
  
  runSummaryReports = [2 3 4 7];
 
  
  free_form_vs_iso ={trials_by_type.free_form_tap ; trials_by_type.iso_tap};
  free_form_vs_iso_names = {'Free Form Tapping' ;  'Iso Tapping'};
  
  setXLim = [ioiGraphLowerLim ioiGraphUpperLim];
  
  
   plotSubDir = 'summaryIOIHistByTrialType';
   plotpath = fullfile(project_plots_path,plotSubDir);
    
   if(~exist(plotpath,'dir'))
     mkdir(project_plots_path,plotSubDir);
   end
   
   
   
   paramFieldNames = {'trialSetNames','trialSets','tsIdx','hand','graphType','xLim','yLim','equalGraphLims','normalize','stimTempo','rowLabels',...
		      'colLabels','infoBox','save','savePath','leftHandMidiNote','rightHandMidiNote',...
		      'IOIScaleFactor','ioiMinThresh', ...
		      'ioiHistBinSize','ioiHistBinLim','graphDescript'};
   

   pTappingStats = {'leftHandMidiNote',60,...
		    'rightHandMidiNote',74,...
		    'ioiHistBinLim',[0 8],...
		    'ioiHistBinSize',.02,...
		    'ioiMinThresh',0.02};	    
   
   %subplot graphs to equalize xlims and ylims
   eqGraphLims = [2 1; 2 2; 3 1; 3 2; 4 1; 4 2];

   
   p_plot_summaryIOIHistByTrialType{end+1} = mkstruct(paramFieldNames,...
					       {'trialSetNames',graph_ioi_trialTypes,...
		                                'trialSets',trialSets,...
					       'tsIdx',TAPPING_STATS_IDX,...
		                               'equalGraphLims',eqGraphLims,...
		                               'graphType','bargraph',...
					       'normalize','peak_ioi',...
					       'stimTempo',bt_tempo_estimates,...
					       'rowLabels',graph_ioi_rowLabels,...
					       'colLabels',graph_ioi_colLabels,...
		                               'infoBox',{'numTrials'},...
					       'save',save_ioi_graph,...
					       'savePath',plotpath,...
		                               pTappingStats{:}});
   
   
   p_plot_summaryIOIHistByTrialType{end+1} = mkstruct(paramFieldNames,...
					       {'trialSetNames',graph_ioi_trialTypes,...
		                                'trialSets',trialSets,...
					       'tsIdx',TAPPING_STATS_IDX,...
		                               'xLim',setXLim,...
		                               'equalGraphLims',eqGraphLims,...
		                               'graphType','bargraph',...
		                               'graphDescript','stim_category_x_task',...
					       'normalize','peak_ioi',...
					       'stimTempo',bt_tempo_estimates,...
					       'rowLabels',graph_ioi_rowLabels,...
					       'colLabels',graph_ioi_colLabels,...
		                               'infoBox',{'numTrials','FWHM','stdDev'},...
					       'save',save_ioi_graph,...
					       'savePath',plotpath,...
		                               pTappingStats{:}});
   
   
   p_plot_summaryIOIHistByTrialType{end+1} = mkstruct(paramFieldNames,...
					       {'trialSetNames',graph_ioi_trialTypes,...
		                                'trialSets',trialSets,...
					       'tsIdx',TAPPING_STATS_IDX,...
		                               'xLim',setXLim,...
		                               'equalGraphLims',eqGraphLims,...
		                               'hand','right',...
		                               'graphType','bargraph',...
		                               'graphDescript','stim_category_x_task',...
					       'normalize','peak_ioi',...
					       'stimTempo',bt_tempo_estimates,...
					       'rowLabels',graph_ioi_rowLabels,...
					       'colLabels',graph_ioi_colLabels,...
		                               'infoBox',{'numTrials','FWHM','stdDev'},...
					       'save',save_ioi_graph,...
					       'savePath',plotpath,...
		                               pTappingStats{:}});
   
    
   p_plot_summaryIOIHistByTrialType{end+1} = mkstruct(paramFieldNames,...
					       {'trialSetNames',graph_ioi_trialTypes,...
		                                'trialSets',trialSets,...
					       'tsIdx',TAPPING_STATS_IDX,...
		                               'xLim',setXLim,...
		                               'equalGraphLims',eqGraphLims,...
		                               'hand','left',...
		                               'graphType','bargraph',...
		                               'graphDescript','stim_category_x_task',...
					       'normalize','peak_ioi',...
					       'stimTempo',bt_tempo_estimates,...
					       'rowLabels',graph_ioi_rowLabels,...
					       'colLabels',graph_ioi_colLabels,...
		                               'infoBox',{'numTrials','FWHM','stdDev'},...
					       'save',save_ioi_graph,...
					       'savePath',plotpath,...
		                               pTappingStats{:}});
   
   
 
   p_plot_summaryIOIHistByTrialType{end+1} = mkstruct(paramFieldNames,...
					       {'trialSetNames',graph_ioi_trialTypes,...
		                                'trialSets',trialSets,...
					       'tsIdx',TAPPING_STATS_IDX,...
                               		       'equalGraphLims',eqGraphLims,...
		                               'hand','right',...
		                               'graphType','bargraph',...
					       'normalize','peak_ioi',...
					       'stimTempo',bt_tempo_estimates,...
					       'rowLabels',graph_ioi_rowLabels,...
					       'colLabels',graph_ioi_colLabels,...
		                               'infoBox',{'numTrials','FWHM','stdDev'},...
					       'save',save_ioi_graph,...
					       'savePath',plotpath,...
		                               pTappingStats{:}});
   
    
   p_plot_summaryIOIHistByTrialType{end+1} = mkstruct(paramFieldNames,...
					       {'trialSetNames',graph_ioi_trialTypes,...
		                                'trialSets',trialSets,...
					       'tsIdx',TAPPING_STATS_IDX,...
    		                               'equalGraphLims',eqGraphLims,...
		                               'hand','left',...
		                               'graphType','bargraph',...
					       'normalize','peak_ioi',...
					       'stimTempo',bt_tempo_estimates,...
					       'rowLabels',graph_ioi_rowLabels,...
					       'colLabels',graph_ioi_colLabels,...
		                               'infoBox',{'numTrials','FWHM','stdDev'},...
					       'save',save_ioi_graph,...
					       'savePath',plotpath,...
		                               pTappingStats{:}});
   
    
   p_plot_summaryIOIHistByTrialType{end+1} = mkstruct(paramFieldNames,...
					       {'trialSetNames',free_form_vs_iso_names,...
		                                'trialSets',free_form_vs_iso,...
					        'tsIdx',TAPPING_STATS_IDX,...
		                                'xLim',setXLim,...
    		                                'equalGraphLims',eqGraphLims,...
                                		'graphType','bargraph',...
		                                'graphDescript','free_form_vs_iso',...
					        'normalize','peak_ioi',...
					        'stimTempo',bt_tempo_estimates,...
					        'rowLabels',free_form_vs_iso_names,...
					        'colLabels',{'All Music and Silence'},...
		                                'infoBox',{'numTrials','FWHM','stdDev'},...
					        'save',save_ioi_graph,...
					        'savePath',plotpath,...
		                                pTappingStats{:}});
   
   
   for ireport = runSummaryReports
     summaryReport{end+1}.data = plot_summaryIOIHistByTrialType(sess,p_plot_summaryIOIHistByTrialType{ireport});
   end
 
 
    
   if SAVE_PROJECT
     save_project_vars;
   end
   
end



if VARTEST_SUMMARYREPORT
  
  %NEED TO CLEAN UP UPPER LIM AND LOWER LIM 
  %VALUES ARE HARDCODED
  p_vt.upperLim = ioiGraphUpperLim + 0.01;
  p_vt.lowerLim = ioiGraphLowerLim - 0.01;
  p_vt.rows = varTest_rowLabels;
  p_vt.cols = varTest_colLabels;
  
  for ireport = 1:3
    summaryReport{ireport} = varTest2_summaryReport(summaryReport{ireport},p_vt);
    summaryReport{ireport} = varTestN_summaryReport(summaryReport{ireport},p_vt);
  end
  
  
  ireport = 4;
  p_vt.rows = {' Free Form Tapping ',' Iso Tapping '};
  p_vt.cols = {' All Silence and Music'};
  summaryReport{ireport} = varTest2_summaryReport(summaryReport{ireport},p_vt);
    
  if SAVE_PROJECT
    save_project_vars;
  end

end
