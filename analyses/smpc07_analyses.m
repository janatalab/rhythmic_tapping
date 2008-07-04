% Analyses for the SMPC07 poster
%

globals = rhythmTap_globals;

min_entropy = 0.82;
max_entropy = 1;
entropy_step_size = 0.005;

% Load outputs from other analyses
if ~exist('resp_ds','var')
  % Response data
  matfname = fullfile(globals.paths.datapath, 'resp_rp', ...
      'meanEnergies_byTrialSub.mat');
  fprintf('Loading data from: %s\n',matfname);
  load(matfname,'meanEnergies');
  rp_ds = meanEnergies;
  clear meanEnergies
  
  % Post-tapping data
end

resp_cols = set_var_col_const(rp_ds.vars);

% Calculate the entropies of the response profiles for each trial
ntrials = length(rp_ds.data{resp_cols.trial_order});

H = zeros(ntrials,1)+NaN;
for itrial=1:ntrials
  curr_rp = rp_ds.data{resp_cols.meanEnergy}{itrial};
  
  nfilt = length(curr_rp);
  
  % Subtract the min of the data
  curr_rp = curr_rp - min(curr_rp);
  
  % Scale by sum of the energy in the profile to get the proportion in each
  % band.
  curr_rp = curr_rp/sum(curr_rp);

  % Remove any values that went to zero
  curr_rp(curr_rp == 0) = [];
  
  % Calculate the entropy
  H(itrial) = -sum(curr_rp.*log(curr_rp));
  
  % Normalize by the amount maximum entropy for output from this many filters
  H(itrial) = H(itrial)/log(nfilt);

end % for itrial

tapping_conds = unique(rp_ds.data{resp_cols.tapping_cond});
ntap_conds = length(tapping_conds);

stim_cat = unique(rp_ds.data{resp_cols.stimulus_category});
nstim_cat = length(stim_cat);

% Generate histograms of entropy distributions by category
entropy_hist_bins = min_entropy:entropy_step_size:max_entropy;

H_hist = zeros(length(entropy_hist_bins),ntap_conds*nstim_cat);
for itap = 1:ntap_conds
  tap_mask = ismember(rp_ds.data{resp_cols.tapping_cond},tapping_conds{itap});
  for icat = 1:nstim_cat
    cat_mask = ...
	ismember(rp_ds.data{resp_cols.stimulus_category},stim_cat{icat});
    
    col_idx = (itap-1)*nstim_cat+icat;
    H_hist(:,col_idx) = hist(H(tap_mask&cat_mask), entropy_hist_bins);
    meanH(itap,icat) = nanmean(H(tap_mask&cat_mask));
    stdH(itap,icat) = nanstd(H(tap_mask&cat_mask));
    semH(itap,icat) = stdH(itap,icat)/sqrt(sum(tap_mask&cat_mask));
  end
end
