% poststim_question_fig.m
%
% Used in conjunction with rhythmTap_tapping_figs.m

curr_vars = question_vars(seven_point_mask);
varmask = ismember(vars2analyze, curr_vars);

nfig = 0;

%% Matrix of plots
% stimulus category X tapping condition matrix, with all questions in each
% plot
nfig = nfig+1;
figure(nfig), clf

for icat = 1:nstimcats
  curr_cat = groove_plot_order{icat};
  curr_cat_idx = strmatch(curr_cat,stimcats,'exact');
  
  for icond = 1:ntapconds
    if strcmp(curr_cat,'silence') && strcmp(tapconds{icond},'no_tap')
      continue
    end
    
    subplot(nstimcats,ntapconds,(icat-1)*ntapconds+icond)
    
    bh = bar(summary.group.nanmean{curr_cat_idx,icond}(varmask));
    errorbar_data = ...
      summary.group.nanmean{curr_cat_idx,icond}(varmask)./...
      sqrt(summary.group.nsub{curr_cat_idx,icond}(varmask));
    add_errorbars(bh,errorbar_data');
    
    set(gca,'ylim',[1 7],'ytick',1:7)
    set(gca, 'xlim', [0 nquest+1])
    
    if icond == 1
      ylabel(strrep(stimcats{curr_cat_idx},'_','\_'))
    end
    if icat == 1
      title(strrep(tapconds{icond},'_','\_'))
    end
    if icat == nstimcats
      set(gca,'xticklabel', '')
      for iq = 1:nquest
        text(iq,0,quest_subset(iq).question_text,'rotation',-90);
      end
    else
      set(gca,'xticklabel', '')
    end
    
  end % for icond=
end % for icat =

append_str = '';
figfname = fullfile(globals.paths.figpath,'tapping_poststim_question_summary.ps');
fprintf('Printing figure %d to %s\n', nfig, figfname);
print(figfname,'-dpsc','-adobecset',append_str);

%% By question
nfig = nfig+1;
figure(nfig), clf
colormap(gray)

nquest = length(curr_vars);
ncols = 3;
nrows = ceil(nquest/ncols);

for iquest = 1:nquest
  curr_var = curr_vars{iquest};
  varmask = ismember(vars2analyze, curr_var);
  
  switch curr_var
    case {'compqid_207_1', 'compqid_493_1'}
      curr_stimcats = {'low_groove','mid_groove','high_groove'};
      curr_catlabels = {'Low','Mid','High'};
      curr_tapconds = {'no_tap','iso_tap','free_form_tap'};
      curr_taplabels = {'None','Iso','Free'};
    case {'compqid_494_1','compqid_498_1'}
      curr_stimcats = {'silence','low_groove','mid_groove','high_groove'};
      curr_catlabels = {'Silence','Low','Mid','High'};
      curr_tapconds = {'iso_tap','free_form_tap'};
      curr_taplabels = {'Iso','Free'};
    case {'compqid_505_1'}
      curr_stimcats = {'silence','low_groove','mid_groove','high_groove'};
      curr_catlabels = {'Silence','Low','Mid','High'};
      curr_tapconds = {'no_tap','iso_tap','free_form_tap'};
      curr_taplabels = {'None','Iso','Free'};
     
    otherwise
      continue
  end
  
  % Extract the data
  meandata = nan(length(curr_stimcats),length(curr_tapconds));
  semdata = nan(length(curr_stimcats),length(curr_tapconds));
  for icat = 1:length(curr_stimcats)
    catidx = strmatch(curr_stimcats{icat}, summary.stimcats,'exact');
    
    for icond = 1:length(curr_tapconds)
      condidx = strmatch(curr_tapconds{icond}, summary.tapconds, 'exact');
      
      meandata(icat,icond) = summary.group.nanmean{catidx,condidx}(varmask);
      semdata(icat,icond) = summary.group.nanstd{catidx,condidx}(varmask) / ...
        sqrt(summary.group.nsub{catidx,condidx}(varmask));
    end
  end % for icat=
  
  % Plot the data
  subplot(nrows,ncols,iquest)
  bh = bar(meandata);
  add_errorbars(bh,semdata,'k')
  set(gca,'ylim',[1 7])
  set(gca,'ytick',1:7)
  ylabel('Rating')
  
  set(gca,'xlim',[0 length(curr_stimcats)+1])
  set(gca,'xtick',1:length(curr_stimcats))
  set(gca,'xticklabel', curr_catlabels)
  xlabel('Groove Category')
  legend(strrep(curr_taplabels,'_','\_'),'location','northwest','orientation','vertical')
  title(linewrap(quest_subset(iquest).question_text,40))
  
  axis square
end % for iquest

% Print the figure
append_str = '';
figfname = fullfile(globals.paths.figpath,'tapping_poststim_question_summary_by_question.ps');
fprintf('Printing figure %d to %s\n', nfig, figfname);
print(figfname,'-dpsc','-adobecset',append_str);
