function corr_stimMeasure_x_stimMeasure(stim_st,params)
% computes a correlation matrix among all the stim measures and plots it
%
% accepts a stim_st as assigned in rhythmTap_tapping_figs
% accepts params with a single field, params.globalsFile, which points to the
% location of the globals file for the project.
%
% 3/17/2010 - First Version, Stefan Tomic
  
globalsFunc = str2func(params.globalsFile);
globals = globalsFunc();
plotPath = globals.paths.figpath;

  
measures = {'mmCoh', 'mvCoh', 'vmCoh', 'vvCoh', 'mmPred', 'mvPred',...
	    'vmPred', 'vvPred', 'mmTD', 'mvTD', 'vmTD', 'vvTD', 'mmLogFul', ...
	    'mvLogFul', 'vmLogFul', 'vvLogFul'};



nMeasures = length(measures);

stimCols = set_var_col_const(stim_st.vars);


for iMeasure = 1:nMeasures
  
  thisMeasure = measures{iMeasure};
   
  mMatrix(:,iMeasure) = stim_st.data{stimCols.(thisMeasure)};
  
end


[corrMat,pMat] = corr(mMatrix);


figure;
set(gcf,'position',[100 100 800 1000],'paperposition',[0.25 0.5 8 10]);

axes('units','pixels','position',[100 200  600 600]);

imagesc(corrMat);
axis square;

set(gca,'xtick',[1:nMeasures],'ytick',[1:nMeasures],'xticklabel',measures, ...
	'yticklabel',measures,'fontsize',6);

colorbar;

axes('position',[0 .95 1 .05],'visible','off');
text(0.5,0,'Correlation matrix of stim measures','fontsize',16,'fontweight', ...
     'bold','horizontalalignment','center');

plotFullpath = fullfile(plotPath,'corr_mat_stim_measures.ps');

print('-dpsc',plotFullpath);