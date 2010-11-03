% plot_summary_of_MPP_corr.m
% 
% Plots outcome of SAS analyses of correlation between stimulus and
% a response MPPs
%
% Also plots number of peaks analyses

% 24Sep2010 Petr Janata

if ~exist('rhythmTap_globals')
  addpath('../analyses');
end

params = rhythmTap_globals;

groove_order = {'low_groove','mid_groove','high_groove'};
ncat = length(groove_order);

tap_order = {'iso_tap','free_form_tap'};
ncond = length(tap_order);

analyses = {'corr','peaks'};
num_analyses = length(analyses);

for ianal = 1:num_analyses
  switch analyses{ianal}
    case 'corr'
      fstub = 'corr_analysis_summary.csv';
    case 'peaks'
      fstub = 'numpeaks_analysis_summary.csv';
  end
  
  fname = fullfile(params.paths.datapath, fstub);

  figstub = 'mpp_analysis_summary.eps';
  figfname = fullfile(params.paths.figpath, figstub);

  vars = loadtxt(fname,'nlines',1,'delim',',');
  data = loadtxt(fname,'skipline',1,'delim',',','convert','off');

  cols = set_var_col_const(vars);

  vals = cellfun(@str2num,data(:,cols.Estimate));
  errvals = cellfun(@str2num,data(:,cols.Standard_Error));

  plotdata = nan(ncat,ncond);

  for igroove = 1:ncat
    groove_mask = ismember(data(:,cols.stimulus_category), groove_order{igroove});
    
    for itap = 1:ncond
      tap_mask = ismember(data(:,cols.tapping_condition), tap_order{itap});
      
      plotdata(igroove,itap) = vals(groove_mask & tap_mask);
      errdata(igroove,itap) = errvals(groove_mask & tap_mask);
      
    end % for itap=
  end % for igroove=
  
  % Plot the data
  figure(1)
  subplot(1,2,ianal)
  set(gcf,'DefaultAxesFontSize',12, 'PaperPositionMode','auto')
  colormap(gray);
  
  bh = bar(plotdata);
  
  set(gca,'plotboxaspectratio',[5 4 1])
  add_errorbars(bh,errdata,'k');
  
  axisLabelFontSize = 14;
  
  set(gca,'xticklabel', {'Low','Mid','High'})
  xlabel('Groove Category','fontsize', axisLabelFontSize)
  ylabel('z','fontsize', axisLabelFontSize)
  
  if ianal == 2
    set(gca,'ytick',[0:2:(max(plotdata(:))+1)])
  end
  
  if ianal == 1
    legend({'Isochronous','Freeform'},'Location','NorthWest')
    legend boxoff
  end
  
  title(analyses{ianal})
  
  % save the figure
  fprintf('Saving figure to %s\n', figfname);
  print(figfname,'-deps','-adobecset');
end