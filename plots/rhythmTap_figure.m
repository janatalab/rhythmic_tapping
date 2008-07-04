function [fig_h,ax_h] = rhythmTap_figure(params)

if(isfield(params,'figh'))
  fig_h = figure(figh);
else
  fig_h = figure;
end

ax_h = [];

if(~isfield(params,'figSize'))
  params.figSize = 'letter';
end

switch(params.figSize)
 case 'letter'
  set(fig_h,'units','inches');
  set(fig_h,'position',[1 1 8 10.5]); 
  set(fig_h,'paperposition',[0.25 0.25 8 10.5]); 
 case 'ipod'
  set(fig_h,'units','pixels');
  set(fig_h,'position',[100 100 640 480]);
end

%assign a title to the figure
if(isfield(params,'plotTitle'))
  titleStr = strrep(params.plotTitle,'_','\_');
  axes('position',[0.5 0.95 0.1 0.02],'visible','off');
  txt_h = text(0.5,0.5,titleStr);
  set(txt_h,'HorizontalAlignment','center','FontWeight','bold', ...
	    'FontSize',14);
end

if(~isfield(params,'aspect'))
  params.aspect = 'rectangle';
end
  
if(ismember('squarePlot_bottom',params.axLocs))
  dims = [0.13 0.1 0.775 0.775];
  ax_h(end+1) = axes('position',dims);
  axis square
  set(ax_h(end),'tag','squarePlot_bottom');
end
    
if(ismember('rectPlot_top',params.axLocs))
  dims = [0.13 0.47 0.775 0.34];
  ax_h(end+1) = axes('position',dims);
  set(ax_h(end),'tag','rectPlot_top');
end

if(ismember('rectPlot_bottom',params.axLocs))
  ax_h(end+1) = axes('position',[0.13 0.10 0.775 0.34]);
  set(ax_h(end),'tag','rectPlot_bottom');
end

if(ismember('infoBox_top',params.axLocs))
  ax_h(end+1) = axes('position',[0.13 0.81 0.775 0.1]);
  set(ax_h(end),'tag','infoBox_top');
  set(ax_h(end),'visible','off');
end

if(ismember('movie_img',params.axLocs))
  ax_h(end+1) = axes('position',[0 0 1 1]);
  set(ax_h(end),'tag','movie_img');
end

if(ismember('movie_tapdata',params.axLocs))
  img_h = get_axhandle(ax_h,'movie_img');
  set(img_h,'position',[0 0 1 .8]);
  ax_h(end+1) = axes('position',[0 .8 1 .2]);
  set(ax_h(end),'tag','movie_tapdata');
  set(ax_h(end),'xtick',[],'ytick',[],'ydir','reverse');
end

%need to fix subplot ax_h indices
if(ismember('subplot',params.axLocs))
  nRows = params.nRows;
  nCols = params.nCols;
    
  for iRow = 1:nRows
    
    for iCol = 1:nCols
      ax_h(iRow,iCol) = subplot(nRows,nCols,(iRow-1)*nCols + iCol);
      axPos = get(ax_h(iRow,iCol),'position');
      axPos(2) = axPos(2) - 0.05;
      set(ax_h(iRow,iCol),'position',axPos);
      axis square
      
      if(isfield(params,'colLabels') && (iRow == 1))
	axPos = get(ax_h(1,iCol),'position');
	axPos(1) = axPos(1)+axPos(3)/2 -0.04;
	axPos(2) = axPos(2) + axPos(4) + .02;
	axPos(3) = 0.08;
	axPos(4) = 0.02;
	ax_lbl_h = axes('position',axPos,'visible','off');
	txt_h = text(0.5,0.5,params.colLabels{iCol});
	set(txt_h,'HorizontalAlignment','center','VerticalAlignment','middle','FontWeight','bold');
	
      end
      
      if(iRow == 1 && iCol == 1)
	if(isfield(params,'xLabel'))
	  xlabel(ax_h(1,1),params.xLabel);
	end
	if(isfield(params,'yLabel'))
	  ylabel(ax_h(1,1),params.yLabel);
	end
      end
      
    end
    
    %display row labels
    if(isfield(params,'rowLabels'))
      axPos = get(ax_h(iRow,1),'position');
      axPos(1) = 0.01;
      axPos(2) = axPos(2) + axPos(4)/2;
      axPos(3) = 0.08;
      axPos(4) = 0.02;
      ax_lbl_h = axes('position',axPos,'visible','off');
      txt_h = text(0.5,0.5,params.rowLabels{iRow});
      set(txt_h,'HorizontalAlignment','center','VerticalAlignment','middle','FontWeight','bold');
    end
    
  end
  
end   


return
