function report = plot_summaryIOIHistByTrialType(sess,params)
%
%
% produces a subplot grid of ioi Histograms for each trial
% type, summed across all subjects for each trial type.
%
% This function essentially reorganizes all of the events from all
% sessions into a single event struct array, normalizes IOI
% calculations by peak IOI or by stimulus tempo, then calls
% graph_ioiHistByTrialSetGrid to produce the subplot grid for each
% trial type on a single figure.
%
%  S.T. 23 Feb 2007

tappingStatsIdx = params.tsIdx;
processEvents = {};
addToTitle = '';
addToXlabel = '';

for isess = 1:length(sess)
  for ievent = 1:length(sess{isess}.data)
  
    thisEvent = sess{isess}.data{ievent};

    %only process if this is a response type event
    %and tapping stats exist for the event
    if(strcmp('resp',thisEvent.data{1}.type) & ...
      length(thisEvent.data{1}.data) >= tappingStatsIdx)
     
      if(isfield(params,'normalize'))
	 
	addToXlabel = '\n(normalized)';
	
	switch params.normalize
	 case 'peak_ioi'
	  
	  %find the peak IOI for this trial
	  thisEventHistStats = thisEvent.data{1}.data{tappingStatsIdx};
	  maxIOIIdx = find(thisEventHistStats.ioiHist == ...
			   max(thisEventHistStats.ioiHist),1);
	  IOIScaleFactor = thisEventHistStats.ioiHistBinCenters(maxIOIIdx);
	  
	  leftHand_maxIOIIdx = find(thisEventHistStats.leftHand_ioiHist == ...
			   max(thisEventHistStats.leftHand_ioiHist),1);
	  left_IOIScaleFactor = thisEventHistStats.ioiHistBinCenters(leftHand_maxIOIIdx);
	  
	  rightHand_maxIOIIdx = find(thisEventHistStats.rightHand_ioiHist == ...
			   max(thisEventHistStats.rightHand_ioiHist),1);
	  right_IOIScaleFactor = thisEventHistStats.ioiHistBinCenters(rightHand_maxIOIIdx);
	  
	  %if highest IOI was 0 (there was no tapping), then just
          %use a scale factor of 1
	  if(IOIScaleFactor == 0)
	    IOIScaleFactor = 1;
	  end

	  if(left_IOIScaleFactor == 0)
	    left_IOIScaleFactor = 1;
	  end
	  
	  if(right_IOIScaleFactor == 0)
	    right_IOIScaleFactor = 1;
	  end
	  
	  
	  
	  
	 case 'stim_tempo'
	  thisStimID = thisEvent.data{1}.stim_id;
	  
	  tempoIdx = find(params.stimTempo(:,1) == thisStimID);
	  
	  if(~isempty(tempoIdx))
	  
	    thisStimTempo = params.stimTempo(tempoIdx,2);
	    tactusIOIsec = 1/thisStimTempo*60;
	    IOIScaleFactor = tactusIOIsec;
	    left_IOIScaleFactor = IOIScaleFactor;
	    right_IOIScaleFactor = IOIScaleFactor;
	  else
	    
	    %if no stim tempo info exists, just use scale factor of
            %1. This is assuming a silence stim.
	    IOIScaleFactor = 1;
	    left_IOIScaleFactor = IOIScaleFactor;
	    right_IOIScaleFactor = IOIScaleFactor;
	    
	  end
	  

	end %switch
	
	%recalculate the ioi histogram with normalization parameters
	p_normHist.leftHandMidiNote = params.leftHandMidiNote;
	p_normHist.rightHandMidiNote = params.rightHandMidiNote;
	p_normHist.IOIScaleFactor = IOIScaleFactor;
	p_normHist.left_IOIScaleFactor = left_IOIScaleFactor;
	p_normHist.right_IOIScaleFactor = right_IOIScaleFactor;
	p_normHist.ioiMinThresh = params.ioiMinThresh;
	p_normHist.ioiHistBinSize =params.ioiHistBinSize;
	p_normHist.ioiHistBinLim = params.ioiHistBinLim;
	normalizedIOIHist = tappingStats(thisEvent.data{1}.data{1},p_normHist);
	thisEvent.data{1}.data{tappingStatsIdx} = normalizedIOIHist;
	
      end %if params.normalize
      
      %add this event to the master list of events to send to the
      %plotting function
      processEvents{end+1} = thisEvent;      
	  
    end
   
  end
end

addToTitle = {};
addToFilename = {};

if(~isempty(params.hand) & strcmp(params.hand,'left'))
  addToTitle{end+1} = ' - Left Hand';
  addToFilename{end+1} = '_leftHand';
elseif(~isempty(params.hand) & strcmp(params.hand,'right'))
  addToTitle{end+1} = ' - Right Hand';
  addToFilename{end+1} = '_rightHand';
end

if(isfield(params,'normalize') & strcmp(params.normalize,'peak_ioi'))
  addToTitle{end+1} = '\n(normalized by peak IOI)';
  addToFilename{end+1} = '_normByPeakIOI';
elseif(isfield(params,'normalize') & strcmp(params.normalize,'stim_tempo'))
  addToTitle{end+1} = '\n(normalized by stimulus tempo)';
  addToFilename{end+1} = '_normByStimTempo';  
end


if(isfield(params,'graphDescript'))
  addToFilename{end+1} = ['_' params.graphDescript];
end

figTitle = ['Summary IOI Histograms by Trial Category' addToTitle{:}];


p_graph_ioiHistByTrialSetGrid = graph_ioiHistByTrialSetGrid_params('trialSetNames',params.trialSetNames,...
						  'combineHists',1,...
						  'trialSets',params.trialSets,...
						  'tsIdx',tappingStatsIdx,...
						  'title',figTitle,...
						  'hand',params.hand,...
						  'graphType','bargraph',...
						  'squeezeLims',0,...
						  'xlabel',['IOI' addToXlabel],...
						  'ylabel','num of occurrences',...
						  'rowLabels',params.rowLabels,...
						  'colLabels',params.colLabels,...
						  'xLim',params.xLim,...
						  'equalGraphLims',params.equalGraphLims,...
						  'displayColorbar',0,...
						  'infoBox',params.infoBox,...
						  'save',params.save,...
						  'path',params.savePath,...
						  'filename',['summaryIOI' addToFilename{:}]);
    

report = graph_ioiHistByTrialSetGrid(processEvents,p_graph_ioiHistByTrialSetGrid);

