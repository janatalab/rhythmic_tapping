function plot_peakIOI_vs_peakReson(inData)

maskVals1 = unique(inData{3});
maskVals2 = unique(inData{4});

%reverse the order of maskVals1 (iso and freeform tap)
maskVals1 = maskVals1(end:-1:1);



fparams.plotTitle = 'peak ITI vs. peak Reson';
fparams.nPlots = 1;
fparams.aspect = 'subplot';
fparams.nRows  = 3;
fparams.nCols  = 2;
fparams.rowLabels = strrep(maskVals2,'_','\_');
fparams.colLabels = strrep(maskVals1,'_','\_');
fparams.xLabel = 'peak ITI (s)';
fparams.yLabel = 'peak Reson Period (s)';
[figh,axh] = rhythmTap_figure(fparams);


maxLim = 0;
symbols = {'.','.','.'};
colors = {'b','b','b'};
colorNames = {'black','blue','red'};

for iMask1 = 1:length(maskVals1)
  for iMask2 = 1:length(maskVals2)
    

    
    mask1 = strcmp(inData{3},maskVals1{iMask1});
    mask2 = strcmp(inData{4},maskVals2{iMask2});
    
    useSymbol = symbols{iMask1};
    useColor = colors{iMask2};
    
    xCoords = inData{1}(mask1 & mask2);
    yCoords = inData{2}(mask1 & mask2);

    use_ax = axh(iMask2,iMask1);
    plot(use_ax,xCoords,yCoords,[useSymbol useColor]);
    
    thisXLim = get(use_ax,'Xlim');
    thisYLim = get(use_ax,'YLim');
    
    maxLim = max([maxLim thisXLim(2) thisYLim(2)]);
    
  end
end

xlabel('peak ITI');
ylabel('peak Reson');

for iRow = 1:size(axh,1)
  for iCol = 1:size(axh,2)
    subax = axh(iRow,iCol);
    set(subax,'XLim',[0 maxLim]);
    set(subax,'YLim',[0 maxLim]);
    set(subax,'XTick',[0:.5:maxLim]);
    set(subax,'YTick',[0:.5:maxLim]);
  end
end

%label_axes = axes('position',[0.13 0.8 0.775 0.12],'xlim',[0 1],'ylim',[0 1]);
%set(gca,'visible','off');
%hold on
%for iMask1 = 1:length(maskVals1)

%  plot(0.1,1-0.2*iMask1,['k' symbols{iMask1}]);
%  text(0.12,1-0.2*iMask1,strrep(sprintf('= %s',maskVals1{iMask1}),'_','\_'));
  
%end

%for iMask2 = 1:length(maskVals2)

%  text(0.3,1-0.2*iMask2,strrep(sprintf('%s = %s',colorNames{iMask2},maskVals2{iMask2}),'_','\_'));
  
%end



return
