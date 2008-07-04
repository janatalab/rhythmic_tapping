% tapping_x_music_entropy_fig.m
%
% Plots performance data vs stimulus data, where the data are in the form of
% entropy measures of the response profiles

% 7/23/07 PJ - For SMPC07 poster


cat_order = {'real_music_low_groove', 'real_music_mid_groove', ...
      'real_music_high_groove'};

% Calculate the distributions of stimulus entropies as a function of stimulus
% category
min_entropy = min(stim_st.data{stimcols.rp_entropy});
min_entropy = 0.8;
max_entropy = 1;
entropy_step_size = 0.01;
entropy_hist_bins = min_entropy:entropy_step_size:max_entropy;

% Plotting variables

% Scatter plot axes
sc_axes_left = 4;
sc_axes_bottom = 4;
sc_axes_height = 6;
sc_axes_width = sc_axes_height;
sc_margin = 0.5;

cat_marker_colors = {'high_groove','g';
  'mid_groove','b';
  'low_groove','r';
  'silence','k'};

figure(1), clf
set(gcf,'units','cent','defaultaxesunits','cent')

nstim_cat = length(cat_order);
clear stimH_hist
for icat = 1:nstim_cat
  stim_cat_mask = ...
      ismember(stim_st.data{stimcols.stimulus_category},cat_order{icat});
  
  curr_data = stim_st.data{stimcols.rp_entropy}(stim_cat_mask);
  stimH_hist(:,icat) = hist(curr_data, entropy_hist_bins);
  meanH(icat) = nanmean(curr_data);
  stdH(icat) = nanstd(curr_data);
  semH(icat) = stdH(icat)/sqrt(sum(stim_cat_mask));
end

% Plot stimulus vs tapping rp entropies
tapping_conds = {'iso_tap','free_form_tap'};
ntap_conds = length(tapping_conds);

clear sc_axes
for itap = 1:ntap_conds
  tap_mask = ismember(resp_st.data{respcols.tapping_condition},tapping_conds{itap});

  curr_pos = [sc_axes_left+(itap-1)*(sc_axes_width+sc_margin) ...
	sc_axes_bottom ...
	sc_axes_width sc_axes_height];
  sc_axes(itap) = axes('position',curr_pos);
  
  for icat = 1:nstim_cat
    curr_resp_cat = strrep(cat_order{icat},'real_music_','');
    stim_cat_mask = ...
	ismember(stim_st.data{stimcols.stimulus_category},cat_order{icat});
    
    resp_cat_mask = ...
	ismember(resp_st.data{respcols.stimulus_category}, ...
	strrep(cat_order{icat},'real_music_',''));
    
    % Get indices in stimulus info for all of the tapping trials
    [dummy, stim_st_idxs] = ismember(resp_st.data{respcols.stimulus_id}, ...
	stim_st.data{stimcols.stimulus_id});
    
    ydata = ...
	stim_st.data{stimcols.rp_entropy}(stim_st_idxs(tap_mask&resp_cat_mask));
    xdata = resp_st.data{respcols.rp_entropy}(tap_mask&resp_cat_mask);
    
    [cc,p] = corrcoef(xdata,ydata);

    marker_color = ...
	cat_marker_colors{strmatch(curr_resp_cat,cat_marker_colors(:,1)),2};
    marker_str = sprintf('%so', marker_color);
    plot(xdata,ydata,marker_str,'markersize',7)

    lh = lsline;
    set(lh(1),'linewidth',2)

    hold on
    
  end  % for icat
  set(gca,'xlim', [min_entropy max_entropy])
  set(gca,'ylim', [0.9 max_entropy])
  if itap > 1
    set(gca,'yticklabel','')
  end
    

end % for itap=



