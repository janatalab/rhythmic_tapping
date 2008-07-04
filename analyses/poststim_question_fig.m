% poststim_question_fig.m
%
% Used in conjunction with rhythmTap_tapping_figs.m

varmask = ismember(vars2analyze, question_vars(seven_point_mask));

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
fprintf('Printing figure %d to %s\n', figfname);
print(figfname,'-dpsc','-adobecset',append_str);

