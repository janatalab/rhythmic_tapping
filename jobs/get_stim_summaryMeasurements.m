function outData = get_stim_summaryMeasurements(inData,params)
%
% Was get_stim_meanRhythmProfile.m. Returns summary measurements for each stim
% (e.g. npeaks, complex_simple, mean-var-Coherence, etc.)
%
% If any additional summary measurements are desired, they may be added here
% instead of in a post-processing script.
%
% 2/23/10 - renamed function and added timing expectancy calculations
  
ensemble_globals;

  
meanResEnergy = ensemble_init_data_struct;
meanResEnergy.vars = {'stimulus_id' 'artist' 'song_name' 'stimulus_category' ...
		    'MPP' 'stdPP' 'resonFreqs' 'npeaks' 'complex_simple' ...
		    'mmCoh' 'mvCoh' 'vmCoh' 'vvCoh' ...
		    'mmPred' 'mvPred' 'vmPred' 'vvPred' ...
		    'mmTD' 'mvTD' 'vmTD' 'vvTD'};

mrCols = set_var_col_const(meanResEnergy.vars);

clear searchCrit;
searchCrit.type = 'stimulus_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimMetaData = inData{findIdx};
stimMetaDataCols = set_var_col_const(stimMetaData.vars);
stimMetaData = ensemble_filter(stimMetaData,params.stims.filt);

clear searchCrit;
searchCrit.type = 'stimulus_x_attribute_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimAttMetaData = inData{findIdx};
stimAttMetaDataCols = set_var_col_const(stimAttMetaData.vars);
stimAttMetaData = ensemble_filter(stimAttMetaData,params.stimAttributes.filt);


nStims = length(stimMetaData.data{stimMetaDataCols.stimulus_id});

for iStim = 1:nStims

  thisStimID = ...
      stimMetaData.data{stimMetaDataCols.stimulus_id}(iStim);

  fprintf('Processing Stim %d, ID %d\n',iStim,thisStimID);
  
  stimAttIdx = find(stimAttMetaData.data{stimAttMetaDataCols.stimulus_id} == thisStimID);
  thisStimCat = stimAttMetaData.data{stimAttMetaDataCols.name}{stimAttIdx};
  
  thisLocation = stimMetaData.data{stimMetaDataCols.location}{iStim};
  [path,fstub,ext] = fileparts(fullfile(stimulus_ipem_analysis_root,thisLocation));
  
  rpPath = fullfile(path,fstub,'rp');
  
  ipemProc = ipem_proc_series(thisStimID,params.ipem);
  ipemProcCols = set_var_col_const(ipemProc.vars);
  rp = ipemProc.data{ipemProcCols.rp}{1};
  rp = ensemble_datastruct2tree(rp);

  artist = stimMetaData.data{stimMetaDataCols.artist}{iStim};
  song_name = stimMetaData.data{stimMetaDataCols.name}{iStim};
  
  meanResEnergy.data{mrCols.stimulus_id}(iStim,1) = thisStimID;
  meanResEnergy.data{mrCols.artist}{iStim,1} = artist;
  meanResEnergy.data{mrCols.song_name}{iStim,1} = song_name;
  meanResEnergy.data{mrCols.stimulus_category}{iStim,1} = thisStimCat;
  meanResEnergy.data{mrCols.MPP}{iStim,1} = rp.meanResonatorEnergy;
  meanResEnergy.data{mrCols.stdPP}{iStim,1} = rp.stdResonatorEnergy;
  meanResEnergy.data{mrCols.resonFreqs}{iStim,1} = rp.resonatorFreqs;

  if( isfield(rp,'interpMPPStruct'))
    mppPeaks = rp.interpMPPStruct.peakInfo.peakFreq;
  else
    mppPeaks = rp.peakInfo.peakFreq;
  end
  
  meanResEnergy.data{mrCols.npeaks} = length(mppPeaks);
  meanResEnergy.data{mrCols.complex_simple} = rp_binRatioComplexity(rp);
  
  [meanResEnergy.data{mrCols.mmCoh},...
   meanResEnergy.data{mrCols.mvCoh},...
   meanResEnergy.data{mrCols.vmCoh},...
   meanResEnergy.data{mrCols.vvCoh}] = rp_summaryTempExpect(rp.coherence.cohPerPeakPerBand);

  [meanResEnergy.data{mrCols.mmPred},...
   meanResEnergy.data{mrCols.mvPred},...
   meanResEnergy.data{mrCols.vmPred},...
   meanResEnergy.data{mrCols.vvPred}] = rp_summaryTempExpect(rp.vmExpect.vmPredictionPerOnset);
  
  [meanResEnergy.data{mrCols.mmTD},...
   meanResEnergy.data{mrCols.mvTD},...
   meanResEnergy.data{mrCols.vmTD},...
   meanResEnergy.data{mrCols.vvTD}] = rp_summaryTempExpect(rp.vmExpect.vmTimingDev);
  
end

outData = meanResEnergy;

return





