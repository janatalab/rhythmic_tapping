function result = matchRespsToTappingStats(inData,params)
%
% Merges tapping data with Ensemble responses and outputs to a form that can be easily interpreted for statistics
%
% 
% This function takes the result from ensemble_session_trial_info and response
% data from ensemble_load_expinfo. Summary tapping stats are calculated. The
% summary tapping stats and response data are merged to an Ensemble
% data struct that represents all the data for a given trial on a single row.
%
%
% Stefan Tomic, 2007
 
trial_qids = params.trial_qids;
trial_conds = params.trial_conds;

saparams.ensemble = params.ensemble;
stim_attributes = stimAttributes([],saparams);
stim_attributes_cols = set_var_col_const(stim_attributes.vars);

clear searchCrit;
searchCrit.name = 'session_x_trial_info';
tsIdx = ensemble_find_analysis_struct(inData,searchCrit);
tappingDataBySession = inData{tsIdx};
tappingDataBySessionCols = set_var_col_const(tappingDataBySession.vars);

clear searchCrit;
searchCrit.name = 'response_data';
respIdx = ensemble_find_analysis_struct(inData,searchCrit);
respInfo =inData{respIdx};

%filter the respInfo so we get only responses to forms that
%correspond to non-practice trials
respInfo = ensemble_filter(respInfo,params.resps.filt);
respInfoCols = set_var_col_const(respInfo.vars);
%then reorganize the data struct by question/subquest. ID
respByQuestion = ensemble_data_by_question(respInfo,[]);
respByQuestionCols = set_var_col_const(respByQuestion.vars);

%We first need to populate respTap with question/resp info, then go through the trials
%and match them in the proper order for each sesssion
respTap = ensemble_init_data_struct;
respTap.vars = {'session_id','subject_id',respByQuestion.vars{:},'stimulus_id','trial_id','response_order','trial_order','stimulus_category','tapping_condition','tapping_var_about_peak','num_tapping_dist_peaks','tapping_stats'};
respTapCols = set_var_col_const(respTap.vars);
respTap.data = cell(size(respTap.vars));
respTap.type = 'response_x_tapping_stats';
respTap.name = 'response_x_tapping_stats';

respTapReturn = respTap;

%populate respTap with session, trial, and compqid/response info
uniqueSessionIDs = unique(respInfo.data{respInfoCols.session_id});

for iSession = 1:length(uniqueSessionIDs)
  
  thisSessionID = uniqueSessionIDs(iSession);
  
  clear tmpFilt;
  tmpFilt.include.all.session_id = thisSessionID;
  respInfoSession = ensemble_filter(respInfo,tmpFilt);
  
  thisSubjectID = respInfoSession.data{respInfoCols.subject_id}(1);
  [respOrders,rowIdxs]    = unique(respInfoSession.data{respInfoCols.response_order});
  stimulusIDs = respInfoSession.data{respInfoCols.stimulus_id}(rowIdxs);
  trialIDs =  respInfoSession.data{respInfoCols.trial_id}(rowIdxs);
  
  [tf,stimAttIdxs] = ismember(stimulusIDs,stim_attributes.data{stim_attributes_cols.stimulus_id});
  stimCats = stim_attributes.data{stim_attributes_cols.stim_cat}(stimAttIdxs);

  numToAdd = length(respOrders);
  
  respTap.data{respTapCols.session_id}(end+1:end+numToAdd,1) = thisSessionID;
  respTap.data{respTapCols.subject_id}(end+1:end+numToAdd,1) = repmat(thisSubjectID,numToAdd,1);
  respTap.data{respTapCols.stimulus_id}(end+1:end+numToAdd,1) = stimulusIDs;
  respTap.data{respTapCols.trial_id}(end+1:end+numToAdd,1) = trialIDs;
  respTap.data{respTapCols.stimulus_category}(end+1:end+numToAdd,1) = stimCats;
  respTap.data{respTapCols.response_order}(end+1:end+numToAdd,1) = respOrders;
  
  %fill in the missing columns with blanks so that we can still
  %filter this struct using ensemble_filter
  respTap.data{respTapCols.trial_order}(end+1:end+numToAdd,1) ... 
      = repmat(NaN,numToAdd,1);
  respTap.data{respTapCols.tapping_condition}(end+1:end+numToAdd,1) ...
      = cell([numToAdd 1]);
  respTap.data{respTapCols.tapping_var_about_peak}(end+1:end+numToAdd,1) ...
      = cell([numToAdd 1]);
  respTap.data{respTapCols.num_tapping_dist_peaks}(end+1:end+numToAdd,1) ...
      = cell([numToAdd 1]);
  respTap.data{respTapCols.tapping_stats}(end+1:end+numToAdd,1) ...
      = cell([numToAdd 1]);
  
  
  %populate respTap with the question/response info. 
  for iQuestion = 1:length(respByQuestion.data)
  
    compqid_tag = respByQuestion.vars{iQuestion};
  
    new_resps = repmat(NaN,numToAdd,1);
    
    thisQuestionInfo = respByQuestion.data{respByQuestionCols.(compqid_tag)};
    thisQuestionInfoCols = set_var_col_const(thisQuestionInfo.vars);
    
    clear tmpFilt;
    tmpFilt.include.all.session_id = thisSessionID;
    thisSessionQuestions = ensemble_filter(thisQuestionInfo,tmpFilt);
    
    qResponseOrders = thisSessionQuestions.data{thisQuestionInfoCols.response_order};
    [tf,respIdx] = ismember(qResponseOrders,respOrders);
    new_resps(respIdx,1) = thisSessionQuestions.data{thisQuestionInfoCols.response_enum};
    respTap.data{respTapCols.(compqid_tag)}(end+1:end+numToAdd,1) = new_resps;
    
  end
  
  
end




%get all the tapping stats for all the sessions
for iSess = 1:length(tappingDataBySession.data{tappingDataBySessionCols.session_id})
 
  %initialize tappingSummary for each session. This will be used to
  %populate respTapReturn for each subject/session at the end of the
  %outer loop
  tappingSummary = ensemble_init_data_struct;
  tappingSummary.vars = {'subject_id','session_id','stimulus_id', ...
		    'trial_id','trial_order','tapping_condition','tapping_var_about_peak','num_tapping_dist_peaks','tapping_stats'};

  tappingSummaryCols = set_var_col_const(tappingSummary.vars);
  tappingSummary.data = cell(size(tappingSummary.vars));

  thisSubjectID = tappingDataBySession.data{tappingDataBySessionCols.subject_id}{iSess};
  thisSessionID = tappingDataBySession.data{tappingDataBySessionCols.session_id}(iSess);
    
  thisSessTrials = tappingDataBySession.data{tappingDataBySessionCols.trial_info}{iSess};
  thisSessTrialsCols = set_var_col_const(thisSessTrials.vars);
   
  for iTrial = 1:length(thisSessTrials.data{1})
    
    thisStimID = thisSessTrials.data{thisSessTrialsCols.stimulus_id}(iTrial);
    thisTrialID = ...
	thisSessTrials.data{thisSessTrialsCols.trial_id}(iTrial);
    
    trialInfo = mysql_extract_data('table','trial','trial_id', ...
				   thisTrialID,'extract_vars',{'trial_id','question_id'},...
				   'conn_id',params.ensemble.conn_id);
    taskIdx = find(trialInfo{2} == trial_qids);
    thisTappingCondition = trial_conds{taskIdx};
    
    
    midiInfo = thisSessTrials.data{thisSessTrialsCols.midi_resp}{iTrial};
    
    tappingStatsParams = params.tapping_stats;
    
    tapping_stats = tappingStats_v2(midiInfo,tappingStatsParams);
    tapping_stats_cols = set_var_col_const(tapping_stats.vars);
    bothHands_tapping_stats = ...
	tapping_stats.data{tapping_stats_cols.both};
    bothHands_tapping_stats_cols = set_var_col_const(bothHands_tapping_stats.vars);
    
    tapVarAboutPeak = bothHands_tapping_stats.data{bothHands_tapping_stats_cols.var_about_peak};
    tapNumPeaks = bothHands_tapping_stats.data{bothHands_tapping_stats_cols.num_peaks};
    
    tappingSummary.data{tappingSummaryCols.subject_id}{end+1,1} = thisSubjectID;
    tappingSummary.data{tappingSummaryCols.session_id}(end+1,1) = thisSessionID;
    tappingSummary.data{tappingSummaryCols.stimulus_id}(end+1,1) = thisStimID;
    tappingSummary.data{tappingSummaryCols.trial_id}(end+1,1) = thisTrialID;
    tappingSummary.data{tappingSummaryCols.tapping_condition}{end+1,1} = ...
	thisTappingCondition;
    tappingSummary.data{tappingSummaryCols.tapping_var_about_peak}(end+1,1) ...
	= tapVarAboutPeak;
    tappingSummary.data{tappingSummaryCols.num_tapping_dist_peaks}(end+1,1) ...
	= tapNumPeaks;
    tappingSummary.data{tappingSummaryCols.trial_order}(end+1,1) = ...
	iTrial;
    
    %let's save the whole tapping stats struct as well so that we
    %can inspect the data if we see something fishy
    tappingSummary.data{tappingSummaryCols.tapping_stats}{end+1,1} ...
	= tapping_stats;
  end
  
  clear tmpFilt;
  tmpFilt.include.all.subject_id = {thisSubjectID};
  respTapThisSub = ensemble_filter(respTap,tmpFilt);
  
  %now match the info from tappingSummary to respTap based on trial
  %order/resp order
  lowestRespOrder = min(respTapThisSub.data{respTapCols.response_order});
  relativeRespOrders = respTapThisSub.data{respTapCols.response_order} ...
      - lowestRespOrder + 1;
  trialOrders = tappingSummary.data{tappingSummaryCols.trial_order};
  [tf,orderMap] = ismember(relativeRespOrders,trialOrders);
  
  %let's perform a little sanity check on the trialIDs to make sure
  %they match
  if(~all(tappingSummary.data{tappingSummaryCols.trial_id}(orderMap) ...
	  == respTapThisSub.data{respTapCols.trial_id}))
    error(sprintf('Enum responses to tapping trial info for subject %s, session %d did not match. Aborting...\n\n',...
		  thisSubjectID,thisSessionID));
  end
  
 
  numToAdd = length(respTapThisSub.data{1});
  respTapReturn.data{respTapCols.session_id}(end+1:end+numToAdd,1) = respTapThisSub.data{respTapCols.session_id};
  respTapReturn.data{respTapCols.subject_id}(end+1:end+numToAdd,1) = respTapThisSub.data{respTapCols.subject_id};
   respTapReturn.data{respTapCols.stimulus_id}(end+1:end+numToAdd,1) = respTapThisSub.data{respTapCols.stimulus_id};
  respTapReturn.data{respTapCols.trial_id}(end+1:end+numToAdd,1) = respTapThisSub.data{respTapCols.trial_id};
  respTapReturn.data{respTapCols.response_order}(end+1:end+numToAdd,1) ...
      = respTapThisSub.data{respTapCols.response_order};
  respTapReturn.data{respTapCols.trial_order}(end+1:end+numToAdd,1) ...
      = relativeRespOrders; 
  respTapReturn.data{respTapCols.stimulus_category}(end+1:end+numToAdd,1) ...
      = respTapThisSub.data{respTapCols.stimulus_category};      
  respTapReturn.data{respTapCols.tapping_condition}(end+1:end+numToAdd,1) ...
      = tappingSummary.data{tappingSummaryCols.tapping_condition}(orderMap);
  
  %copy the responses
  for iQuestion = 1:length(respByQuestion.vars)
      compqid_tag = respByQuestion.vars{iQuestion};
      respTapReturn.data{respTapCols.(compqid_tag)}(end+1:end+numToAdd,1) ...
	  = respTapThisSub.data{respTapCols.(compqid_tag)};
  end
  
  
  respTapReturn.data{respTapCols.tapping_var_about_peak}(end+1:end+numToAdd,1) ...
      = tappingSummary.data{tappingSummaryCols.tapping_var_about_peak}(orderMap);
  respTapReturn.data{respTapCols.num_tapping_dist_peaks}(end+1:end+numToAdd,1) ...
      = tappingSummary.data{tappingSummaryCols.num_tapping_dist_peaks}(orderMap);
  respTapReturn.data{respTapCols.tapping_stats}(end+1:end+numToAdd,1) ...
      = tappingSummary.data{tappingSummaryCols.tapping_stats}(orderMap);
    
end

result = respTapReturn;




return
