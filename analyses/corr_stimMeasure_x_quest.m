function corr_stimMeasure_x_quest(resp_st,quest_info,params)
%
% Correlation of stimulus timing deviation measurements (coherence, prediction,
% etc.) with post stim questions. Called from rhythmTap_tapping_figs
%
%
% 3/17/2010 - First Version, Stefan Tomic

  
  
try
  params.excludeStimID
catch
  params.excludeStimID = [];
end
  

globalsFunc = str2func(params.globalsFile);

globals = globalsFunc();

plotPath = globals.paths.figpath;

measures2plot = params.measures2plot;
nMeasures = length(measures2plot);
respCols = set_var_col_const(resp_st.vars);

tappingConds = unique(resp_st.data{respCols.tapping_condition});
nTapConds = length(tappingConds);


stimIDs = unique(resp_st.data{respCols.stimulus_id});
silenceID = globals.ensemble.silence_stim_id;
stimIDs = setdiff(stimIDs,silenceID);
nStims = length(stimIDs);

%obtain the indices in resp_st.vars that correspond to the questions in quest_info
useQIDs = [quest_info.question_id];
useSubQIDs = [quest_info.subquestion];
nQIDs = length(useQIDs);
for iQID = 1:nQIDs
  useCompQIDStr{iQID} = sprintf('compqid_%d_%d',useQIDs(iQID),useSubQIDs(iQID));
end
[dummy,questIdxs] = intersect(resp_st.vars,useCompQIDStr);
nQuests = length(questIdxs);


for iMeasure = 1:nMeasures

  thisMeasure = measures2plot{iMeasure};

  for iQuest = 1:nQuests

    qIdx = questIdxs(iQuest);
    
    qFieldname = resp_st.vars{qIdx};
    
    qStringID = regexp(qFieldname,'_','split');
    qDoubleID = str2num(qStringID{2}) + str2num(qStringID{3})*.01;
    
    qInfoIdx = find([quest_info.compqid] == qDoubleID);
    question_text = quest_info(qInfoIdx).question_text;
    
    figure;
    set(gcf,'position',[50 100 800 1000],'paperposition',[.25 .5 8 10]);
    
    %title of figure
    axes('position',[0 .95 1 .05],'visible','off');
    
    %split up question text at the parenthesis index
    %so that long questions will fit in the title
    parenIdx = strfind(question_text,'(');
    question_text1 = question_text(1:parenIdx-1);
    question_text2 = question_text(parenIdx:end);
    
    text(0.5,0.5,strrep(question_text1,'_','\_'),'HorizontalAlignment','center','fontsize',14,'fontweight','bold');
    text(0.5,0.18,strrep(question_text2,'_','\_'),'HorizontalAlignment','center','fontsize',14,'fontweight','bold');
 
    for iTapCond = 1:nTapConds
    
      thisTapCond = tappingConds{iTapCond};
      
      measuresLow = [];
      measuresMid = [];
      measuresHigh = [];
      avgRatingsLow = [];
      avgRatingsMid = [];
      avgRatingsHigh = [];

      for iStim = 1:nStims
	
	thisStimID = stimIDs(iStim);
	
	useIdxs = find(resp_st.data{respCols.stimulus_id} == thisStimID & ...
		       strcmp(resp_st.data{respCols.tapping_condition},thisTapCond));
	
	measureVals = resp_st.data{respCols.(thisMeasure)}(useIdxs);
	
	if(~all(diff(measureVals) == 0))
	  error(sprintf('not all %s measures for stim ID %d were equal',thisMeasure,thisStimID));
	end
	
	measureVal = measureVals(1);
		
	ratingVals = log2(resp_st.data{qIdx}(useIdxs)) + 1;
	avgRating = mean(ratingVals);
	
	stimCat = resp_st.data{respCols.stimulus_category}{useIdxs(1)};
  
	switch(stimCat)	  
	 case 'low_groove'
	  measuresLow(end+1,1) = measureVal;
	  avgRatingsLow(end+1,1) = avgRating;
	 case 'mid_groove'
	  measuresMid(end+1,1) = measureVal;
	  avgRatingsMid(end+1,1) = avgRating;
	 case 'high_groove'
	  measuresHigh(end+1,1) = measureVal;
	  avgRatingsHigh(end+1,1) = avgRating;
	end
	
      end
    
      if(all(isnan(avgRatingsLow)) & all(isnan(avgRatingsMid)) & all(isnan(avgRatingsHigh)))
	continue;
      end
      
      [lowCorr,lowP] = corr(avgRatingsLow,measuresLow);
      [midCorr,midP] = corr(avgRatingsMid,measuresMid);
      [highCorr,highP] = corr(avgRatingsHigh,measuresHigh);
      
      allRatings = [avgRatingsLow ; avgRatingsMid ; avgRatingsHigh];
      allMeasures = [measuresLow ; measuresMid ; measuresHigh];
      [allCorr,allP] = corr(allRatings,allMeasures);
      
      subplot(3,1,iTapCond);
      plot(avgRatingsLow,measuresLow,'or');
      ylabel(strrep(thisMeasure,'_','\_'));
      xlabel('Average Rating');
      hold on;
      plot(avgRatingsMid,measuresMid,'ob');
      plot(avgRatingsHigh,measuresHigh,'og');
      set(gca,'xlim',[1 7]);
      axPos = get(gca,'position');
      
      %tapping condition label
      axes('position',[(axPos(1)-.1) axPos(2) .05 axPos(4)],'visible','off');
      text(0,.5,strrep(thisTapCond,'_','\_'),'fontsize',12,'fontweight','bold','verticalalignment','middle','rotation',90);
     
      axes('position',[axPos(1) (axPos(2)-0.06) axPos(3) 0.05],'visible','off');
      text(.15,.3,'High Groove','horizontalalignment','center','color',[0 1 0],'fontweight','bold');
      text(.15,0,sprintf('r = %.3f, p = %.3f',highCorr,highP),'horizontalalignment','center','color',[0 1 0],'fontweight','bold') 
      
      text(.38,.3,'Mid Groove','horizontalalignment','center','color',[0 0 1],'fontweight','bold');
      text(.38,0,sprintf('r = %.3f, p = %.3f',midCorr,midP),'horizontalalignment','center','color',[0 0 1],'fontweight','bold') 
      
      text(.61,.3,'Low Groove','horizontalalignment','center','color',[1 0 0],'fontweight','bold');
      text(.61,0,sprintf('r = %.3f, p = %.3f',lowCorr,lowP),'horizontalalignment','center','color',[1 0 0],'fontweight','bold'); 
      
      text(.85,.3,'All Stims','horizontalalignment','center','color',[0 0 0],'fontweight','bold');
      text(.85,0,sprintf('r = %.3f, p = %.3f',allCorr,allP),'horizontalalignment','center','color',[0 0 0],'fontweight','bold');
      
    end
    
    plotFname = sprintf('avgRating_vs_Measure_%s.ps',thisMeasure);
    plotFullPath = fullfile(plotPath,plotFname);
    
    if(iQuest == 1)
      appendStr = '';
    else
      appendStr = '-append';
    end
    
    print('-dpsc',appendStr,plotFullPath);
    
    close gcf;
    
    
  end
end