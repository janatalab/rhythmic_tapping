function outData = corr_resp_vs_stim(inData,params)

try plotOverall = params.plot.plotOverall; catch plotOverall = 1; end
try plotByStim = params.plot.plotByStim; catch plotByStim = 0; end

plotFPath = fullfile(params.plotPath,params.plotFname)

write_specified = confirm_overwrite_file(plotFPath);
append_str = '';

sets = params.sets;

nSets = length(sets);
inDataCols = set_var_col_const(inData.vars);

stimulusIDs = inData.data{inDataCols.stimulus_id};
silenceStim = find(stimulusIDs == params.silence_stimID);
stimulusIDs(silenceStim) = [];
nStims = length(stimulusIDs);

stimMPPs = inData.data{inDataCols.stimulus};

% Initialize the correlation matrix
corrmat = zeros(nStims,nStims,nSets);

%obtain coefficients for butterworth high pass filter
[b,a] = butter(3,.15,'high');

% Filter the stimulus MPPs. Only need to do this once
for iMPP = 1:size(stimMPPs,1)
  stimMPPs(iMPP,:) = filtfilt(b,a,stimMPPs(iMPP,:));
end

% Look at overall distributions
for iSet = 1:nSets
  setMPPs = inData.data{inDataCols.(sets{iSet})};
  setMPPs(silenceStim,:) = [];  % remove silence MPP
  
  % Filter all of the MPPs
  for iMPP = 1:size(setMPPs,1)
    setMPPs(iMPP,:) = filtfilt(b,a,setMPPs(iMPP,:));
  end

  % Calculte the correlation matrix
  corrmat(:,:,iSet) = corr(setMPPs',stimMPPs');
end % for iSet

if plotOverall
  % Plot the cumulative distributions for each set
  figure;
  set(gcf,'position',[100 100 800 1000],'paperposition',[0.5 0.5 8 10]);
  set(gcf,'defaultaxesfontsize',11)
  for iSet = 1:nSets
    subplot(nSets,1,iSet)

    hist_spacing = [-1:0.1:1];
    % Get all the correlations that are off the diagonal and generate a
    % histogram
    other_corrs = tril(corrmat(:,:,iSet),-1);
    other_corrs = other_corrs(find(tril(ones(size(other_corrs)),-1)));
    other_hist = hist(other_corrs,hist_spacing)';

    % Values on diagonals are correlations with the same stims
    same_corrs = diag(corrmat(:,:,iSet));
    same_hist = hist(same_corrs,hist_spacing)';

    % Plot the two histograms. Plot them normalized by total number of counts
    num_other = sum(other_hist);
    num_same = sum(same_hist);

    bar_width = .9;
    label_fontsize = 12;
    h = bar(hist_spacing,[other_hist same_hist]./repmat([num_other num_same],length(same_hist),1), ...
      bar_width);
    xlabel('Correlation coefficient', 'fontsize', label_fontsize)
    ylabel('Proportion of correlations', 'fontsize', label_fontsize)

    % Add information about mean correlations
    text(0.5,0.9,sprintf('Mean same: r=%1.3f', mean(same_corrs)),...
      'units','norm','horizontalalign','center','fontsize', 11)
    text(0.5,0.85,sprintf('Mean other: r=%1.3f', mean(other_corrs)),...
      'units','norm','horizontalalign','center','fontsize', 11)

    set(gca,'xlim',[-1 1])
    title_fontsize = 14;
    switch params.sets{iSet}
      case 'free_form_tap'
        title_str = 'Freeform Tapping';
      case 'iso_tap'
        title_str = 'Isochronous Tapping';
    end
    title(title_str, 'fontsize', title_fontsize, 'fontweight', 'bold')

    legend({sprintf('Other (N=%d)', num_other), sprintf('Same (N=%d)', num_same)}, ...
      'Location','NorthWest')
  end % for iSet
  
  if write_specified
    print(plotFPath,'-dpsc2','-adobecset',append_str)
    append_str = '-append';
  end
end % if plotOverall

if plotByStim
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
        print('-dpsc',append_str,plotFPath);
        close(gcf);
      end

    end

  end

  disp(sprintf('%s Percentile mean: %.2f, std: %.2f',sets{1},mean(percentiles(:,1)),std(percentiles(:,1))));
  disp(sprintf('%s Percentile mean: %.2f, std: %.2f',sets{2},mean(percentiles(:,2)),std(percentiles(:,2))));
end % if plotByStim

outData = [];
