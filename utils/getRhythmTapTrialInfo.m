function outData = getRhythmTapTrialInfo(inData,params)
%
% Obtains rhythmic tapping info for each trial in a session x trial struct.
% The stim categories (low,mid, and high groove) as well as the
% tapping task are obtained for each trial and stored in each trial struct
% Additionally, if tapping stats are desired (ioi histograms,
% etc.), this can be returned as well by setting
% params.getTappingStats, and setting the proper parameters in
% subfields of params.tapping_stats

clear anSearchCrit;
anSearchCrit.name = 'session_x_trial_info';
anListIdx = ensemble_find_analysis_struct(inData,anSearchCrit);
sessTrialInfo = inData{anListIdx};
sessTrialInfoCols = set_var_col_const(sessTrialInfo.vars);

clear anSearchCrit;
anSearchCrit.name = 'stimulus_metadata';
anListIdx = ensemble_find_analysis_struct(inData,anSearchCrit);
stimMetaData = inData{anListIdx};
stimMetaDataCols = set_var_col_const(stimMetaData.vars);

nmatCols = nmat_columns;


SILENCE_STIM_ID = 6497;

trial_qids = [602 604 476 603 605];
trial_conds = {'free_form_tap','free_form_tap', ...
	       'no_tap','iso_tap','iso_tap'};

%build a stim/groove attribute data struct
lowGrooveAttributeID = mysql_extract_data('table','attribute', ...
					     'name','real_music_low_groove','extract_flds','attribute_id','conn_id',params.ensemble.conn_id);
midGrooveAttributeID = mysql_extract_data('table','attribute', ...
					     'name','real_music_mid_groove','extract_flds','attribute_id','conn_id',params.ensemble.conn_id);
highGrooveAttributeID = mysql_extract_data('table','attribute', ...
					      'name','real_music_high_groove','extract_flds','attribute_id','conn_id',params.ensemble.conn_id);

stimGrooveData = mysql_extract_data('table','stimulus_x_attribute','attribute_id',[lowGrooveAttributeID{1},midGrooveAttributeID{1},highGrooveAttributeID{1}],'conn_id',params.ensemble.conn_id,'extract_flds',{'stimulus_id','attribute_id'});


stimGroove = ensemble_init_data_struct;
stimGroove.vars = {'stimulus_id','groove_rating'};
stimGrooveCols = set_var_col_const(stimGroove.vars);
stimGroove.data{stimGrooveCols.stimulus_id} = ...
    stimGrooveData{1};
stimGroove.data{stimGrooveCols.groove_rating}(stimGrooveData{2} ==  lowGrooveAttributeID{1},1) = {'low_groove'};
stimGroove.data{stimGrooveCols.groove_rating}(stimGrooveData{2} == ...
					       midGrooveAttributeID{1},1) = {'mid_groove'};
stimGroove.data{stimGrooveCols.groove_rating}(stimGrooveData{2} == ...
					       highGrooveAttributeID{1},1) = {'high_groove'};

stimGroove.data{stimGrooveCols.stimulus_id}(end+1) = ...
    SILENCE_STIM_ID;
stimGroove.data{stimGrooveCols.groove_rating}{end+1} = 'silence';

%initialize summaryInfo cell array
if(isfield(params,'summaryByTrialCond'))
  summaryByTrialCond = params.summaryByTrialCond;
  nTotalStims = length(stimMetaData.data{stimMetaDataCols.stimulus_id});
  nTrialConds = length(params.summaryByTrialCond);
  
  stimSummaries = ensemble_init_data_struct;
  stimSummaries.vars = {'stimulus_id'  'artist' 'song_name' 'tapping_stats' ...
		    'tapping_cond' 'stimulus_category' 'nTrials'};
  stimSummaries.data = { [] {} {} {} };
  stimSummariesCols = set_var_col_const(stimSummaries.vars);
  for iTrialCond = 1:nTrialConds
    for iStim = 1:nTotalStims
      idx = (iTrialCond - 1)*nTotalStims + iStim;
      thisStimID = stimMetaData.data{stimMetaDataCols.stimulus_id}(iStim);
      stimSummaries.data{stimSummariesCols.stimulus_id}(idx,1) = thisStimID;
      stimSummaries.data{stimSummariesCols.tapping_stats}{idx,1} = {};
      stimSummaries.data{stimSummariesCols.tapping_cond}{idx,1} = summaryByTrialCond{iTrialCond};
      
      stimGrooveIdx = find(stimGroove.data{stimGrooveCols.stimulus_id}==thisStimID);
      stimSummaries.data{stimSummariesCols.stimulus_category}{idx,1} ...
	  = stimGroove.data{stimGrooveCols.groove_rating}{stimGrooveIdx};

      metaDataIdx = find(stimMetaData.data{stimMetaDataCols.stimulus_id} == thisStimID);
      stimSummaries.data{stimSummariesCols.artist}{idx,1}=...
	  stimMetaData.data{stimMetaDataCols.artist}{metaDataIdx};
      stimSummaries.data{stimSummariesCols.song_name}{idx,1}=...
	  stimMetaData.data{stimMetaDataCols.name}{metaDataIdx};
      stimSummaries.data{stimSummariesCols.nTrials}(idx,1) = 0;
      handTapStats = ensemble_init_data_struct;
      handTapStats.vars = {'ioi' 'ioi_hist' 'hist_bin_size' 'hist_bin_centers' 'var_about_peak'};
      handTapStats.data = cell(size(handTapStats.vars));
      tapStats = ensemble_init_data_struct;
      tapStats.vars = {'params' 'both' 'left' 'right'};
      tapStats.data = {[] handTapStats handTapStats handTapStats};
      stimSummaries.data{stimSummariesCols.tapping_stats}{idx,1} = tapStats;
    end
  end
end

%now assign stimulus attributes and task type to the trials
nSess = length(sessTrialInfo.data{sessTrialInfoCols.session_id});

for iSess = 1:nSess
  
  trialInfoList = sessTrialInfo.data{sessTrialInfoCols.trial_info}{iSess};
  trialInfoList.vars = {trialInfoList.vars{:} 'trial_order' 'stimulus_category' 'tapping_condition'};
  if(isfield(params,'getTappingStats') & params.getTappingStats)
    trialInfoList.vars = {trialInfoList.vars{:} 'tapping_stats'};
  end
  trialInfoListCols = set_var_col_const(trialInfoList.vars);
  
  nTrials = length(trialInfoList.data{trialInfoListCols.trial_id});
  
  for iTrial = 1:nTrials
    
    thisTrialID = trialInfoList.data{trialInfoListCols.trial_id}(iTrial);
    thisStimID =  trialInfoList.data{trialInfoListCols.stimulus_id}(iTrial);
    
    stimCatIdx = find(stimGroove.data{stimGrooveCols.stimulus_id} == thisStimID);
    stimCategory = stimGroove.data{stimGrooveCols.groove_rating}{stimCatIdx};
    
    trialInfo = mysql_extract_data('table','trial','trial_id', ...
				     thisTrialID,'extract_vars',{'trial_id','question_id'},...
				     'conn_id',params.ensemble.conn_id);
    taskIdx = find(trialInfo{2} == trial_qids);
    trialCondition = trial_conds{taskIdx};
    
    trialInfoList.data{trialInfoListCols.trial_order}(iTrial,1) = iTrial;
    
    trialInfoList.data{trialInfoListCols.stimulus_category}{iTrial,1} ...
	= stimCategory;
    trialInfoList.data{trialInfoListCols.tapping_condition}{iTrial,1} ...
	= trialCondition;

    %if params.getTappingStats was set, process it here
    if(isfield(params,'getTappingStats') & params.getTappingStats)
      midiInfo = trialInfoList.data{trialInfoListCols.midi_resp}{iTrial};
      midiInfoCols = set_var_col_const(midiInfo.vars);
      tappingStatsParams = params.tapping_stats;
      tapping_stats = tappingStats_v2(midiInfo,tappingStatsParams);
      trialInfoList.data{trialInfoListCols.tapping_stats}{iTrial,1} = tapping_stats;
    end
      
    if(isfield(params,'summaryByTrialCond'))
      summaryIdx = [];
      if (ismember(trialCondition,summaryByTrialCond))
	  summaryIdx = find(thisStimID ==  stimSummaries.data{stimSummariesCols.stimulus_id} & ...
			    ismember(trialCondition,stimSummaries.data{stimSummariesCols.tapping_cond}));

	  if(~isempty(summaryIdx))
	    stimSummaries.data{stimSummariesCols.tapping_stats}{summaryIdx} = ...
		combineTappingStats(stimSummaries.data{stimSummariesCols.tapping_stats}{summaryIdx},tapping_stats);
	    stimSummaries.data{stimSummariesCols.nTrials}(summaryIdx) ...
		= stimSummaries.data{stimSummariesCols.nTrials}(summaryIdx)+ 1;
	  end
	
      end
    
    end
    
  end
  
  %assign trial list back to sessTrialInfo
  sessTrialInfo.data{sessTrialInfoCols.trial_info}{iSess} = trialInfoList;
  
end

%recalculate var about peak for each of the stimSummaries
if(isfield(params,'summaryByTrialCond'))
  
  tappingStatList =  stimSummaries.data{stimSummariesCols.tapping_stats};
  nStims = length(tappingStatList);
  for iStim = 1:nStims
    thisTs = tappingStatList{iStim};
    tsCols = set_var_col_const(thisTs.vars);
    hands = {'both' 'left' 'right'};
    for iHand = 1:length(hands)
      hand = hands{iHand};
      handStats = thisTs.data{tsCols.(hand)};
      handStatsCols = set_var_col_const(handStats.vars);
      ioiHist = handStats.data{handStatsCols.ioi_hist};
      peakIOIIdx = find(ioiHist == max(ioiHist),1,'first');
      peakIOI = handStats.data{handStatsCols.hist_bin_centers}(peakIOIIdx);
      binSize = handStats.data{handStatsCols.hist_bin_size};
      nBinRange = params.tapping_stats.stdev.nBins;
      varRange = [(peakIOI - nBinRange*binSize/2) (peakIOI + nBinRange*binSize/2)];
      varIOI = handStats.data{handStatsCols.ioi};
      varIOI = varIOI(varIOI >= varRange(1) & varIOI <= varRange(2));
      varAboutPeak = std(varIOI);
      thisTs.data{tsCols.(hand)}.data{handStatsCols.var_about_peak} ...
	  = varAboutPeak;
      thisTs.data{tsCols.params}.stdev.range = varRange;
      stimSummaries.data{stimSummariesCols.tapping_stats}{iStim} = thisTs;
    end
    
    
  end
  
  
  
end


outData = ensemble_init_data_struct;
outData.vars = {'tappingStats_by_trial' 'tappingStats_groupBy_stimulus_id'};
outDataCols = set_var_col_const(outData.vars);
outData.data{outDataCols.tappingStats_by_trial} = sessTrialInfo;

if(isfield(params,'summaryByTrialCond'))
  outData.data{outDataCols.tappingStats_groupBy_stimulus_id} = stimSummaries;
else
  outData.data{outDataCols.tappingStats_groupBy_stimulus_id} = [];
end

return





function newTappingStats = combineTappingStats(tappingStats1,tappingStats2)


tsCols = set_var_col_const(tappingStats1.vars);
newTappingStats = ensemble_init_data_struct;
newTappingStats.vars = tappingStats1.vars;
newTappingStats.data{tsCols.params} = tappingStats2.data{tsCols.params};

for ihand = 1:3
  hands = {'both' 'left' 'right'};
  hand = hands{ihand};
  handStats1 = tappingStats1.data{tsCols.(hand)};
  handStats2 = tappingStats2.data{tsCols.(hand)};
  hsCols = set_var_col_const(handStats1.vars);
  newIOI = [handStats1.data{hsCols.ioi} ; handStats2.data{hsCols.ioi}];

  if(isempty(handStats1.data{hsCols.ioi_hist}))
    newIOIHist = handStats2.data{hsCols.ioi_hist};
  else
    newIOIHist = handStats1.data{hsCols.ioi_hist} + handStats2.data{hsCols.ioi_hist};
  end
  
  newHistBinSize = handStats2.data{hsCols.hist_bin_size};
  newHistBinCenters = handStats2.data{hsCols.hist_bin_centers};
  newHandStats = ensemble_init_data_struct;
  newHandStats.vars = handStats1.vars;
  newHandStats.data{hsCols.ioi} = newIOI;
  newHandStats.data{hsCols.ioi_hist} = newIOIHist;
  newHandStats.data{hsCols.hist_bin_size} = newHistBinSize;
  newHandStats.data{hsCols.hist_bin_centers} = newHistBinCenters;
  
  newTappingStats.data{tsCols.(hand)} = newHandStats;
  
end






return
