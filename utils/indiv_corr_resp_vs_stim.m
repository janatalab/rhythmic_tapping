function outData = indiv_corr_resp_vs_stim(inData,params)
%
% correlates the tapping MPP of each individual trial with the corresponding stimulus MPP
% returns a correlation value and p value for each trial.
%
% Also loads the tappingSummary data struct (saved from
% midiResp_rhythm_profiler), tags the correlation value for each trial onto
% this struct, and saves the resulting struct back to the same path.

loadPath = fullfile(params.path,params.loadFname);
loadRespRP = load(loadPath);

tappingSummary = loadRespRP.tappingSummary;

skipStimIDs = params.skipStimIDs;

%obtain coefficients for butterworth high pass filter
[b,a] = butter(3,.15,'high');

tappingSummary.vars = {tappingSummary.vars{:} 'corr' 'pval'};
meCols = set_var_col_const(tappingSummary.vars);

nTrials = length(tappingSummary.data{meCols.meanEnergy});

stimIDList = unique(tappingSummary.data{meCols.stimulus_id});
stimIDList = setdiff(stimIDList,skipStimIDs);
nStims = length(stimIDList);


%load all stim MPPs

for iStim = 1:nStims
 
  stimID = stimIDList(iStim);
  stimIPEMOut = ipem_proc_series(stimID,params.ipem);
  stimIPEMOutCols = set_var_col_const(stimIPEMOut.vars);
  thisStimRP = stimIPEMOut.data{stimIPEMOutCols.rp};
    
  if(iscell(thisStimRP))
    thisStimRP = thisStimRP{1};
  end
  stimRPCols = set_var_col_const(thisStimRP.vars);
  stimMPP = thisStimRP.data{stimRPCols.meanResonatorEnergy};
  
  % Filter the stimMPP now. No need to do it multiple times later.
  stimMPP = filtfilt(b,a,stimMPP);
  
  stimMPPList{iStim} = stimMPP;
 
end

for iTrial = 1:nTrials

  thisStimCat = tappingSummary.data{meCols.stimulus_category}{iTrial};
  tappingCond = tappingSummary.data{meCols.tapping_cond}{iTrial};
  thisStimID = tappingSummary.data{meCols.stimulus_id}(iTrial);
  thisTapMPP = tappingSummary.data{meCols.meanEnergy}{iTrial};
  if(~ismember(thisStimID,skipStimIDs) && ~strcmp(tappingCond,'no_tap') && any(thisTapMPP))
 
    stimIdx = find(thisStimID == stimIDList);
    stimMPP = stimMPPList{stimIdx};
    
    thisTapMPP = filtfilt(b,a,thisTapMPP);
    
    [c,p] = corr(thisTapMPP,stimMPP);
     
  else
    c = NaN;
    p = NaN;
  end
  
  tappingSummary.data{meCols.corr}(iTrial,1) = c;
  tappingSummary.data{meCols.pval}(iTrial,1) = p;
 
end

if(params.saveData)  
  fullfpath = fullfile(params.path,params.fname);
  save(fullfpath,'tappingSummary','params');
end


outData = tappingSummary;


