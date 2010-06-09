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

timeNow = strrep(datestr(now,'mm-dd-yy_HHMM'),' ','');

globalsFunc = str2func(params.globalsFile);

globals = globalsFunc();

plotPath = globals.paths.figpath;

measures2plot = params.measures2plot;
nMeasures = length(measures2plot);
respCols = set_var_col_const(resp_st.vars);

tappingConds = unique(resp_st.data{respCols.tapping_condition});
nTapConds = length(tappingConds);


[stimIDs,lookupIdx] = unique(resp_st.data{respCols.stimulus_id});
silenceID = globals.ensemble.silence_stim_id;
[stimIDs,lookupIdx2] = setdiff(stimIDs,silenceID);
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


stimCats = resp_st.data{respCols.stimulus_category}(lookupIdx);
stimCats = stimCats(lookupIdx2);

uniqueStimCats = unique(stimCats);
nStimCats = length(uniqueStimCats);

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
 
    for iStim = 1:nStims
	
      thisStimID = stimIDs(iStim);
    
      thisStimIdxs = find(resp_st.data{respCols.stimulus_id} == thisStimID);
      
      thisStimMeasureVals = resp_st.data{respCols.(thisMeasure)}(thisStimIdxs);
      if(~all(diff(thisStimMeasureVals) == 0))
	error(sprintf('not all %s measures for stim ID %d were equal',thisMeasure,thisStimID));
      end
      measureVals(iStim,1) = thisStimMeasureVals(1);
      ratingVals = log2(resp_st.data{qIdx}(thisStimIdxs)) + 1;
      avgRatings(iStim,1) = nanmean(ratingVals);
    end
    
    [rVal,pVal] = corr(avgRatings,measureVals);
    axes;
    
    for iStimCat = 1:nStimCats
      
      thisStimCat = uniqueStimCats{iStimCat};
      maskThisCat = strcmp(thisStimCat,stimCats);
      
      switch(thisStimCat)
	
       case 'high_groove'
	plotSpec = 'og';
       case 'mid_groove'
	plotSpec = 'ob';
       case 'low_groove'
	plotSpec = 'or';
      end
     
      plot(avgRatings(maskThisCat),measureVals(maskThisCat),plotSpec);
      hold on;
    end
    
    %plot(avgRatings,measureVals,'ok');
    axis square;
    ylabel(strrep(thisMeasure,'_','\_'));
    xlabel('Average Rating');
    set(gca,'xlim',[1 7]);
    axPos = get(gca,'position');
    axes('position',[0 (axPos(2)-0.02) 1 0.02],'visible','off');
    text(.5,.5,sprintf('r = %.3f, p = %.3f',rVal,pVal),'horizontalalignment','center','color',[0 0 0],'fontweight','bold');
    
    plotFname = sprintf('avgRating_vs_Measure_%s_%s.ps',thisMeasure,timeNow);
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