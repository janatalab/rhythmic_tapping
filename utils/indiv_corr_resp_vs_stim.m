function outData = indiv_corr_resp_vs_stim(inData,params)
%
%
%
% 
%

loadPath = fullfile(params.path,params.loadFname);
loadRespRP = load(loadPath);

trialMPP = loadRespRP.meanEnergies;

skipStimIDs = params.skipStimIDs;

%obtain coefficients for butterworth high pass filter
[b,a] = butter(3,.15,'high');

trialMPP.vars = {trialMPP.vars{:} 'corr' 'pval'};
meCols = set_var_col_const(trialMPP.vars);

nTrials = length(trialMPP.data{meCols.meanEnergy});

stimIDList = unique(trialMPP.data{meCols.stimulus_id});
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
  stimMPPList{iStim} = stimMPP;
 
end

for iTrial = 1:nTrials

  thisStimCat = trialMPP.data{meCols.stimulus_category}{iTrial};
  tappingCond = trialMPP.data{meCols.tapping_cond}{iTrial};
  thisStimID = trialMPP.data{meCols.stimulus_id}(iTrial);
  thisTapMPP = trialMPP.data{meCols.meanEnergy}{iTrial};
  if(~ismember(thisStimID,skipStimIDs) && ~strcmp(tappingCond,'no_tap') && any(thisTapMPP))
 
    stimIdx = find(thisStimID == stimIDList);
    stimMPP = stimMPPList{stimIdx};
    
    stimMPP = filtfilt(b,a,stimMPP);
    thisTapMPP = filtfilt(b,a,thisTapMPP);
    
    [c,p] = corr(thisTapMPP,stimMPP);
     
  else
    c = NaN;
    p = NaN;
  end
  
  trialMPP.data{meCols.corr}(iTrial,1) = c;
  trialMPP.data{meCols.pval}(iTrial,1) = p;
 
end

if(params.saveData)  
  fullfpath = fullfile(params.path,params.fname);
  save(fullfpath,'trialMPP');
end


outData = trialMPP;


