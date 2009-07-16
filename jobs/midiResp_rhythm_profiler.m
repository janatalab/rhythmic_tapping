function outData = midiResp_rhythm_profiler(inData,params)
%
% Takes a session_x_trial structure, returned from
% ensemble_session_x_trial_info. Loops through each session and
% trial, then converts the midi responses from each trial to an aud
% struct. The conversion to aud struct is just an intermediate
% stage so that the response can be processed by ipem_proc_series,
% which works on audio waveforms. ipem_proc_series processes the
% ani and rp (rhythm profile). The rp for each response is added to
% the session_x_trial struct, which is returned.
%
%

%not supporting searching/loading of rp with specified params sets yet
%matching is done by checking trial order in the session.

if(ismember('calcMeans',params.process))
  %data struct for mean resonEnergies 
  meanEnergies = ensemble_init_data_struct;
  meanEnergies.type = 'mean_energies';
  meanEnergies.name = 'mean_energies_by_trial_and_subject';
  meanEnergies.vars = {'subject_id' 'stimulus_id' 'trial_order' 'tapping_cond' 'tapping_stats' 'stimulus_category' ...
		    'artist' 'song_name' 'meanEnergy' 'stdEnergy' ...
		    'resonFreqs' 'peakFreqs' 'normPeakFreqs' 'peakWidths','meanVMPrediction','meanVMViolation','meanVMTimingDev','varVMPrediction','varVMViolation','varVMTimingDev','meanCoherence','varCoherence'};

  meCols = set_var_col_const(meanEnergies.vars);
  meIdx = 1;
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

sessIDs = sessTrials.data{sessTrialsCols.session_id};
storeIpemProc = params.storeIpemProc;

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
    thisTapStats = thisTrialStruct.data{thisTrialStructCols.tapping_stats}{1};
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
    
    %if params.getTappingStats was set, process it here
    if(ismember('recalcTappingStats',params.process))
      midiInfo = thisTrialStruct.data{thisTrialStructCols.midi_resp}{1};
      midiInfoCols = set_var_col_const(midiInfo.vars);
      tappingStatsParams = params.tapping_stats;
      tappingStatsParams = params.tapping_stats;
      thisTapStats = tappingStats_v2(midiInfo,tappingStatsParams);
      thisTrialStruct.data{thisTrialStructCols.tapping_stats}{1} = thisTapStats;
    end
    
    
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
	
	peakIdxs = find_peaks(meanResonEnergy,params.peakFinder);
	peakFreqs = resonFreqs(peakIdxs);
	peakWidths = get_rp_peakWidths('rpEnergy',meanResonEnergy,...
						  'peakFreqs',peakFreqs,...
						  'resonFreqs',resonFreqs);
	if(isfield(rpCols,'coherence'))
	  coherence = thisRP.data{rpCols.coherence};
	  coherenceCols = set_var_col_const(coherence.vars);
	  meanEnergies.data{meCols.meanCoherence}(meIdx,1) = nanmean(coherence.data{coherenceCols.cohPerPeakPerBand}{1});
	  meanEnergies.data{meCols.varCoherence}(meIdx,1) = nanstd(coherence.data{coherenceCols.cohPerPeakPerBand}{1}).^2;
	end
	  
	if(isfield(rpCols,'vmExpect'))
	  vmData = thisRP.data{rpCols.vmExpect};
	  vmDataCols = set_var_col_const(vmData.vars);
	  vmPredictionPerOnset = vmData.data{vmDataCols.vmPredictionPerOnset};
	  vmViolationPerOnset = vmData.data{vmDataCols.vmViolationPerOnset};
	  vmTimingDev = vmData.data{vmDataCols.vmTimingDev};
	  meanEnergies.data{meCols.meanVMPrediction}(meIdx,1) = nanmean(vmPredictionPerOnset{1});
	  meanEnergies.data{meCols.meanVMViolation}(meIdx,1) = nanmean(vmViolationPerOnset{1});
	  meanEnergies.data{meCols.meanVMTimingDev}(meIdx,1) = nanmean(vmTimingDev{1});
	  meanEnergies.data{meCols.varVMPrediction}(meIdx,1) = nanstd(vmPredictionPerOnset{1}).^2;
	  meanEnergies.data{meCols.varVMViolation}(meIdx,1) = nanstd(vmViolationPerOnset{1}).^2;
	  meanEnergies.data{meCols.varVMTimingDev}(meIdx,1) = nanstd(vmTimingDev{1}).^2;
	end
		
	meanEnergies.data{meCols.subject_id}{meIdx,1} = thisSubjectID;
	meanEnergies.data{meCols.stimulus_id}(meIdx,1) = thisStimulusID;
	meanEnergies.data{meCols.trial_order}(meIdx,1) = iTrial;
	meanEnergies.data{meCols.tapping_cond}{meIdx,1}  =thisTapCond;
	meanEnergies.data{meCols.tapping_stats}{meIdx,1} =thisTapStats;
	meanEnergies.data{meCols.stimulus_category}{meIdx,1} = thisStimCat;
	meanEnergies.data{meCols.artist}{meIdx,1} = thisArtist;
	meanEnergies.data{meCols.song_name}{meIdx,1} = thisSongName;
	meanEnergies.data{meCols.meanEnergy}{meIdx,1} = meanResonEnergy;
	meanEnergies.data{meCols.stdEnergy}{meIdx,1} = stdResonEnergy;
	meanEnergies.data{meCols.resonFreqs}{meIdx,1} = resonFreqs;
	meanEnergies.data{meCols.normPeakFreqs}{meIdx,1} = normPeakFreqs;
	meanEnergies.data{meCols.peakFreqs}{meIdx,1} = peakFreqs;
	meanEnergies.data{meCols.peakWidths}{meIdx,1} = peakWidths;

	meIdx = meIdx + 1;
	
      end
      
    end
    
  end

end

if(ismember('calcMeans',params.process) && isfield(params,'savePath') ...
   && params.saveCalc)
  meanEnergyPath = fullfile(params.savePath,'meanEnergies_peakWidths_byTrialSub_normIOI.mat');
  save(meanEnergyPath,'meanEnergies','params');
end

if(ismember('calcMeans',params.process))
  outData = meanEnergies;
else
  outData = [];
end

