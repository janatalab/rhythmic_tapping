function trialList = filtSessTrials(inData,params)
%
% trialList = getTrialsForStim(sessTrialInfo,params)
%
% accepts a session_x_trial_info struct, returned from
% ensemble_session_x_trial_info, and finds all the trials from all
% the sessions that fit the parameters of the filter spec, 
% specified in params.filt

clear searchCrit;
searchCrit.type = 'session_x_trial_info';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
sessTrialInfo = inData{findIdx};
sessTrialInfoCols = set_var_col_const(sessTrialInfo.vars);

clear searchCrit;
searchCrit.type = 'stimulus_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimMetaData = inData{findIdx};
stimMetaDataCols = set_var_col_const(stimMetaData.vars);

clear searchCrit;
searchCrit.type = 'stimulus_x_attribute_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimAttMetaData  = inData{findIdx};
stimMetaDataCols = set_var_col_const(stimMetaData.vars);


%make sure we have trial info (tapping task and stimulus category
%info) for the session/trial struct. If not, obtain the info
trialVars =  sessTrialInfo.data{sessTrialInfoCols.trial_info}{1}.vars;
if(~ismember('stimulus_category',trialVars) | ~ismember('tapping_condition',trialVars))
  params.sessTrialInfo.ensemble = params.ensemble;
  grtData{1} = sessTrialInfo;
  grtData{2} = stimMetaData;
  tInfo = getRhythmTapTrialInfo(grtData,params.sessTrialInfo);
  tInfoCols = set_var_col_const(tInfo.vars);
  %replace sessTrialInfo with version populated with stim cat. and
  %tapping cond.
  sessTrialInfo = tInfo.data{tInfoCols.tappingStats_by_trial};
end

nSess = length(sessTrialInfo.data{sessTrialInfoCols.session_id});

trialList = ensemble_init_data_struct;
trialList.type = 'filtered_trial_list';
trialList.vars = sessTrialInfo.data{sessTrialInfoCols.trial_info}{1}.vars;
trialList.data = cell(size(trialList.vars));

for iSess = 1:nSess
  
  trialInfo = sessTrialInfo.data{sessTrialInfoCols.trial_info}{iSess};
  trialInfoCols = set_var_col_const(trialInfo.vars);
  
  trialInfoThisSess = ensemble_filter(trialInfo,params.filt);
  
  if(length(trialInfoThisSess.data{trialInfoCols.trial_id}) ~= 0)
    for iData = 1:length(trialInfoThisSess.data)
      trialList.data{iData}(end+1,1) = trialInfoThisSess.data{iData}(1);
    end
  end
  
end

%retrieve only the tapping conditions we want to plot, while
%ordering them by tapping condition
%tapCondTypes = params.tappingConditions;
%for iTapCond = 1:length(tapCondTypes)
%  clear tmpFilt;
%  tmpFilt.include.all.tapping_condition = tapCondTypes(iTapCond);
%  trialListByCond{iTapCond} = ensemble_filter(trialList,tmpFilt);
%end

%trialList = trialListByCond;

return
