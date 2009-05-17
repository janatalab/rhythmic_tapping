function outData = plot_stim_rhythm_profile(inData,params)
%
%
%
%
%
%

ensemble_globals;

if(~isfield(params,'separatePlotFiles'))
  params.separatePlotFiles = 0;
end

[pth,plotFStub,ext] = fileparts(params.plot.plotFname);
plotFile = fullfile(params.plot.savePath,params.plot.plotFname);
bandPlot1 = fullfile(params.plot.savePath,[plotFStub '_bandOutputs' ext]);
bandPlot2 = fullfile(params.plot.savePath,[plotFStub '_bandEnergies' ext]);

if(params.plot.savePlot  & exist(plotFile))
    
  confirmOverwrite = '';
  while(~ismember(confirmOverwrite,{'y','n'}))
    confirmOverwrite = input(sprintf('File %s exists, overwrite? (y/n): ',plotFile),'s');
  end
  
  if(strcmp(confirmOverwrite,'y'))
    delete(plotFile);
    if(exist(bandPlot1,'file'))
      delete(bandPlot1);
    end
    if(exist(bandPlot2,'file'))
      delete(bandPlot2);
    end
  else
      disp('OK, not saving the plot. It will be displayed on the screen.');
  end
  
end
  
stimMetaData = inData{1};
stimMetaDataCols = set_var_col_const(stimMetaData.vars);
stimMetaData = ensemble_filter(stimMetaData,params.stims.filt);

stimAttMetaData = inData{2};
stimAttMetaDataCols = set_var_col_const(stimAttMetaData.vars);
stimAttMetaData = ensemble_filter(stimAttMetaData,params.stimAttributes.filt);

if(isfield(params,'process') && ismember('trialSig',params.process))
  sessTrialInfo = inData{3};
  sessTrialInfoCols = set_var_col_const(sessTrialInfo.vars);

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
end

nStims = length(stimMetaData.data{stimMetaDataCols.stimulus_id});

for iStim = 1:nStims

  thisStimID = ...
      stimMetaData.data{stimMetaDataCols.stimulus_id}(iStim);
  stimAttIdx = find(stimAttMetaData.data{stimAttMetaDataCols.stimulus_id} == thisStimID);
  thisStimCat = stimAttMetaData.data{stimAttMetaDataCols.name}{stimAttIdx};
  
  thisLocation = stimMetaData.data{stimMetaDataCols.location}{iStim};
  [path,fstub,ext] = fileparts(fullfile(stimulus_ipem_analysis_root,thisLocation));
  
  
  ipemProc = ipem_proc_series(thisStimID,params.ipem);
  ipemProcCols = set_var_col_const(ipemProc.vars);
  rp = ipemProc.data{ipemProcCols.rp}{1};
   
  
  if(isfield(params,'process') && ismember('trialSig',params.process))
    params.getTrialsParams.filt.include.all.stimulus_id = thisStimID;
    trialsThisStim = getTrialsForThisStim(sessTrialInfo,params.getTrialsParams);
  
    trialAud = {};
    %trialsThisStim is a cell array, grouped by tapping condition
    %need to process one cell at a time
    for iTrialSet = 1:length(trialsThisStim)
      newTrialAud = trialMidiResp2Aud(trialsThisStim{iTrialSet},params.nmat2aud);
      
      newIdxs = length(trialAud)+1:length(trialAud)+length(newTrialAud);
      params.plot.trialSets(newIdxs,1:2) = [newIdxs' repmat(iTrialSet,length(newIdxs),1)];
      trialAud(end+1:end+length(newTrialAud)) = newTrialAud;
    end
  end
  
  artist_name = stimMetaData.data{stimMetaDataCols.artist}{iStim};
  song_name = stimMetaData.data{stimMetaDataCols.name}{iStim};
  
  if(length(artist_name) > 35)
    song_name = sprintf('\n"%s"',song_name);
  else
    song_name = ['"' song_name '"'];
  end
  
  params.plot.fig.title = sprintf('Stimulus ID %d, category: %s\n%s, %s',...
		    thisStimID,thisStimCat,artist_name,song_name);
  clear plotData;
  plotData{1} = rp;
  
  %need to also add this process conditional in above code
  if(isfield(params,'process') && ismember('trialSig',params.process))
    plotData(2:length(trialAud)+1) = trialAud;
  end

  if(params.separateStimIDPages)
    params.plot.plotFname = [plotFStub sprintf('_stimID_%d',thisStimID) '.ps'];
  else
    params.plot.appendToPlot = 1;
  
  end
  
  plot_rhythmProfile(plotData,params.plot);
  
end

outData = plotFile;

return



function trialList = getTrialsForThisStim(sessTrialInfo,params)

sessTrialInfoCols = set_var_col_const(sessTrialInfo.vars);
nSess = length(sessTrialInfo.data{sessTrialInfoCols.session_id});

trialList = ensemble_init_data_struct;
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
tapCondTypes = params.plotTappingConditions;
for iTapCond = 1:length(tapCondTypes)
  clear tmpFilt;
  tmpFilt.include.all.tapping_condition = tapCondTypes(iTapCond);
  trialListByCond{iTapCond} = ensemble_filter(trialList,tmpFilt);
end

trialList = trialListByCond;

return
