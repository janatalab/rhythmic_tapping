% dirty_entropy_calc
%
% Very hard coded look at some entropy calculations

LOAD_DATA = 0;

globals = rhythmTap_globals;

fstub = 'rhythmTap_response_rprofile_analysis_16July_18:42.mat';
matname = fullfile(globals.paths.datapath,fstub);

if LOAD_DATA
  tmp = load(matname);
  an = tmp.an;
  
  clear tmp
end

respdata = an{6}.results{1};
respcols = set_var_col_const(respdata.vars);

nstim = length(respdata.data{respcols.meanEnergy});
H = zeros(nstim,1);
for istim = 1:nstim
  curr_data = respdata.data{respcols.meanEnergy}{istim};
  nfilt = length(curr_data);
  
  % Subtract the min of the data
  curr_data = curr_data - min(curr_data);
  
  % Scale by sum of the energy in the profile to get the proportion in each
  % band.
  curr_data = curr_data/sum(curr_data);

  % Remove any values that went to zero
  curr_data(curr_data == 0) = [];
  
  % Calculate the entropy
  H(istim) = -sum(curr_data.*log(curr_data));
  
  % Normalize by the amount maximum entropy for output from this many filters
  H(istim) = H(istim)/log(nfilt);
end

% Generate histograms by category
tapping_conds = unique(respdata.data{respcols.tapping_cond});
ntap_conds = length(tapping_conds);

stim_cat = unique(respdata.data{respcols.stimulus_category});
nstim_cat = length(stim_cat);

min_entropy = 0.85;
max_entropy = 1;
entropy_step_size = 0.001;
entropy_hist_bins = min_entropy:entropy_step_size:max_entropy;


H_hist = zeros(length(entropy_hist_bins),ntap_conds*nstim_cat);
for itap = 1:ntap_conds
  tap_mask = ismember(respdata.data{respcols.tapping_cond},tapping_conds{itap});
  for icat = 1:nstim_cat
    cat_mask = ...
	ismember(respdata.data{respcols.stimulus_category},stim_cat{icat});
    
    col_idx = (itap-1)*nstim_cat+icat;
    H_hist(:,col_idx) = hist(H(tap_mask&cat_mask), entropy_hist_bins);
    meanH(itap,icat) = nanmean(H(tap_mask&cat_mask));
    stdH(itap,icat) = nanstd(H(tap_mask&cat_mask));
  end
end
