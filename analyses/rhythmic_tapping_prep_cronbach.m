% Formats data matrix of post-stim groove ratings that can be exported to
% SAS in order for Cronbach's alpha to be calculated
%
% rhythmic_tapping_prep_cronbach
%


% 27Apr2011 Petr Janata
LOAD_DATA = 0;
USE_PLOT = 0;

% Load project globals
globals = rhythmTap_globals;

% Load the MAT-file containing the post-stim ratings
if LOAD_DATA
	datafstub = 'rhythmTap_grooveEnumByTapStats_17July2007_14:15.mat';
	datafname = fullfile(globals.paths.datapath, datafstub);
	
	fprintf('Loading data from: %s\n', datafname);
	load(datafname,'an'); % Load the data
end

resp_st = an{3}.results; % extract relevant data
respcols = set_var_col_const(resp_st.vars);

% Remove silence trials
currfilt.exclude.any.stimulus_id = 6497;
resp_st = ensemble_filter(resp_st,currfilt);

% Get list of subject IDs
[subid_mask_mtx, subids] = make_mask_mtx(resp_st.data{respcols.subject_id});
nsub = length(subids);

% Get list of unique stimulus IDs
[stimid_mask_mtx, stimids] = make_mask_mtx(resp_st.data{respcols.stimulus_id});
nstim = length(stimids);

% Get the perceived groove data
groove = resp_st.data{respcols.compqid_493_1};

% Get the stimulus category for each stimulus
stimcat = cell(nstim,1);
for istim = 1:nstim
	stimcat(istim) = unique(resp_st.data{respcols.stimulus_category}(stimid_mask_mtx(:,istim)));
end

% Great a sort list
sort_order = {'low_groove','mid_groove','high_groove'};
sort_order = {'high_groove','mid_groove','low_groove'};
sorted_idxs = [];
for icat = 1:length(sort_order)
	sorted_idxs = [sorted_idxs; find(ismember(stimcat,sort_order{icat}))];
end

% Initialize output matrix
outmtx = nan(nstim, nsub);

% Populate the output matrix
for istim = 1:nstim
	for isub = 1:nsub
		composite_mask = stimid_mask_mtx(:,istim) & subid_mask_mtx(:,isub);
		nresp = sum(composite_mask);
		if nresp > 0
			if nresp > 1
				warning('Found %d responses for stimid %d, subject %s', ...
					nresp, stimids(istim), subids{isub})
			end
			outmtx(istim,isub) = mean(groove(composite_mask));
		end
	end % for isub=
end % for istim=

% Plot the output matrix as well as matrix of missing data. Turns out we
% have a lot of missing data and can't compute Cronbach's alpha.
figure(1), clf
subplot(2,1,1)
% Calculate z-scores
zout = (outmtx - repmat(nanmean(outmtx),nstim,1))./repmat(nanstd(outmtx),nstim,1);
imagesc(zout)
title('Perceived groove ratings')

subplot(2,1,2)
imagesc(isnan(outmtx))
title('Missing data (brown)')

% Plot average standardized perceived groove
figure(2), clf
set(gcf,'defaultaxesfontsize', 12)
data = nanmean(zout(sorted_idxs,:),2);
errdata = nanstd(zout(sorted_idxs,:),0,2)./sqrt(sum(~isnan(zout(sorted_idxs,:)),2));

if USE_PLOT
	errorbar(data, errdata)
else
	h = barh(data);
	colormap(gray)
	add_errorbars(h,errdata,'k');
	axis ij
	
	offset = 0.5;
	%set(gca,'ytick', [16 32]+offset)
	set(gca,'ytick', [])
	line(repmat(get(gca,'xlim')',1,2), ones(2,1)*[16 32]+offset, 'color','k')
	
	xlabel('Z-score','fontsize',16)
	
	% Add stim names
	for istim = 1:nstim
		stimid = stimids(sorted_idxs(istim));
		stimname = stimmeta.data{stimcols.name}{stimmeta.data{stimcols.stimulus_id} == stimid};
		
		negpos = sign(data(istim));
		if negpos < 0
			align_dir = 'left';
		else
			align_dir = 'right';
		end
		
		text_offset = 0;
		text(0-negpos*.05,istim+text_offset,stimname,'horizontalalign', align_dir, 'verticalalign', 'middle')
	end
end

% Print the figure
figfname = fullfile(globals.paths.figpath, 'rhythmic_tapping_v2_stim_groove_ratings.eps');
fprintf('Printing %s\n', figfname);
print(figfname, '-deps')

% Print stimulus info in the sorted order
stimmeta = an{1}.results.data{5};
stimcols = set_var_col_const(stimmeta.vars);
for istim = 1:nstim
	stimid = stimids(sorted_idxs(istim));
	fprintf('%d: %s\n', stimid, stimmeta.data{stimcols.name}{stimmeta.data{stimcols.stimulus_id} == stimid})
end