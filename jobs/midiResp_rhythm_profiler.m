function outData = midiResp_rhythm_profiler(inData,params)
%
% Calculates summary measurements of tapping from the rhythm model and ITI stats
%  
% INPUT(S):
%   session_x_trial structure, returned from ensemble_session_x_trial_info.
%   stimulus_metadata, returned from ensemble_load_expinfo
%
% PARAM(S):
%  params.process:       'calcMeans','calcRP','loadRP'
%  params.savePath:      path to save individual RPs and summary measurement mat file 
%  params.ipem_proc:     ipem_proc_series parameters for rp calculation on tapping data
%  params.storeIpemProc: cell array of strings designating which result of ipem_proc_series to
%                        save for each trial (e.g. {'rp'})
%  params.filt:          ensemble_filter parameters for filtering out
%                        sessions/subs to process
%  params.tapping_stats: params for tappingStats_v2 (calculates ITI
%                        distribution info)
%  params.fname:         Filename to save summary measurement struct (saved to params.savePath)         
%  
%  
% DESCRIPTION:  
%  Loops through each session and trial, converts the midi 
%  responses from each trial to an aud struct. Each aud struct 
%  is then processed with ipem_proc_series. The RPs for each
%  trial are saved to disk in separate files at params.savePath.
%  Originally, this function simply looped through each trial,
%  calculated, and saved the RPs for each trial. Its utility has
%  extended to the calculation of summary measurements (e.g. mean coherence,
%  # MPP peaks, ITI std). If you only wish to recalculate the summary measurements
%  without recalculating the rhythm profiles, simply set 
%  params.process={'loadRP','calcMeans'}
%
%  not supporting searching/loading of rp with specified params sets yet
%  matching is done by checking trial order in the session.
%
%  NOTE: an earlier version of this function (r886 in svn) was performing
%        find_peaks, in lieu of using the peakFreqs in stored in the RP struct
%        This was old code that was forgotten in this function. This older code
%        was using params.peakFinder, which had a single parameter
%        params.peakFinder.thresh = 0.25. Therefore, some earlier results
%        (around June 2009) may have different nPeak results than currently
%        reported. - S.T. 3/1/2010
%  
%  
%  2007, Stefan Tomic - Original Version
%  2/24/2010, S.T. -  provided comments and general description
%                     Renamed meanEnergies variable to more appropriate name of
%                     tappingSummary (also was called trialMPP at one point- sorry!) 
%                     Likewise renamed meCols->tsCols, and meIdx->tsIdx

storeIpemProc = params.storeIpemProc;
  
if(ismember('calcMeans',params.process))
  %data struct for mean resonEnergies 
  tappingSummary = ensemble_init_data_struct;
  tappingSummary.type = 'mean_energies';
  tappingSummary.name = 'mean_energies_by_trial_and_subject';
  tappingSummary.vars = {'subject_id' 'stimulus_id' 'trial_order' 'tapping_cond' 'norm_by_peakITI_tapping_stats' 'norm_by_mean_tapping_stats' 'tapping_stats' 'stimulus_category' ...
		    'artist' 'song_name' 'meanEnergy' 'stdEnergy' ...
		    'resonFreqs' 'peakFreqs' 'normPeakFreqs' 'peakWidths','numPeaks','peakConcentration','meanVMPrediction','meanVMLogFulfillment','meanVMTimingDev','varVMPrediction','varVMLogFulfillment','varVMTimingDev','meanCoherence','varCoherence'};

  tsCols = set_var_col_const(tappingSummary.vars);
  tsIdx = 1;
end

if(~isfield(params,'process'))
  params.process = {'calcRP'};
end
  
if(length(intersect({'calcRP','loadRP'},params.process)) == 0)
  params.process = union(params.process,{'calcRP'});
end

clear searchCrit;
searchCrit.type = 'stimulus_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimulusMetadata = inData{findIdx};
smCols = set_var_col_const(stimulusMetadata.vars);

clear searchCrit;
searchCrit.type = 'session_x_trial_info';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
sessTrials = inData{findIdx};
sessTrialsCols = set_var_col_const(sessTrials.vars);

%filter all trial info with filter settings in params.
if(isfield(params,'filt'))
  clear tmpFilt
  tmpFilt = params.filt;
  sessTrials = ensemble_filter(sessTrials,tmpFilt);
end

sessIDs = sessTrials.data{sessTrialsCols.session_id};


for iSess = 1:length(sessIDs)

  thisExperimentID = sessTrials.data{sessTrialsCols.experiment_id}(iSess);
  thisSessionID = sessTrials.data{sessTrialsCols.session_id}(iSess);
  thisSubjectID = sessTrials.data{sessTrialsCols.subject_id}{iSess};
  
  fprintf('Processing Subject %s\n',thisSubjectID);
  
  clear tmpFilt;
  tmpFilt.include.all.session_id = thisSessionID;
  thisSessionStruct = ensemble_filter(sessTrials,tmpFilt);
  
  thisSessTrials = thisSessionStruct.data{sessTrialsCols.trial_info}{1};
  trialInfoCols = set_var_col_const(thisSessTrials.vars);
  
  nTrials = length(thisSessTrials.data{trialInfoCols.trial_id});
  
  for iTrial = 1:nTrials
  
    filename = sprintf('%s_%d_trial_%d.mat',thisSubjectID,thisSessionID,iTrial);
    filepath = fullfile(params.savePath,filename);
    
      
    thisTrialID = thisSessTrials.data{trialInfoCols.trial_id}(iTrial);
    thisStartTime = thisSessTrials.data{trialInfoCols.start_time_sec}(iTrial);
    thisStopTime = thisStartTime + thisSessTrials.data{trialInfoCols.dur_sec}(iTrial);
    
    clear tmpFilt;
    tmpFilt.include.all.trial_id = thisTrialID;
    tmpFilt.include.all.start_time_sec = thisStartTime;
    thisTrialStruct = ensemble_filter(thisSessTrials,tmpFilt);
    
    thisTrialStruct.vars = {thisTrialStruct.vars{:} 'resp_aud' storeIpemProc{:}};
    thisTrialStructCols = set_var_col_const(thisTrialStruct.vars);
    
    thisTapCond = thisTrialStruct.data{thisTrialStructCols.tapping_condition}{1};
    %thisTapStats = thisTrialStruct.data{thisTrialStructCols.tapping_stats}{1};
    thisStimCat = thisTrialStruct.data{thisTrialStructCols.stimulus_category}{1};
    thisStimulusID = thisTrialStruct.data{thisTrialStructCols.stimulus_id};
    
    smIdx = find(thisStimulusID == stimulusMetadata.data{smCols.stimulus_id});
    thisArtist = stimulusMetadata.data{smCols.artist}{smIdx};
    thisSongName = stimulusMetadata.data{smCols.name}{smIdx};

    if(ismember('calcRP',params.process))
      disp(sprintf('IPEM Proc for session %d/%d, trial %d/%d\n',iSess,length(sessIDs),iTrial,nTrials));
      
      thisMidiResp = thisTrialStruct.data{thisTrialStructCols.midi_resp}{1};
      midiRespCols = set_var_col_const(thisMidiResp.vars);
      
      thisNmat =thisMidiResp.data{midiRespCols.nmat};
      
      if(iscell(thisNmat))
	thisNmat = thisNmat{1};
      end
      
      params.nmat2aud.startTime = thisStartTime;
      params.nmat2aud.stopTime  = thisStopTime;
      respAud = nmat2aud(thisNmat,params.nmat2aud);
      thisTrialStruct.data{thisTrialStructCols.resp_aud}{1} = respAud;

      %don't use ipem_proc_series to save the calculation. It will be
      %saved along with trial data at the end of this function
      params.ipem_proc.glob.save_calc = {};
      ipemOut = ipem_proc_series(respAud,params.ipem_proc);
      ipemOutCols = set_var_col_const(ipemOut.vars);
    
      %store the ipem proc back to the trial data struct
      for iProc = 1:length(params.storeIpemProc)
	thisProc = storeIpemProc{iProc};
	thisTrialStruct.data{thisTrialStructCols.(thisProc)}{1} = ipemOut.data{ipemOutCols.(thisProc)}{1};
      end
    
      if(isfield(params,'savePath') && params.saveCalc)
	save(filepath,'thisSessionID','thisExperimentID','thisSubjectID','thisTrialStruct','thisTapCond','thisStimCat','thisArtist','thisSongName');
      end
    elseif(ismember('loadRP',params.process))
      load(filepath);
    end
    
    %recalculate tapping stats. We want both normalized and non-normalized stats
    midiInfo = thisTrialStruct.data{thisTrialStructCols.midi_resp}{1};
    midiInfoCols = set_var_col_const(midiInfo.vars);
    tappingStatsParams = params.tapping_stats;
    tappingStatsParams.normalizeBy = 'mean';
    thisNormByMeanTapStats = tappingStats_v2(midiInfo,tappingStatsParams);
    tappingStatsParams.normalizeBy = 'peakITI';
    thisNormByPeakTapStats = tappingStats_v2(midiInfo,tappingStatsParams);
    tappingStatsParams.normalizeBy = '';
    thisTapStats = tappingStats_v2(midiInfo,tappingStatsParams);
    
    
    
    if(ismember('calcMeans',params.process))
     
      thisRP = thisTrialStruct.data{thisTrialStructCols.rp}{1};
      if(~isempty(thisRP))
	rpCols = set_var_col_const(thisRP.vars);
	resonFreqs = thisRP.data{rpCols.resonatorFreqs};
	resonEnergy = thisRP.data{rpCols.resonatorEnergy};
	
	meanResonEnergy = thisRP.data{rpCols.meanResonatorEnergy};
	stdResonEnergy  = thisRP.data{rpCols.stdResonatorEnergy};
	if(size(meanResonEnergy,2) > size(meanResonEnergy,1))
	  meanResonEnergy = meanResonEnergy';
	end
	if(size(stdResonEnergy,2) > size(stdResonEnergy,1))
	  stdResonEnergy = stdResonEnergy';
	end	
	if(size(resonFreqs,2) > size(resonFreqs,1))
	  resonFreqs = resonFreqs';
	end
	
	peakInfo = thisRP.data{rpCols.peakInfo};
	peakInfoCols = set_var_col_const(peakInfo.vars);
	peakFreqs = peakInfo.data{peakInfoCols.peakFreq};
	normPeakFreqs = peakInfo.data{peakInfoCols.normPeakFreq};
	peakWidths = peakInfo.data{peakInfoCols.width};
	normPeakHeights = peakInfo.data{peakInfoCols.normHeight};

	%calculating numPeaks
	numPeaks = length(peakFreqs);
	
	%calculating peakConcentration (sum of normalized heights / npeaks)
	peakConcentration = sum(normPeakHeights) ./ numPeaks;
	
	if(isfield(rpCols,'coherence'))
	  coherence = thisRP.data{rpCols.coherence};
	  coherenceCols = set_var_col_const(coherence.vars);
	  tappingSummary.data{tsCols.meanCoherence}(tsIdx,1) = nanmean(coherence.data{coherenceCols.cohPerPeakPerBand}{1});
	  tappingSummary.data{tsCols.varCoherence}(tsIdx,1) = nanstd(coherence.data{coherenceCols.cohPerPeakPerBand}{1}).^2;
	end
	  
	if(isfield(rpCols,'vmExpect'))
	  vmData = thisRP.data{rpCols.vmExpect};
	  vmDataCols = set_var_col_const(vmData.vars);
	  vmPredictionPerOnset = vmData.data{vmDataCols.vmPredictionPerOnset};
	  vmLogFulfillPerOnset = vmData.data{vmDataCols.vmLogFulfillPerOnset};
	  vmTimingDev = vmData.data{vmDataCols.vmTimingDev};
	  tappingSummary.data{tsCols.meanVMPrediction}(tsIdx,1) = nanmean(vmPredictionPerOnset{1});
	  tappingSummary.data{tsCols.meanVMLogFulfillment}(tsIdx,1) = nanmean(vmLogFulfillPerOnset{1});
	  tappingSummary.data{tsCols.meanVMTimingDev}(tsIdx,1) = nanmean(vmTimingDev{1});
	  tappingSummary.data{tsCols.varVMPrediction}(tsIdx,1) = nanstd(vmPredictionPerOnset{1}).^2;
	  tappingSummary.data{tsCols.varVMLogFulfillment}(tsIdx,1) = nanstd(vmLogFulfillPerOnset{1}).^2;
	  tappingSummary.data{tsCols.varVMTimingDev}(tsIdx,1) = nanstd(vmTimingDev{1}).^2;
	end
		
	tappingSummary.data{tsCols.subject_id}{tsIdx,1} = thisSubjectID;
	tappingSummary.data{tsCols.stimulus_id}(tsIdx,1) = thisStimulusID;
	tappingSummary.data{tsCols.trial_order}(tsIdx,1) = iTrial;
	tappingSummary.data{tsCols.tapping_cond}{tsIdx,1}  = thisTapCond;
	tappingSummary.data{tsCols.tapping_stats}{tsIdx,1} = thisTapStats;
	tappingSummary.data{tsCols.norm_by_peakITI_tapping_stats}{tsIdx,1} = thisNormByPeakTapStats;
	tappingSummary.data{tsCols.norm_by_mean_tapping_stats}{tsIdx,1} = thisNormByMeanTapStats;
	tappingSummary.data{tsCols.stimulus_category}{tsIdx,1} = thisStimCat;
	tappingSummary.data{tsCols.artist}{tsIdx,1} = thisArtist;
	tappingSummary.data{tsCols.song_name}{tsIdx,1} = thisSongName;
	tappingSummary.data{tsCols.meanEnergy}{tsIdx,1} = meanResonEnergy;
	tappingSummary.data{tsCols.stdEnergy}{tsIdx,1} = stdResonEnergy;
	tappingSummary.data{tsCols.resonFreqs}{tsIdx,1} = resonFreqs;
	tappingSummary.data{tsCols.normPeakFreqs}{tsIdx,1} = normPeakFreqs;
	tappingSummary.data{tsCols.peakFreqs}{tsIdx,1} = peakFreqs;
	tappingSummary.data{tsCols.peakWidths}{tsIdx,1} = peakWidths;
	tappingSummary.data{tsCols.numPeaks}{tsIdx,1} = numPeaks;
	tappingSummary.data{tsCols.peakConcentration}{tsIdx,1} = peakConcentration;
	tsIdx = tsIdx + 1;
	
      end
      
    end
    
  end

end

if(ismember('calcMeans',params.process) && isfield(params,'savePath') ...
   && params.saveCalc)
  meanEnergyPath = fullfile(params.savePath,params.fname);
  save(meanEnergyPath,'tappingSummary','params');
end

if(ismember('calcMeans',params.process))
  outData = tappingSummary;
else
  outData = [];
end

