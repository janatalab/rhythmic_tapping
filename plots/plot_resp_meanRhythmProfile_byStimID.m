function outData = plot_resp_meanRhythmProfile_byStimID(inData,params)
%
% plots mean RPs of the tap responses for each of the tappingConds
% set in parameters. Plots each of the tapping conds on a single
% plot for comparison.
%
% assumes that the stimulus is the first RP, so label order should
% be set accordingly
%
% 18 July 2007, Stefan Tomic


meanEnergies = inData;
meCols = set_var_col_const(meanEnergies.vars);

stimIDs = unique(meanEnergies.data{meCols.stimulus_id});
tappingConds = params.tapping_cond;

if(params.savePlot)
  plotFname = fullfile(params.savePath,[params.filename '.ps']);
  confirmOverwrite = confirm_overwrite_file(plotFname);
end

%store original plot parameters so that they can be manipulated
%based on whether or not a stim is being plotted.
setParams.plot = params.plot;

stimAnLoad = load(params.stimAnalysisMatFile,'an');
fprintf('Loading stim mean rhythm profiles from %s\n\n',params.stimAnalysisMatFile);
stimAnList = stimAnLoad.an;
searchCrit.name = params.stimAnMeanRPJob;
anIdx = ensemble_find_analysis_struct(stimAnList,searchCrit);
stimMeanRPList = stimAnList{anIdx}.results;
slCols = set_var_col_const(stimMeanRPList.vars);

for iStim = 1:length(stimIDs)

  thisStimulusID = stimIDs(iStim);

  clear tmpFilt;
  tmpFilt.include.all.stimulus_id = thisStimulusID;
  meList = ensemble_filter(meanEnergies,tmpFilt);
  thisSongName = meList.data{meCols.song_name}{1};
  thisArtist   = meList.data{meCols.artist}{1};
  thisStimCat  = meList.data{meCols.stimulus_category}{1};
  
  figParams.axLocs = {'rectPlot_bottom','rectPlot_top'};
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
  
  
  maxThisPlot = 0;
  for iTapCond = 1:length(tappingConds)

    thisTapCond = tappingConds{iTapCond};
    
    clear tmpFilt;
    tmpFilt.include.all.tapping_cond = thisTapCond;
    meTapList = ensemble_filter(meList,tmpFilt);
    
    meanEnergyMat = cell2mat(meTapList.data{meCols.meanEnergy});
    nSubs = size(meanEnergyMat,1);    
    meanMEnergy = mean(meanEnergyMat);
    stdMEnergy  = std(meanEnergyMat)./sqrt(nSubs);
    resonFreqs  = meTapList.data{meCols.resonFreqs}{1};
    
    peakIdxs = find_peaks(meanMEnergy,params.peakFinder);
    peakFreqs = resonFreqs(peakIdxs);
    
    peakWidths = get_rp_peakWidths('rpEnergy',meanMEnergy,'resonFreqs',resonFreqs,'peakFreqs',peakFreqs);
    
    QFactor = peakFreqs./peakWidths;
    
    plotData.data{pdCols.meanResonEnergy}{end+1,1} = meanMEnergy;
    plotData.data{pdCols.stdResonEnergy}{end+1,1} = stdMEnergy;
    plotData.data{pdCols.resonatorFreqs}{end+1,1} = resonFreqs;
    plotData.data{pdCols.peakResonFreqs}{end+1,1} = peakFreqs;
    plotData.data{pdCols.peakWidths}{end+1,1} = peakWidths;
    plotData.data{pdCols.QFactor}{end+1,1} = QFactor;
    
    params.plot.legendLabels{end+1} = [params.labels{iTapCond} ...
		    sprintf(' (N=%d)',nSubs)];
    
    maxEnergy = max(meanMEnergy);
    maxThisPlot = max(maxEnergy,maxThisPlot);
    
  end
 
  
  if(~strcmp(thisStimCat,'silence'))
    stimIdx = find(stimMeanRPList.data{slCols.stimulus_id} == thisStimulusID);
    stimMeanEnergy = stimMeanRPList.data{slCols.meanEnergy}{stimIdx};
    resonFreqs     = stimMeanRPList.data{slCols.resonFreqs}{stimIdx};
    peakFreqs      = stimMeanRPList.data{slCols.peakFreqs}{stimIdx};
    
    peakWidths = get_rp_peakWidths('rpEnergy',stimMeanEnergy,'resonFreqs',resonFreqs,'peakFreqs',peakFreqs);
    QFactor = peakFreqs./peakWidths;
    
    plotData.data{pdCols.meanResonEnergy}{end+1,1} = stimMeanEnergy;
    plotData.data{pdCols.resonatorFreqs}{end+1,1} = resonFreqs;
    plotData.data{pdCols.peakResonFreqs}{end+1,1} = peakFreqs;
    plotData.data{pdCols.stdResonEnergy}{end+1,1} = [];
    plotData.data{pdCols.peakWidths}{end+1,1} = peakWidths;
    plotData.data{pdCols.QFactor}{end+1,1} = QFactor;
    params.plot.legendLabels{end+1} = 'stimulus';
  end

  
  if(~strcmp(thisStimCat,'silence'))
    %normalize the stimulus RP based on the tapping RP, so that we
    %can more easily compare the graphs.
    normRatio = maxThisPlot/max(plotData.data{pdCols.meanResonEnergy}{end,1});
    plotData.data{pdCols.meanResonEnergy}{end,1} = ...
	plotData.data{pdCols.meanResonEnergy}{end,1}*normRatio;

    params.dispPeaks.header = upper({params.labels{:} 'stimulus'});
    params.plot.plotStd = setParams.plot.plotStd;
    params.plot.lineSpec  = setParams.plot.lineSpec;
  else
    params.plot.plotStd = setParams.plot.plotStd(1:end-1);
    params.plot.lineSpec  = setParams.plot.lineSpec(1:end-1);
    params.dispPeaks.header = upper(params.labels);
  end

  params.plot.ax = get_axhandle(axh,'rectPlot_top');
  plot_meanResonEnergy(plotData,params.plot);

  params.dispPeaks.dispWidths = 1;
  params.dispPeaks.ax = get_axhandle(axh,'rectPlot_bottom');
  dispPeaks(plotData,params.dispPeaks);
   
  if(params.savePlot)
    if(confirmOverwrite)
      print('-dpsc','-append','-adobecset',plotFname);
    end
    delete(figh);
  end
  
  
end
  
  
  
outData = [];

return
