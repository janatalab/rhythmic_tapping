function outData = corr_resp_vs_stim(inData,params)


params.sets = {'free_form_tap' 'iso_tap'};
params.silence_stimID = 6497;
params.plotFname = 'corr_meanResp_vs_stim_24July.ps';
params.plotPath = '/data2/rhythm/rhythmic_tapping_v2/plots/resp_rp/mmp_resp_vs_stim';

plotFPath = fullfile(params.plotPath,params.plotFname)

confirm_overwrite_file(plotFPath);

sets = params.sets;

nSets = length(sets);
inDataCols = set_var_col_const(inData.vars);

stimulusIDs = inData.data{inDataCols.stimulus_id};
silenceStim = find(stimulusIDs == params.silence_stimID);
stimulusIDs(silenceStim) = [];
nStims = length(stimulusIDs);

stimMPPs = inData.data{inDataCols.stimulus};

%obtain coefficients for butterworth high pass filter
[b,a] = butter(3,.15,'high');

for iTap = 1:nStims
  
    for iSet = 1:nSets

      setMPPs = inData.data{inDataCols.(sets{iSet})};
      setMPPs(silenceStim,:) = [];
              
      thisTapMPP = setMPPs(iTap,:);
      
      %high pass filter mpp
      thisTapMPP = filtfilt(b,a,thisTapMPP);
      
      for iStim = 1:nStims
	stimMPP = stimMPPs(iStim,:);
	
	%high pass filter mpp
	stimMPP = filtfilt(b,a,stimMPP);
	
	[c,p] = corr(thisTapMPP',stimMPP');
      
	corrList(iStim,iSet) = c;
	pList(iStim,iSet) = p;
      end
      correctCorr = corrList(iTap,iSet);
      correctP = pList(iTap,iSet);
      
      percentiles(iTap,iSet) = sum(corrList(:,iSet) <= correctCorr)./length(corrList(:,iSet));
    
      %plot a histogram
      if(mod(iSet-1,2) == 0)
	figure;
	set(gcf,'position',[100 100 800 1000],'paperposition',[0.5 0.5 8 10]);    
      end
      axH = subplot(2,1,mod(iSet-1,2)+1);
      [corrHist,corrBins] = hist(axH,corrList(:,iSet),[0:.025:1]);
      bar(axH,corrBins,corrHist,'b');
      binDiffs = abs(correctCorr - corrBins);
      binWidth = min(diff(corrBins));
      binIdx = find(binDiffs == min(binDiffs));
      hold on;
      
      correctOnly = zeros(size(corrHist));
      correctOnly(binIdx) = corrHist(binIdx);
      bar(corrBins,correctOnly,'r');
      
      %note hardcoding of ylim here. Might want to change this later.
      set(axH,'xlim',[0 1],'ylim',[0 10]);
      ylim = get(axH,'ylim');
      text(0.7,ylim(2)*0.9,sprintf('Correct Corr: %.2f, p: %.4f',correctCorr,correctP));
      text(0.7,ylim(2)*0.85,sprintf('Percentile: %.2f',percentiles(iTap,iSet)*100));
      title(strrep(sets{iSet},'_',' '));
      titleAx = axes('position',[0,0.95,1,0.05],'visible','off','xlim',[0 1],'ylim',[0 1]);
      artist = inData.data{inDataCols.artist}{iTap};
      songTitle = inData.data{inDataCols.song_title}{iTap};
      headerText = sprintf('Stimulus ID %d\n %s - %s',stimulusIDs(iTap),artist,songTitle);
      text(0.5,0.5,headerText,'horizontalalignment','center',...
	   'fontsize',14,'fontweight','bold');
    
      if(mod(iSet,2) == 0)
	print('-dpsc','-append',plotFPath);
	close(gcf);
      end
     
    end

end

disp(sprintf('%s Percentile mean: %.2f, std: %.2f',sets{1},mean(percentiles(:,1)),std(percentiles(:,1))));
disp(sprintf('%s Percentile mean: %.2f, std: %.2f',sets{2},mean(percentiles(:,2)),std(percentiles(:,2))));

outData = [];
