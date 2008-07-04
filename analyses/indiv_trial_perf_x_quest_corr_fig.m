% indiv_trial_perf_x_quest_corr_fig.m
%
% Plots correlations between subjective post-stim evaluations and performance
% measures on a trial by trial basis.
%

% Might need to express subjective ratings for trials as z-scores within
% individual subjects to deal with different ranges on the scales.

% 7/17/07 PJ

PLOT_ACROSS_CAT = 0;
PLOT_GROUPED = 1;

across_cat_fig = 1;
nrows = ceil(nquest/2);

by_cat_fig = 2;

use_tap_conds = {'free_form_tap','iso_tap'};
cat_marker_colors = {'high_groove','g';
  'mid_groove','b';
  'low_groove','r';
  'silence','k'};

cat_width = 0.75;

append_str = '';
figure(across_cat_fig), clf
for iquest = 1:nquest
  if iquest > 1
    append_str = '-append';
  end
  
  compqid_str = sprintf('compqid_%d_%d', quest_subset(iquest).question_id, ...
      quest_subset(iquest).subquestion);

  if PLOT_ACROSS_CAT
    figure(across_cat_fig)
    
    subplot(nrows,2,iquest)
    
    catmask = ismember(resp_st.data{respcols.stimulus_category},stimcats);
    iso_mask = ismember(resp_st.data{respcols.tapping_condition}, 'iso_tap');
    freeform_mask = ismember(resp_st.data{respcols.tapping_condition}, 'free_form_tap');

    xdata = ...
	enum2data(resp_st.data{respcols.(compqid_str)}(catmask&iso_mask));
    ydata1 = resp_st.data{respcols.(measures2plot{ivar})}(catmask&iso_mask);
    
    [cc1,p1] = corrcoef(xdata,ydata1);
    plot(xdata,ydata1,'o','markersize',7)
    lh = lsline;
    set(lh,'color',[1 0 0])
    
    hold on
    
    xdata = ...
	enum2data(resp_st.data{respcols.(compqid_str)}(catmask&freeform_mask));
    ydata2 = resp_st.data{respcols.(measures2plot{ivar})}(catmask&freeform_mask);
    [cc2,p2] = corrcoef(xdata,ydata2);
    plot(xdata,ydata2,'o','markersize',7)
    lh = lsline;
    set(lh,'color',[0 0 1])
    
    switch measures2plot{ivar}
      case 'rp_entropy'
	set(gca,'ylim',[0.8 1])
    end
    
    title(quest_subset(iquest).question_text)
    
  end % if PLOT_ACROSS_CAT

  figure(by_cat_fig), clf
  set(gcf, 'defaultaxesfontsize',12)
    
  for icat = 1:nstimcats
    curr_cat = groove_plot_order{icat};
    catmask = ismember(resp_st.data{respcols.stimulus_category}, curr_cat);

    for icond = 1:length(use_tap_conds)
      cond_str = use_tap_conds{icond};
      condmask = ismember(resp_st.data{respcols.tapping_condition}, cond_str);

      xdata = enum2data(resp_st.data{respcols.(compqid_str)}(catmask&condmask));
      ydata = resp_st.data{respcols.(measures2plot{ivar})}(catmask&condmask);
      
      % Remove any trials that had NaNs in either the tapping or questions
      nanmask = isnan(xdata) | isnan(ydata);
      xdata(nanmask) = [];
      ydata(nanmask) = [];
      
      if isempty(xdata)
	continue
      end
      
      if PLOT_GROUPED
	subplot(length(use_tap_conds),1,icond)
	hold on
      else
	subplot(nstimcats,length(use_tap_conds), ...
	    (icat-1)*length(use_tap_conds)+icond)
      end
      
      [cc,p] = corrcoef(xdata,ydata);
      
      new_xloc = xdata+icat*cat_width/nstimcats-cat_width/2;
      marker_color = ...
	  cat_marker_colors{strmatch(curr_cat,cat_marker_colors(:,1)),2};
      marker_str = sprintf('%so', marker_color);
      
      plot(new_xloc,ydata,marker_str,'markersize',7)
      lh = lsline;
      set(lh(1),'linewidth',2)
      %set(lh,'color',[1 0 0])
      
      set(gca, 'xlim', [0 8])
      set(gca,'xtick',1:7)
      
      switch measures2plot{ivar}
	case 'rp_entropy'
	  set(gca,'ylim',[0.8 1])
      end
      
      stat_str = sprintf('r=%1.3f,p=%1.3f', cc(2,1),p(2,1));
      text_str = sprintf('%s\n%s', strrep(curr_cat,'_',' '), stat_str);
      t = text((icat-1)/nstimcats+1/nstimcats/2, 0.02, text_str, ...
	  'horizontalalign','center', ...
	  'verticalalign','bottom', ...
	  'units','normalized', ...
	  'color',get(lh(1),'color'), ...
	  'fontsize', 12, ...
	  'fontweight','bold');
      
      xlabel('Rating category', 'fontsize',14)
      
      if icond == 1
	ylabel(strrep(measures2plot{ivar},'_','\_'))
      end
      if icat == 1
	text_str = strrep(cond_str,'_',' ');
	text(0, 1,text_str,'units','normalized','verticalalign','bottom', ...
	    'fontsize', 12)
      end
      if icat == 1 & icond == 1
	title_str = sprintf(strrep(quest_subset(iquest).question_text, '(', '\n('));
	title(title_str, 'fontsize',16)
      end
      
    end % for icond=
  end % for icat =

  figfname = fullfile(globals.paths.figpath, ...
      sprintf('%s_corr_w_quest_indivtrial.ps', measures2plot{ivar}));
  fprintf('Printing figure to %s\n', figfname);
  print(figfname,'-dpsc','-adobecset',append_str);

end % for iquest=
