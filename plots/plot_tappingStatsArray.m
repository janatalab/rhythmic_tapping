function outData =  plot_tappingStatsArray(inData,params)
%
% takes a trial_info data struct that contains tapping stats,
% stimulus_id, stimulus_category variables and plots each of them
% out.


trialInfo = inData;
trialInfoCols = set_var_col_const(trialInfo.vars);
nPlots = length(trialInfo.data{trialInfoCols.tapping_stats});

if(isfield(params,'savePlots') && params.savePlots)
  params.savePlots = ...
      confirm_overwrite_file(fullfile(params.plotPath,[params.plotFname '.ps']));
  if(~params.savePlots)
    fprintf('Specified plot file exists. Not saving plots');
  end
  
end


for iPlot = 1:nPlots

  thisStimulusID = trialInfo.data{trialInfoCols.stimulus_id}(iPlot);
  nTrials = trialInfo.data{trialInfoCols.nTrials}(iPlot);
  tappingCond = trialInfo.data{trialInfoCols.tapping_cond}{iPlot};
  stimCategory = trialInfo.data{trialInfoCols.stimulus_category}{iPlot};
  hand = params.hand;
  artist = trialInfo.data{trialInfoCols.artist}{iPlot};
  song_name = trialInfo.data{trialInfoCols.song_name}{iPlot};
  
  titleStr = [sprintf('Stimulus ID %d, Stimulus Category "%s"\n', ...
		   thisStimulusID,stimCategory) ...
	      sprintf('Tapping Condition %s, N = %d\n',tappingCond,nTrials) ...
	      sprintf('%s, "%s"',artist,song_name)];
  
  titleStr = strrep(titleStr,'_','\_');
  
  fig1 = figure;
  set(fig1,'units','inches');
  set(fig1,'position',[1 1 8 10.5]); 
  set(fig1,'paperposition',[0.25 0.25 8 10.5]); 
  axes('position',[0.5 0.95 0.1 0.02],'visible','off');
  txt_h = text(0.5,0.5,titleStr);
  set(txt_h,'HorizontalAlignment','center','FontWeight','bold','FontSize',14);
  hist_ax = axes('position',[0.13 0.47 0.775 0.34]);
  
  params.plot.ax_handle = hist_ax;
  params.plot.displayColorbar = 0;
  
  
  tappingStats = trialInfo.data{trialInfoCols.tapping_stats}{iPlot};
  tappingStatsCols = set_var_col_const(tappingStats.vars);
  handStats = tappingStats.data{tappingStatsCols.(hand)};
  
  plotIOIHist(handStats,params.plot);
  
  if(isfield(params,'savePlots') && params.savePlots)
    if(~isfield(params,'addToPlotFname'))
      params.addToPlotFname = '';
    end
    print('-dpsc','-append',fullfile(params.plotPath,params.plotFname));
    close(fig1);
  end
  
end

if(isfield(params,'savePlots') && params.savePlots)
  fprintf('Plots saved to %s',params.plotPath);
end
outData = [];

return
