function outData = plotIOIHist(inData,params)
%
% plots an ioi histogram (from tappingStats_v2 function)
%
% ioi_hist can be passed in as a matrix, where each row corresponds
% to a histogram set. This is useful when wanting to plot multiple
% histograms that have the same bin size on the same axes
%
% params:
%   ax_handle
%   squeezeLims
%   graphType
%   displayColorBar
%   colorBarLabel 
%   xLim
%   yLim
%   xlabel
%   ylabel
%   infoBox
%
% lots of code copied from graph_ioiHistByTrialSet (which works on
% an older data structure)
%
% 12 July, 2007 Stefan Tomic

histInfo = inData;
histInfoCols = set_var_col_const(histInfo.vars);


histMat = histInfo.data{histInfoCols.ioi_hist};
histBinCenters = histInfo.data{histInfoCols.hist_bin_centers};
binSize = histInfo.data{histInfoCols.hist_bin_size};
ioi = histInfo.data{histInfoCols.ioi};

%take out 0's at the edges if this was set
if(isfield(params,'squeezeLims') && params.squeezeLims)
  
  %sum across multiple histograms, if multiple rows were passed in
  sumHistMat = sum(histMat,1);
  lowIdx = find(sumHistMat ~= 0,1);
  highIdx = find(sumHistMat ~= 0,1,'last');
  
  histBinCenters = histBinCenters(lowIdx:highIdx);
  histMat = histMat(lowIdx:highIdx,:);
  
end

if(~isfield(params,'graphType'))
  params.graphType = 'bargraph';
end

switch(params.graphType)
 case 'image'
  imagesc(histBinCenters,1:size(histMat',1),histMat');
  h_main = params.ax_handle;
  if(isfield(params,'displayColorbar') && params.displayColorbar)
    h_cb = colorbar;
    ylabel(h_cb,params.colorbarLabel);
  end
  
 case 'bargraph'
  bar(histBinCenters,histMat);
  h_main = params.ax_handle;
  if(isfield(params,'displayColorbar') && params.displayColorbar)
    h_cb = colorbar;
    set(h_cb,'ytick',1:size(histMat,2));
    ylabel(h_cb,'Trial Order');
  end
  
  if(isfield(params,'xLim') &  ~isempty(params.xLim))
    setXLim = params.xLim;
  else
    setXLim = [min(histBinCenters) max(histBinCenters)];
  end
  
  if(isfield(params,'yLim') & ~isempty(params.yLim))
    setYLim = params.yLim;
  else
    setYLim = [min(histMat(:)) max(histMat(:))]*1.1;
  end
  
 
  set(h_main,'xlim',setXLim);
  set(h_main,'ylim',setYLim);
  
  
end 

if(isfield(params,'xlabel'))
  xlabel(h_main,sprintf(params.xlabel));
end

if(isfield(params,'ylabel'))
  ylabel(h_main,sprintf(params.ylabel));
end

if(isfield(params,'title'))
  title(sprintf(params.title));
end

if(isfield(params,'infoBox') & ~isempty(params.infoBox))
  
  infoBoxText = '';
  numBoxLines = 0;
  
  if(ismember('FWHM',params.infoBox))
    if(size(histMat,1) == 1)
      p_FWHM.binCenters = histBinCenters;
      p_FWHM.binWidth = binSize;
      FWHM = fullWidthHalfMax(histMat,p_FWHM);
      infoBoxText = [infoBoxText sprintf('FWHM = %.3f\n',FWHM)]; 
      numBoxLines = numBoxLines + 1;
    end
  end
  
  
  if(ismember('std',params.infoBox))
    if(size(histMat,1) == 1)
      
      %only take the stdDev of iois represented in this graph
      ioiRange = [(setXLim(1) - binSize/2) (setXLim(2) + binSize/2)];
      ioi_thisGraph = ioi(find((ioi > ioiRange(1)) & (ioi < ioiRange(2))));
      
      stdDevVal = std(ioi_thisGraph);
      infoBoxText = [infoBoxText 'stdev = ' sprintf('%.3f\n',stdDevVal)];
      numBoxLines = numBoxLines + 1;
    end
  end
  
  if(ismember('varAboutPeak',params.infoBox))
    if(size(histMat,1) == 1)
      varAboutPeak = histInfo.data{histInfoCols.var_about_peak};
      infoBoxText = [infoBoxText 'var_about_peak = ' ...
		     sprintf(' %.3f\n',varAboutPeak)];
    
    end
  end
  
  infoBoxText = strrep(infoBoxText,'_','\_');
  h_infoBox = text(0.73,(0.9-0.06*numBoxLines),infoBoxText,'units','normalized');
  
end


outData = [];

return
