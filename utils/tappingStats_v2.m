function tapping_stats = tappingStats_v2(midiInfo,params)
%
% Calculates various tapping stats for an nmat obtained from
% tapping midi data
%
%
%
% 15 Dec, 2006 first version, S.T.

if(~isfield(params,'normalizeByPeakIOI'))
  params.normalizeByPeakIOI = 0;
end


midiInfoCols = set_var_col_const(midiInfo.vars);

tapping_stats = ensemble_init_data_struct;
tapping_stats.vars = {'params','both','left','right'};
tapping_stats_cols = set_var_col_const(tapping_stats.vars);

tapping_stats.data{tapping_stats_cols.params} = params;

tsHand = ensemble_init_data_struct;
tsHand.vars = {'ioi','ioi_hist','hist_bin_size','hist_bin_centers','var_about_peak','num_peaks'};
tsHandCols = set_var_col_const(tsHand.vars);

for iHand = [tapping_stats_cols.both tapping_stats_cols.left tapping_stats_cols.right]

  tapping_stats.data{iHand} = tsHand;

end

nmat = midiInfo.data{midiInfoCols.nmat};
if(iscell(nmat))
    nmat = nmat{1};
end

if(~isempty(nmat))
  
  leftMidiNote = params.midi.leftHandMidiNote;
  rightMidiNote = params.midi.rightHandMidiNote;
  
  
  bothHands_nmat = nmat(find(ismember(nmat(:,4),[leftMidiNote rightMidiNote])),:);
  leftHand_nmat = nmat(find(nmat(:,4) == leftMidiNote),:);
  rightHand_nmat = nmat(find(nmat(:,4) == rightMidiNote),:);
  ioiBoth = diff(bothHands_nmat(:,6),1,1);
  ioiBoth(find(ioiBoth < params.ioiMinThresh)) = [];

  ioiLeft =  diff(leftHand_nmat(:,6),1,1);
  ioiLeft(find(ioiLeft < params.ioiMinThresh)) = [];

  ioiRight = diff(rightHand_nmat(:,6),1,1);
  ioiRight(find(ioiRight < params.ioiMinThresh)) = [];

else
  ioiBoth = [];
  ioiLeft = [];
  ioiRight = [];
end

tapping_stats.data{tapping_stats_cols.both}.data{tsHandCols.ioi} = ioiBoth;
tapping_stats.data{tapping_stats_cols.left}.data{tsHandCols.ioi} = ioiLeft;
tapping_stats.data{tapping_stats_cols.right}.data{tsHandCols.ioi} = ioiRight;

%process all hand combos (both, left, and right)
for iHand = [tapping_stats_cols.both tapping_stats_cols.left tapping_stats_cols.right]

  %initialize the distribution vector for each calculation
  distributionVector = [params.ioiHistBinLim(1):params.ioiHistBinSize:params.ioiHistBinLim(2)];
  
  handStats = tapping_stats.data{iHand};
  
  ioi = handStats.data{tsHandCols.ioi};
  
  %get rid of iois that are outside of histBinLims
  ioi(find( ioi < min(distributionVector) | ioi > max(distributionVector))) = [];
  
  if(~isempty(ioi))
    ioiHist = hist(ioi,distributionVector);
  else
    ioiHist = zeros(size(distributionVector));;
  end
  
  peakIdx = find(ioiHist == max(ioiHist));
  peakIOI = distributionVector(peakIdx);
    
  %need to deal with the possibility of multiple peakIOIs here
  %if there were multiple max values in a row, then use the mean
  %max value. Otherwise, if there were multiple max values that
  %were not consecutive, take the lowest IOI value as the peak.
  if(length(peakIOI) > 1)
    %see if they were consecutive
    if(all(diff(peakIdx) == 1))
      peakIOI = mean(peakIOI);
    else
      %if not consecutive, use the lowest index (peak in the
      %lowest bin)
      peakIdx = min(peakIdx);
      peakIOI = distributionVector(peakIdx);
	
    end
    
  end

  histBinSize = abs(distributionVector(2) - distributionVector(1));
  
  %if normalizing, then scale the iois by the peak ioi and
  %recalculate the histogram
  if(params.normalizeByPeakIOI && ~isempty(ioi))
    %now normalize by the peakIOI
    ioi = ioi./peakIOI;
    
    %get rid of iois that are outside of histBinLims
    ioi(find( ioi < min(distributionVector) | ioi > max(distributionVector))) = [];
    
    %we've scaled the ioi's by the peakIOI (thereby normalizing them)
    %we'll leave distributionVector alone use it as is. It's
    %now just going to represent multiples of peakIOI rather than seconds
    %Hopefully it has an OK range (so far [0 : 0.1 : 3] has been used). It's important for the
    %distributionVectors of all the calculations to be the same, so
    %that we can easily compare normalized histograms.
    
    ioiHist = hist(ioi,distributionVector);
    stdCenter = 1;
    stdRange = params.stdev.range;
    
  elseif(~params.normalizeByPeakIOI && ~isempty(ioi))
    stdCenter = peakIOI;
    stdNBins = params.stdev.nBins;
    stdRange = [(stdCenter - stdNBins*histBinSize) (stdCenter + stdNBins*stdNBins)];
  end
  
  handStats.data{tsHandCols.ioi_hist} = ioiHist;
  handStats.data{tsHandCols.hist_bin_centers} = distributionVector;
  handStats.data{tsHandCols.hist_bin_size} = histBinSize;
 
  if(~isempty(ioi))
    handStats.data{tsHandCols.var_about_peak} = stdAboutPeak(ioi,stdRange);
  else
    handStats.data{tsHandCols.var_about_peak} = 0;
  end
  
  handStats.data{tsHandCols.num_peaks} = numPeaks(ioiHist);
  
  tapping_stats.data{iHand} = handStats;
  
end

return


%find the number of peaks in ioiHist
function num_peaks = numPeaks(ioiHist)

diffHist =  diff(ioiHist);
lenDiffHist = length(diffHist);

% only interested in places where peaks are non-zero (it's possible
% to have a peak where two bins have equal values and the slope at
% the top is flat. So we're just going to look at the nearest
% places where the slope is non-zero
diffHistNZIdxs = find(diffHist ~= 0);
diffHistNZ = diffHist(diffHistNZIdxs);

% if a positive slope is followed by a negative slope, then we
% found a peak
num_peaks = sum((diffHistNZ(1:end-1) > 0) & (diffHistNZ(2:end) < 0));

% the last non-zero slope is positive, then there is a peak at the
% end that we have to catch
if(~isempty(diffHistNZ) && diffHistNZ(end) > 0)
  num_peaks = num_peaks + 1;
end

% likewise, if there is a negative slope at the beginning, there is
% a peak at the beginnning to catch.
if(~isempty(diffHistNZ) && diffHistNZ(1) < 0)
  num_peaks = num_peaks + 1;  
end


return






%calculate the standard deviation of iois in some range
function result = stdAboutPeak(ioi,range)

useIoi = ioi( find( ioi > range(1) & ioi < range(2)) );

%deal with strangeness of (empty matrix) vs. []
if(isempty(useIoi))
  useIoi = [];
end


result = std(useIoi);


return
