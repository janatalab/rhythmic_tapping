% tapping_corr_tap_question_fig.m
%
% Used in conjunction with rhythmTap_tapping_figs.m

use_tap_conds = find(ismember(tapconds, {'free_form_tap','iso_tap'}));

for icat = 1:nstimcats
  curr_cat = groove_plot_order{icat};
  curr_cat_idx = strmatch(curr_cat,stimcats,'exact');

  for icond = 1:length(use_tap_conds)
    curr_cond_idx = use_tap_conds(icond);
    
    if strcmp(curr_cat,'silence') && strcmp(tapconds{curr_cond_idx},'no_tap')
      continue
    end

    xdata = summary.subject.nanmean{curr_cat_idx,curr_cond_idx}(:,var1_idx);
    ydata = summary.subject.nanmean{curr_cat_idx,curr_cond_idx}(:,var2_idx);
    
    if all(isnan(xdata)) | all(isnan(ydata))
      continue
    end
    
    subplot(nstimcats,length(use_tap_conds),(icat-1)*length(use_tap_conds)+icond)
    
    [cc,p] = corrcoef(xdata,ydata);
    plot(xdata,ydata,'o','markersize',7)
    lh = lsline;
    set(lh,'color',[1 0 0])
    
    set(gca, 'xlim', [0 8])
    set(gca,'xtick',1:7)
    
    switch measures2plot{ivar}
      case 'rp_entropy'
	set(gca,'ylim',[0.8 1])
    end

    text(7,max(get(gca,'ylim'))*.9, sprintf('r=%1.3f,p=%1.3f', cc(2,1),p(2,1)), ...
	'horizontalalign','right', ...
	'verticalalign','top');
    
    if icond == 1
      ylabel(strrep(stimcats{curr_cat_idx},'_','\_'))
    end
    if icat == 1
      title(strrep(tapconds{icond},'_','\_'))
    end
    if icat == 1 & icond == 1
      xlabel(curr_qinfo.question_text)
    else
      set(gca,'xticklabel', '')
    end
    
  end % for icond=
end % for icat =

figfname = fullfile(globals.paths.figpath, ...
    sprintf('%s_corr_w_quest_summary.ps', measures2plot{ivar}));
fprintf('Printing figure to %s\n', figfname);
print(figfname,'-dpsc','-adobecset',append_str);

