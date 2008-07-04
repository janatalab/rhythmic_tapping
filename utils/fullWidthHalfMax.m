function FWHM = fullWidthHalfMax(histVals,params)
%
%
%
%
%
%

binCenters = params.binCenters;
binWidth = params.binWidth;


maxIdx = find(histVals == max(histVals));

halfMax = histVals(maxIdx)./2;

upperIdx = 1;
lowerIdx = 1;


while(histVals(maxIdx + upperIdx) >= halfMax)
  upperIdx = upperIdx + 1;
end

while(histVals(maxIdx - lowerIdx) >= halfMax)
  lowerIdx = lowerIdx + 1;
end

lowerLim = maxIdx - lowerIdx + 1;
upperLim = maxIdx + upperIdx - 1;


FWHM = binCenters(upperLim) - binCenters(lowerLim) + binWidth;

