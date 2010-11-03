function outData = plot_resp_meanRhythmProfile_byStimID_v2(inData,params)
%
% plots mean RPs of the tap responses for each of the tappingConds
% set in parameters. Plots each of the tapping conds on a single
% plot for comparison.
%
% assumes that the stimulus is the first RP, so label order should
% be set accordingly
%
% Also exports the mean MPP corresponding to each stim and tap condition
%
% 18 July 2007, Stefan Tomic
% 29 July 2009, PJ - enabled restriction to desired stims

try procStims = params.procStims; catch procStims = []; end
try existingRPFile = params.rpFilename; catch existingRPFile = ''; end

meanEnergiesIdx = ensemble_find_analysis_struct(inData,struct('name','mean_energies_by_trial_and_subject'));
if isempty(meanEnergiesIdx)
  fprintf('Could not locate mean_energies_by_trial_and_subject in input data')
  if ~isempty(existingRPFile)
    rpfname = fullfile(params.rpPath,existingRPFile);
    fprintf('\tLoading meanEnergies from %s\n', rpfname);
    tmp = load(rpfname);
    meanEnergies = tmp.meanEnergies;
  end
else
  meanEnergies = inData{meanEnergiesIdx};
end
meCols = set_var_col_const(meanEnergies.vars);

stimulusMetadataIdx = ensemble_find_analysis_struct(inData,struct('name','stimulus_metadata'));
stimulusMetadata = inData{stimulusMetadataIdx};
stimulusMetadataCols = set_var_col_const(stimulusMetadata.vars);

stimIDs = unique(meanEnergies.data{meCols.stimulus_id});
if ~isempty(procStims)
  stimIDs = intersect(stimIDs,procStims);
end

tappingConds = params.tapping_cond;

exportRP = ensemble_init_data_struct;
exportRP.vars = {'stimulus_id' 'artist' 'song_title' tappingConds{1}{1} tappingConds{2}{1} 'stimulus'};
exportRPCols = set_var_col_const(exportRP.vars);
exportRP.data{exportRPCols.stimulus_id} = stimIDs;

if(params.savePlot)
  plotFname = fullfile(params.savePath,[params.filename '.ps']);
  confirmOverwrite = confirm_overwrite_file(plotFname);
end

%store original plot parameters so that they can be manipulated
%based on whether or not a stim is being plotted.
setParams.plot = params.plot;

%obtain coefficients for butterworth high pass filter
[b,a] = butter(3,.15,'high');


for iStim = 1:length(stimIDs)

  thisStimulusID = stimIDs(iStim);
  clear rpList;
  clear tmpFilt;
  tmpFilt.include.all.stimulus_id = thisStimulusID;
  meList = ensemble_filter(meanEnergies,tmpFilt);
  thisSongName = meList.data{meCols.song_name}{1};
  thisArtist   = meList.data{meCols.artist}{1};
  thisStimCat  = meList.data{meCols.stimulus_category}{1};

  exportRP.data{exportRPCols.artist}{iStim,1} = thisArtist;
  exportRP.data{exportRPCols.song_title}{iStim,1} = thisSongName;
  
  figParams.axLocs = {'rectPlot_bottom_multi','rectPlot_top'};
  figParams.numMulti.bottom = 3;
  figParams.plotTitle = [sprintf('Free Form vs. Isochronous\n')...
		    sprintf('Response Mean Rhythm Profile\n')...
		    sprintf('Stimulus ID %d, %s\n',thisStimulusID',thisStimCat)];
  
  if(~strcmp(thisStimCat,'silence'))
    figParams.plotTitle = [figParams.plotTitle sprintf('%s, %s',thisArtist,thisSongName)];
  end
  [figh,axh] = rhythmTap_figure(figParams);
  
  params.plot.legendLabels = {};
  plotData = ensemble_init_data_struct;
  plotData.vars = {'meanResonEnergy' 'stdResonEnergy' 'resonatorFreqs' ...
		   'peakResonFreqs','peakWidths','QFactor'};
  plotData.data = {{} {} {} {} {} {}};
  pdCols = set_var_col_const(plotData.vars);
  
  
  maxThisPlot = NaN;
  minThisPlot = NaN;
  for iTapCond = 1:length(tappingConds)

    thisTapCond = tappingConds{iTapCond};
    
    clear tmpFilt;
    tmpFilt.include.all.tapping_cond = thisTapCond;
    meTapList = ensemble_filter(meList,tmpFilt);
    
    meanEnergyMat = cell2mat(meTapList.data{meCols.meanEnergy}');
    nSubs = size(meanEnergyMat,2);    
    meanMEnergy = mean(meanEnergyMat,2);

    %high pass filter
    meanMEnergy = filtfilt(b,a,meanMEnergy);
    
    stdMEnergy  = std(meanEnergyMat,[],2)./sqrt(nSubs);
    resonFreqs  = meTapList.data{meCols.resonFreqs}{1};
    
    %transpose vectors if necessary
    if(size(meanMEnergy,2) > size(meanMEnergy,1))
      meanMEnergy = meanMEnergy';
    end
    if(size(resonFreqs,2) > size(resonFreqs,1))
      resonFreqs = resonFreqs';
    end
    if(size(stdMEnergy,2) > size(stdMEnergy,1))
      stdMEnergy = stdMEnergy';
    end
    
    peakIdxs = find_peaks(meanMEnergy,params.peakFinder);
    peakFreqs = resonFreqs(peakIdxs);
    
    peakWidths = get_rp_peakWidths('rpEnergy',meanMEnergy,'resonFreqs',resonFreqs,'peakFreqs',peakFreqs);
    
    
    rpList{iTapCond} = init_rp_struct;
    rpCols = set_var_col_const(rpList{iTapCond}.vars);
    rpList{iTapCond}.data{rpCols.meanResonatorEnergy} = meanMEnergy;
    rpList{iTapCond}.data{rpCols.stdResonatorEnergy} = stdMEnergy;
    rpList{iTapCond}.data{rpCols.resonatorFreqs} = resonFreqs;
    
    params.plot.legendLabels{end+1} = [params.labels{iTapCond} ...
    		    sprintf(' (N=%d)',nSubs)];
 
    maxEnergy = max(meanMEnergy);
    minEnergy = min(meanMEnergy);
    maxThisPlot = max(maxEnergy,maxThisPlot);
    minThisPlot = min(minEnergy,minThisPlot);
    
    %exporting the mean MPP for this stim and tap condition
    exportRP.data{exportRPCols.(thisTapCond{1})}(iStim,:) = meanMEnergy;
    
  end %for iTapCond
 
  %obtain the stimulus RP
  if(~strcmp(thisStimCat,'silence'))
    
    stimIPEMOut = ipem_proc_series(thisStimulusID,params.ipem);
    stimIPEMOutCols = set_var_col_const(stimIPEMOut.vars);
    
    thisStimRP = stimIPEMOut.data{stimIPEMOutCols.rp};
    
    if(iscell(thisStimRP))
      thisStimRP = thisStimRP{1};
    end
    thisStimRPCols = set_var_col_const(thisStimRP.vars);
    
    stimMeanEnergy = thisStimRP.data{thisStimRPCols.meanResonatorEnergy};
    resonFreqs     = thisStimRP.data{thisStimRPCols.resonatorFreqs};
    
    peakInfo = thisStimRP.data{thisStimRPCols.peakInfo};
    peakInfoCols = set_var_col_const(peakInfo.vars);
    peakFreqs = peakInfo.data{peakInfoCols.peakFreq};
    
       
    %rpList{end+1} = thisStimRP;
   
    params.plot.legendLabels{end+1} = 'stimulus';

    
    %store stim mpp in temporary variable
    stim_mpp = thisStimRP.data{thisStimRPCols.meanResonatorEnergy};

    %high pass filter stim mpp
    stim_mpp = filtfilt(b,a,stim_mpp);
  
    %normalize the stimulus RP based on the tapping RP, so that we
    %can more easily compare the graphs.   
    %normRatio = maxThisPlot./(max(stim_mpp));
    normRatio = (maxThisPlot-minThisPlot) ./ (max(stim_mpp) - min(stim_mpp));
    stim_mpp = (stim_mpp - min(stim_mpp)) .* normRatio + minThisPlot;
   
    thisStimRP.data{thisStimRPCols.meanResonatorEnergy} = stim_mpp;
    rpList{end+1} = thisStimRP;
    
    params.dispPeaks.header = upper({params.labels{:} 'stimulus'});
    params.plot.plotStd = setParams.plot.plotStd;
    params.plot.lineSpec  = setParams.plot.lineSpec;
  
    %%%%%%%%%%%
    %OBTAIN CORRELATIONS BETWEEN MEAN RESPONSE MPP AND STIMULUS
    nRP = length(rpList);
    for iRP = 1:nRP-1
 
      stim_mpp = thisStimRP.data{rpCols.meanResonatorEnergy};
      mpp = rpList{iRP}.data{rpCols.meanResonatorEnergy};
      [c(iRP),p(iRP)] = corr(mpp,stim_mpp);
    end
    %%%%%%%%%%%
    
     exportRP.data{exportRPCols.stimulus}(iStim,:) = stimMeanEnergy;
    
  else
    nRP = length(rpList);
    
    %not plotting stimulus data (for silence trials)
    params.plot.plotStd = setParams.plot.plotStd(1:end-1);
    params.plot.lineSpec  = setParams.plot.lineSpec(1:end-1);
    params.dispPeaks.header = upper(params.labels);
  end

  params.plot.ax = get_axhandle(axh,'rectPlot_top');
  
  params.plot.showResonTickLabels = 1;
  params.plot.perform = {'stdEnergy'};
  params.plot.color = 1;
  params.plot.peakFinder = params.peakFinder;
  plot_rpMeanResonEnergy(params.plot.ax,rpList,params.plot);
  
  params.dispPeaks.dispWidths = 0;
  params.dispPeaks.ax = get_axhandle(axh,'rectPlot_bottom');
  
  %%%%%%%%%%%
  %GET PEAK INFO FOR MEAN RESPONSE MPPs
  peakInfo = get_resonPeakInfo(rpList{1}.data{rpCols.meanResonatorEnergy},...
		    resonFreqs,params.peakFinder);
  peakInfo = ensemble_tree2datastruct(peakInfo);
  %temporary solution until ensemble_tree2datastruct is fixed
  if(iscell(peakInfo.data{1}))
    for iTmp = 1:length(peakInfo.data)
      peakInfo.data{iTmp} = peakInfo.data{iTmp}{1};
    end
  end
  
  rpList{1}.data{rpCols.peakInfo} = peakInfo;
  
  
  peakInfo = get_resonPeakInfo(rpList{2}.data{rpCols.meanResonatorEnergy},...
		    resonFreqs,params.peakFinder);
  peakInfo = ensemble_tree2datastruct(peakInfo);
  %temporary solution until ensemble_tree2datastruct is fixed
  if(iscell(peakInfo.data{1}))
    for iTmp = 1:length(peakInfo.data)
      peakInfo.data{iTmp} = peakInfo.data{iTmp}{1};
    end
  end
  
  rpList{2}.data{rpCols.peakInfo} = peakInfo;
 
  %%%%%%%%%%%%
  %DISPLAY PEAK INFO
  
  for iAx = 1:nRP
  
    fpax(iAx) = get_axhandle(axh,sprintf('multiBottom_%d',iAx));
    set(fpax(iAx),'visible','off');
    params.fontSize = 6;
    if((iAx < nRP) && ~strcmp(thisStimCat,'silence'))
      %add correlation and pval to header, except for last RP (stimulus)
      appendToHead = sprintf('\ncorr w/stim: %.2f, p: %.4f',c(iAx),p(iAx)); 
    else
      appendToHead = '';
    end
    
    fpHeader = [upper(params.plot.legendLabels{iAx}) appendToHead];
		
    params.fpTitle = fpHeader;
    plot_findPeaks(fpax(iAx),rpList{iAx},params);
  
  end 
  
  %%%%%%%%%%%%
  
    
  if(params.savePlot)
    if(confirmOverwrite)
      try fileType = params.fileType; catch fileType = 'png'; end
      try fileArgs = params.fileArgs; catch fileArgs = {}; end
      %painters mode seems to mess up the colors used by jbfill method of
      %plotting stdev.  However, if the file is saved out in painters mode, 
      % the opacity of each fill can then be tweaked in Adobe Illustrator
      print(plotFname,sprintf('-d%s', fileType), fileArgs{:});
    end
    delete(figh);
  end
  
  
end
  
  
  
outData = exportRP;

return
