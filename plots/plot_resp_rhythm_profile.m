function outData = plot_resp_rhythm_profile(inData,params)
%
%
% produces resonator output and resonator energy plots from
% rhythm profile calculations and saves
% them to postscript files. The rhythm profiles are read in from
% files located in the directory specified in the rpPath.
%

peakITI_vs_peakReson = {[] [] {} {}};

clear searchCrit;
searchCrit.type = 'session_x_trial_info';
sessTrialListIdx = ensemble_find_analysis_struct(inData,searchCrit);
sessTrialList = inData{sessTrialListIdx};
sessTrialListCols = set_var_col_const(sessTrialList.vars);

clear searchCrit;
searchCrit.type = 'stimulus_metadata';
stimulusMetadataIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimulusMetadata = inData{stimulusMetadataIdx};
stimulusMetadataCols = set_var_col_const(stimulusMetadata.vars);

rpPath = params.rpPath;
rpPathList = dir(fullfile(rpPath,'*trial*.mat'));
rpFnames = {rpPathList.name};

%filter out the session list to include only the ones we want to plot
if(isfield(params,'sessTrialList') && isfield(params.sessTrialList,'filt'))
  sessTrialList = ensemble_filter(sessTrialList,params.sessTrialList.filt);
end

%filter out the stimulus list to include only the ones we want to plot
stimulusMetadata = ensemble_filter(stimulusMetadata,params.stimulusMetadata.filt);

%data struct for mean resonEnergies per stim for plot
meanEnergies = ensemble_init_data_struct;
meanEnergies.vars = {'stimulus_id'  'artist' 'song_name' 'meanEnergy' 'resonFreqs' 'Fs' ...
		    'tapping_cond' 'stimulus_category' 'nTrials'};
meCols = set_var_col_const(meanEnergies.vars);
nStims = length(stimulusMetadata.data{stimulusMetadataCols.stimulus_id});

tappingConditions = params.tappingConditions;
for iTapCond = 1:length(tappingConditions)
  for iStim = 1:nStims
    meIdx = (iTapCond-1)*nStims + iStim;
    meanEnergies.data{meCols.stimulus_id}(meIdx,1) = stimulusMetadata.data{stimulusMetadataCols.stimulus_id}(iStim);
    meanEnergies.data{meCols.artist}{meIdx,1} = stimulusMetadata.data{stimulusMetadataCols.artist}{iStim};
    meanEnergies.data{meCols.song_name}{meIdx,1} = stimulusMetadata.data{stimulusMetadataCols.name}{iStim};
    meanEnergies.data{meCols.tapping_cond}{meIdx,1} = tappingConditions{iTapCond};
    meanEnergies.data{meCols.meanEnergy}{meIdx,1} = [];
    meanEnergies.data{meCols.resonFreqs}{meIdx,1} = [];
    meanEnergies.data{meCols.nTrials}(meIdx,1) = 0;
  end
end

for iFname = 1:length(rpFnames)
  subid = regexp(rpFnames{iFname},'(\w+)_\d+_trial_\d+\.mat','tokens');
  subIDstr{iFname} = subid{1}{1};
end

subIDswithMatFiles = unique(subIDstr);
subIDsInTrialList = sessTrialList.data{sessTrialListCols.subject_id};

[uniqueSubIDs,ia] = intersect(subIDsInTrialList,subIDswithMatFiles);

if(length(ia) ~= length(subIDsInTrialList))
  idxNoMat = setdiff([1:length(subIDsInTrialList)],ia);
  fprintf('Some subjects did not have rhythm profile data in specified path:\n');
  for (isub = 1:length(idxNoMat))
   fprinf('%s\n',subIDsInTrialList(isub)); 
  end
end

uniqueStimIDs = unique(stimulusMetadata.data{stimulusMetadataCols.stimulus_id});

for iSubject = 1:length(uniqueSubIDs)
  
  thisSubjectID = uniqueSubIDs{iSubject};

  disp(sprintf('Loading Rhythm Profiles for Subject %s\n\n',thisSubjectID));
  
  fList_thisSub = dir(fullfile(rpPath,[uniqueSubIDs{iSubject} '*.mat']));
  fnames_thisSub = {fList_thisSub(:).name};
    
  %get the list of trials for this sub from the
  %session_x_trial_info struct
  clear tmpFilt;
  tmpFilt.include.all.subject_id = uniqueSubIDs(iSubject);
  sessTrialListThisSub = ensemble_filter(sessTrialList,tmpFilt);
  trialListThisSub = sessTrialListThisSub.data{sessTrialListCols.trial_info}{1};
  trialListThisSubCols = set_var_col_const(trialListThisSub.vars);
  
  %load each rp for this subject, and add the rp struct to the
  %session_x_trial struct, matching the trial order of the rp
  %struct to the session_x_trial struct. The stim id and trial id
  %of both structs will be checked to make sure that we have a match
  for iFile = 1:length(fnames_thisSub)
    
    clear rpInfo;
    rpInfo = load(fullfile(rpPath,fnames_thisSub{iFile}));
    
    trialOrderMatch = regexp(fnames_thisSub{iFile},'\w+_\d+_trial_(\d+)\.mat','tokens');
    trialOrder = str2num(trialOrderMatch{1}{1});
    
    
    rpTrialStruct = rpInfo.thisTrialStruct;
    rpTrialStructCols = set_var_col_const(rpTrialStruct.vars);
  
    thisTrialID = rpTrialStruct.data{rpTrialStructCols.trial_id};
    thisStimulusID = rpTrialStruct.data{rpTrialStructCols.stimulus_id};
    thisStimCat = rpTrialStruct.data{rpTrialStructCols.stimulus_category}{1};
    thisTapCond = rpTrialStruct.data{rpTrialStructCols.tapping_condition}{1};
    
    if(~ismember(thisStimulusID,stimulusMetadata.data{stimulusMetadataCols.stimulus_id}))
      continue;
    end
    
    if(ismember(thisTapCond,params.exclude.tappingCondition))
      continue;
    end
    
    thisRP = rpTrialStruct.data{rpTrialStructCols.rp}{1};
    thisRespAud = rpTrialStruct.data{rpTrialStructCols.resp_aud}{1};

    %converting midi to aud for separating right and left hands 
    %ideally, this would have been done in
    %midiResp_rhythm_profiler. This code should probably be moved there
    %next time that process is run.
    midiResp= rpTrialStruct.data{rpTrialStructCols.midi_resp}{1};
    params.nmat2aud.startTime = rpTrialStruct.data{rpTrialStructCols.start_time_sec};
    params.nmat2aud.stopTime = params.nmat2aud.startTime + ...
	rpTrialStruct.data{rpTrialStructCols.dur_sec};
    midiRespCols = set_var_col_const(midiResp.vars);
    thisNmat = midiResp.data{midiRespCols.nmat};
    if(iscell(thisNmat))
      thisNmat = thisNmat{1};
    end
    params.nmat2aud.extractNotes = params.nmat2aud.leftHandMidiNote;
    thisRespAudLeft = nmat2aud(thisNmat,params.nmat2aud);
    params.nmat2aud.extractNotes = params.nmat2aud.rightHandMidiNote;
    thisRespAudRight = nmat2aud(thisNmat,params.nmat2aud);
    
    if(~isempty(thisRP))
      thisRPCols = set_var_col_const(thisRP.vars);
      %squeeze and mean not necessary here. Only one band is used and
      %plot_rhythmProfile should take care of squeeze where necessary (for
      %plotting, etc.)
      %thisRP.data{thisRPCols.resonatorOut} =  squeeze(mean(thisRP.data{thisRPCols.resonatorOut},1));
    end
    
    %match resonatorOut and resonatorEnergy to the trial list
    trialListIdx = find(trialListThisSub.data{trialListThisSubCols.trial_order} == trialOrder);
    
    %make sure stimulus parameters between the two structs match
    if( ~(trialListThisSub.data{trialListThisSubCols.stimulus_id}(trialListIdx) ==  thisStimulusID) | ...
	~(trialListThisSub.data{trialListThisSubCols.trial_id}(trialListIdx)==thisTrialID) | ...
	~(strcmp(trialListThisSub.data{trialListThisSubCols.stimulus_category}(trialListIdx),thisStimCat)) | ...
	~(strcmp(trialListThisSub.data{trialListThisSubCols.tapping_condition}(trialListIdx),thisTapCond)))

      error(sprintf('Mismatch in trial info for file %s',fnames_thisSub{iFile}));
    end

    tappingStats = trialListThisSub.data{trialListThisSubCols.tapping_stats}{trialListIdx};
    tappingStatsCols = set_var_col_const(tappingStats.vars);
    tappingStatsBoth = tappingStats.data{tappingStatsCols.both};
    tappingStatsLeft = tappingStats.data{tappingStatsCols.left};
    tappingStatsRight = tappingStats.data{tappingStatsCols.right};
    tappingStatsCols = set_var_col_const(tappingStatsBoth.vars);
    var_about_peak = tappingStatsBoth.data{tappingStatsCols.var_about_peak};

    ioiHistBinsBoth = tappingStatsBoth.data{tappingStatsCols.hist_bin_centers};
    ioiHistBoth = tappingStatsBoth.data{tappingStatsCols.ioi_hist};
    peakIOIBoth = ioiHistBinsBoth(find(ioiHistBoth == max(ioiHistBoth),1,'first'));
    
    ioiHistBinsLeft = tappingStatsLeft.data{tappingStatsCols.hist_bin_centers};
    ioiHistLeft = tappingStatsLeft.data{tappingStatsCols.ioi_hist};
    peakIOILeft = ioiHistBinsLeft(find(ioiHistLeft == max(ioiHistLeft),1,'first'));

    ioiHistBinsRight = tappingStatsRight.data{tappingStatsCols.hist_bin_centers};
    ioiHistRight = tappingStatsRight.data{tappingStatsCols.ioi_hist};
    peakIOIRight = ioiHistBinsRight(find(ioiHistRight == max(ioiHistRight),1,'first'));

    if(~isempty(thisRP))
      %add this RP to the peak ITI vs. peak Reson plot
      peakITI_vs_peakReson{1}(end+1:end+3,1) = [peakIOIBoth ; peakIOILeft ; peakIOIRight];
      peakITI_vs_peakReson{2}(end+1:end+3,1) = repmat(1./peakMeanReson(thisRP),3,1);
      peakITI_vs_peakReson{3}(end+1:end+3,1) = repmat({thisTapCond},3,1);
      peakITI_vs_peakReson{4}(end+1:end+3,1) = {'both' ; 'left' ; 'right'};
    end
      
    titleStr = [sprintf('Subject ID %s, trial order %d\n',thisSubjectID,trialOrder) ...
		sprintf('trial ID %d, stimulus ID %d: ',thisTrialID,thisStimulusID)...    
		sprintf('%s, %s\n',thisStimCat,thisTapCond)...
		sprintf('var about peak: %.3f',var_about_peak)];
    params.plot.fig.title = titleStr;
    
        
    disp(sprintf('Plotting Subject ID %s, Trial Order %d, Stimulus ID %d',...
		   thisSubjectID,trialOrder,thisStimulusID))
      
    switch(params.savePlotsBy)
     case 'stimulus_id'
      %tagNum is used to separate plot files for silence trials
      %since there are so many of them
      if(strcmp(thisStimCat,'silence'))
	tagNum = num2str(floor(iSubject/5)+1);
      else
	tagNum = '';
      end
      params.plot.plotFname = sprintf('stimulus_id_%d_%s%s',thisStimulusID,thisStimCat,tagNum);
     case 'subject_id'
      params.plot.plotFname = sprintf('subject_id_%s',thisSubjectID);
     case 'trial_and_sub'
      params.plot.plotFname = sprintf('subject_id_%s_stimulus_id_%d_%s_trial_%d',thisSubjectID,thisStimulusID,thisStimCat,trialOrder);
    end
      
    clear plotData;
    plotData{1} = thisRP;
    params.plot.trialSets = [1 1;2 2];

    plotData{2} = thisRespAudLeft;
    plotData{3} = thisRespAudRight;
          
    plot_rhythmProfile(plotData,params.plot);
    
      
    %sum up the energies. This will be divided by nTrials after the
    %loop finishes.
    if(~isempty(thisRP))
      %thisEnergy = mean(thisRP.data{thisRPCols.resonatorEnergy},2);
      thisEnergy = thisRP.data{thisRPCols.resonatorEnergy};
      resonFreqs = thisRP.data{thisRPCols.resonatorFreqs};
      meIdx = find(meanEnergies.data{meCols.stimulus_id} == thisStimulusID ...
		   & strcmp(meanEnergies.data{meCols.tapping_cond},thisTapCond));
      Fs = thisRP.data{thisRPCols.Fs};
      
      if(isempty(meanEnergies.data{meCols.meanEnergy}{meIdx,1}))
	meanEnergies.data{meCols.meanEnergy}{meIdx,1} = thisEnergy;
      else
	%if the time durations of the energy matrices differ,
	%then just pad the shorter one with zeros. They all line
	%up at the start and are simply truncated after the last
	%midi note so have different durations for this reason.
	numResons = length(resonFreqs);
	currentSum = meanEnergies.data{meCols.meanEnergy}{meIdx,1};
	timeDiff = size(currentSum,2) - size(thisEnergy,2);
	newSum = [currentSum zeros(numResons,-timeDiff)] + [thisEnergy ...
		    zeros(numResons,timeDiff)];
	
	%meanEnergies.data{meCols.meanEnergy}{meIdx,1} = ...
	%    meanEnergies.data{meCols.meanEnergy}{meIdx,1} + thisEnergy;
	meanEnergies.data{meCols.meanEnergy}{meIdx,1} = newSum;
      end
      meanEnergies.data{meCols.nTrials}(meIdx,1) = ...
	  meanEnergies.data{meCols.nTrials}(meIdx,1) + 1;
      meanEnergies.data{meCols.stimulus_category}{meIdx,1} = thisStimCat;
      meanEnergies.data{meCols.resonFreqs}{meIdx,1} = resonFreqs;
      meanEnergies.data{meCols.Fs}(meIdx,1) = Fs;
    end
  end

end


if(ismember('plotMeanEnergy',params.perform))
  %plot the mean energies (across all trials) for each stim
  nMeans = length(meanEnergies.data{meCols.stimulus_id});
  for meIdx = 1:nMeans
    thisStimulusID = meanEnergies.data{meCols.stimulus_id}(meIdx);
    thisTapCond = meanEnergies.data{meCols.tapping_cond}{meIdx};
    thisStimCat = meanEnergies.data{meCols.stimulus_category}{meIdx};
    nTrials = meanEnergies.data{meCols.nTrials}(meIdx);
    resonFreqs = meanEnergies.data{meCols.resonFreqs}{meIdx};
    Fs = meanEnergies.data{meCols.Fs}(meIdx);
    meanEnergy = meanEnergies.data{meCols.meanEnergy}{meIdx} ./nTrials;
    thisArtist = meanEnergies.data{meCols.artist}{meIdx};
    thisSongName   = meanEnergies.data{meCols.song_name}{meIdx};
 
    mPlotParams = params.plot;
    mPlotParams.plotTitle = [sprintf('stimulus ID %d: ',thisStimulusID) ...    
		    sprintf('%s, "%s"\n',thisArtist,thisSongName) ...
		    sprintf('%s, %s\n',thisStimCat,thisTapCond)];
    mPlotParams.plotFname = sprintf('meanEnergies_all_stims');
    mPlotParams.perform = {'resonEnergy','stdEnergy','meanEnergy','findPeaks'};
  
    %storing mean energy in resonator Energy. This is sort of
    %kludgy. Ideally, we would pass in the actual mean resonator
    %Energy (2D matrix) and calculate the mean across time in
    %plot_rhythmProfile, but in this case we need to make sure that
    %the trial aud info is syncing up across the same stimuli, but
    %they are not. Probably an issue with midi2aud converter.
    %the mean energy is passed in as a column vector, so a second
    %mean will not be successfully performed in plot_rhythmProfile.
    if(~isempty(meanEnergy))
      meanRP = init_rp_struct('resonatorFreqs',resonFreqs,'resonatorEnergy',meanEnergy,'Fs',Fs);
      clear plotData;
      plotData{1} = meanRP;
      plot_rhythmProfile(plotData,mPlotParams);
    end
    
  end
end

if(ismember('plotPeakITI_vs_peakReson',params.perform))
  plot_peakITI_vs_peakReson(peakITI_vs_peakReson);
  print('-dpsc','-append',fullfile(params.plot.savePath,'peakITI_vs_peakReson_comparison'));
end

outData{1} = meanEnergies;
outData{2} = peakITI_vs_peakReson;

return
