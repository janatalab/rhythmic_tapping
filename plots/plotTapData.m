function outData = plotTapData(inData,params)

if(~isfield(params,'lineWidth'))
  params.lineWidth = .5;
end


audArray = inData;
audArrayCols = set_var_col_const(audArray{1}.vars);
axh = params.axh;
axImgH = params.axImgH;
xlimAx = get(axImgH,'xlim');

axes(axh);
set(axh,'color',params.axColor);

hold on;
wvfPlotNum = 1;
  
wvfFs = audArray{1}.data{audArrayCols.Fs}(1);
  
for iAudGroup = 1:length(audArray)
  audStruct = audArray{iAudGroup};
  thisWvf = audStruct.data{audArrayCols.wvf};
  if(iscell(thisWvf))
    thisWvf = thisWvf{1};
  end
  thisWvfFs = audStruct.data{audArrayCols.Fs};
  

  %thisColor = [1 0 0]*(mod(iAudGroup-1,2));
  thisColor = params.lineColor(iAudGroup,:);
  
  if(~isempty(thisWvf))
    
    nRows = size(thisWvf,1);
    for iRow = 1:nRows
      yMin = (iRow - 1)/nRows;
      yMax = iRow/nRows;
      wvfPointsX = repmat(find(thisWvf(iRow,:)),2,1)./wvfFs;
      wvfPointsY = [yMin ; yMax] * ones(1,size(wvfPointsX,2));
      plot(wvfPointsX,wvfPointsY,'Color',thisColor,'lineWidth',params.lineWidth);
    end
    
 
  end
end
  
set(gca,'xlim',xlimAx);
set(gca,'ylim',[0 1]);


return
