% rhythmTap_behaveCoding_figs.m
%
% Generates figures associated with analyses of movement data
%

% 02/14/09 PJ - updated for SMPC09 abstract analyses
% 7/5/09 ST - added coherence, von mises timing


LOAD_DATA = 0;
RUN_ANALYSES = 0;
SAVE_ANALYSES = 0;
GENERATE_FIGS = 1;

globals = rhythmTap_globals;

% List of analysis files we need to load
stim_rpProfile_fstub = ...
    'rhythmTap_stimulus_rprofile_analysis_27July2007_11:30.mat';
    %    'rhythmTap_stimulus_rprofile_analysis_18July2007_00:41.mat';

subject_grooveEnum_fstub = ...
    'rhythmTap_grooveEnumByTapStats_17July2007_14:15.mat';
subject_rpProfile_fstub = 'meanEnergies_peakWidths_byTrialSub_normIOI.mat';
%'meanEnergies_byTrialSub.mat'

analysis_types.subject = {'nanmean', ... % 
      'nanstd', ... % 
      'nanmin', ... % 
      'nanmax', ... %
      };
analysis_types.group = {'nanmean','nanstd','nsub'};

vars2analyze = {'tapping_var_about_peak','rp_entropy'};
vars2analyze = {'numPeaks'};

if LOAD_DATA
  % Load tapping data and responses to post-stim questions
  datafstub = subject_grooveEnum_fstub;
  datafname = fullfile(globals.paths.datapath, datafstub);

  fprintf('Loading data from: %s\n', datafname);
  load(datafname,'an'); % Load the data

  % Find the analysis structure that contains the trial by trial tapping data and
  % response to post trial questions and extract it
  crit.name = 'match_resps_to_tapping';
  an_idx = ensemble_find_analysis_struct(an,crit);
  
  resp_st = an{an_idx}.results;
  respcols = set_var_col_const(resp_st.vars);
  
  clear an
  
  % Response data with response profiles
  matfname = fullfile(globals.paths.datapath, 'resp_rp2', ...
      subject_rpProfile_fstub);
  fprintf('Loading data from: %s\n',matfname);
  load(matfname,'meanEnergies');
  rp_ds = meanEnergies;
  clear meanEnergies
  rpcols = set_var_col_const(rp_ds.vars);
  
  % Copy the variables from rp_ds to appropriate locations in resp_st so that
  % we only have to deal with a single datastruct from here on out.
  copy_vars = {'meanEnergy','stdEnergy','resonFreqs','peakFreqs','meanCoherence','varCoherence',...
	       'meanVMTimingDev','varVMTimingDev','meanVMViolation','varVMViolation',...
	       'meanVMPrediction','varVMPrediction'};
  
  subids = unique(rp_ds.data{rpcols.subject_id});
  nsub = length(subids);
  for isub = 1:nsub
    submask = ismember(rp_ds.data{rpcols.subject_id}, subids(isub));
    trial_ids = rp_ds.data{rpcols.trial_order}(submask);
    if length(unique(trial_ids)) ~= length(trial_ids)
      error('Multiple rows with same trial ID\n')
    end
    for itid = 1:length(trial_ids)
      dest_row = find(ismember(resp_st.data{respcols.subject_id}, ...
	  subids(isub)) & resp_st.data{respcols.trial_order} == ...
	  trial_ids(itid));
      if isempty(dest_row)
	error(sprintf('Did not find destination row for subject %s and trial %d\n', subids(isub), trial_ids(itid)))
      elseif length(dest_row) > 1
	error(sprintf(['Found %d destination rows for subject %s ' ...
	      'and trial %d\n'], length(dest_row), subids(isub), trial_ids(itid)))
      end
      
      for ivar = 1:length(copy_vars)
	curr_var = copy_vars{ivar};
	src_row = submask&rp_ds.data{rpcols.trial_order}==trial_ids(itid);
	src_data = rp_ds.data{rpcols.(curr_var)}(src_row);
	
	if ~ismember(curr_var, fieldnames(respcols))
	  resp_st.vars{end+1} = curr_var;
	  respcols = set_var_col_const(resp_st.vars);
	  fh = str2func(class(src_data));
	  resp_st.data{respcols.(curr_var)} = fh('');
	end
	
	% Make sure that stimids match. This is a weak sanity check
	src_stimid = rp_ds.data{rpcols.stimulus_id}(src_row);
	dest_stimid = resp_st.data{respcols.stimulus_id}(dest_row);
	if src_stimid ~= dest_stimid
	  error('stimid mismatch\n')
	end
	
	resp_st.data{respcols.(curr_var)}(dest_row,1) = src_data;
      end % for ivar		     
    end % for itid
  end % for isub
  
  %
  % Load the stimulus response profiles
  %
  datafname = fullfile(globals.paths.datapath, stim_rpProfile_fstub);
  fprintf('Loading stimulus data from: %s\n', datafname);
  load(datafname,'an')
  stim_st = an{5}.results;
  stimcols = set_var_col_const(stim_st.vars);
  
end % if LOAD_DATA

% Calculate any other desired measures on the trial data
curr_var = 'rp_entropy';
if ~ismember(curr_var, fieldnames(respcols))
  resp_st.vars{end+1} = curr_var;
  respcols = set_var_col_const(resp_st.vars);
  resp_st.data{respcols.(curr_var)} = ...
      rp_entropy(resp_st.data{respcols.meanEnergy});
end

curr_var = 'numPeaks';
if ~ismember(curr_var, fieldnames(respcols))
  resp_st.vars{end+1} = curr_var;
  respcols = set_var_col_const(resp_st.vars);
  resp_st.data{respcols.(curr_var)} = ...
      cellfun('length',resp_st.data{respcols.peakFreqs});
end
    
% Calculate any other desired measures on the stimulus data
curr_var = 'rp_entropy';
if ~ismember(curr_var, fieldnames(stimcols))
  stim_st.vars{end+1} = curr_var;
  stimcols = set_var_col_const(stim_st.vars);
  stim_st.data{stimcols.(curr_var)} = ...
      rp_entropy(stim_st.data{stimcols.meanEnergy});
end

curr_var = 'numPeaks';
if ~ismember(curr_var, fieldnames(stimcols))
  stim_st.vars{end+1} = curr_var;
  stimcols = set_var_col_const(stim_st.vars);
  stim_st.data{stimcols.(curr_var)} = ...
      cellfun('length',stim_st.data{stimcols.peakFreqs});
end


% Get the number of stimulus categories
stimcats = unique(resp_st.data{respcols.stimulus_category});
nstimcats = length(stimcats);

% Get the number of tapping conditions
tapconds = unique(resp_st.data{respcols.tapping_condition});
ntapconds = length(tapconds);

% Construct a subject mask matrix
[sub_mask_mtx, subids] = make_mask_mtx(resp_st.data{respcols.subject_id});
nsub = length(subids);

% Generate the list of compqids that are present
tag = 'compqid_';
idxs = strmatch(tag,resp_st.vars);
question_vars = resp_st.vars(idxs);
qidlist = zeros(1,length(idxs));
for iidx = 1:length(idxs)
  tmpstr = resp_st.vars{idxs(iidx)};
  sepidx = findstr(tmpstr,'_');
  qidstr = tmpstr(sepidx(1)+1:sepidx(2)-1);
  sqidstr = tmpstr(sepidx(2)+1:end);
    qidlist(iidx) = str2num(qidstr)+str2num(sqidstr)/100;
end

% Extract the question metadata
qinfo = mysql_extract_metadata('table','question', ...
    'question_id',unique(fix(qidlist)));
[qmask,qinfo_loc] = ismember(qidlist,[qinfo.compqid]);
qinfo = qinfo(qinfo_loc);

vars2analyze = [vars2analyze question_vars];

%
% Construct matrices containing summary analyses
%

analysis_sets = fieldnames(analysis_types);
num_anal_sets = length(analysis_sets);

if RUN_ANALYSES
  clear summary
  
  % Initialize output data
  for iset = 1:num_anal_sets
    setstr = analysis_sets{iset};
    num_analyses.(setstr) = length(analysis_types.(setstr));
    for ianal = 1:num_analyses.(setstr)
      summary.(setstr).(analysis_types.(setstr){ianal}) = cell(nstimcats,ntapconds);
    end
  end % for iset
  
  for icat = 1:nstimcats
    % Create a stimulus category mask
    stimcat_mask = ismember(resp_st.data{respcols.stimulus_category}, stimcats{icat});
    
    for icond = 1:ntapconds
      % Create a tapping condition mask
      cond_mask = ismember(resp_st.data{respcols.tapping_condition}, ...
	  tapconds{icond});
      
      % Run the subject analyses first
      setstr = 'subject';
      curr_analyses = analysis_types.(setstr);

      fprintf('Running %s analyses (%s,%s) ...\n', setstr, stimcats{icat}, tapconds{icond});
      for isub = 1:nsub
	sub_mask = sub_mask_mtx(:,isub);
	    
	for ianal = 1:num_analyses.(setstr)
	  anal_str = analysis_types.(setstr){ianal};
	      
	  composite_mask = stimcat_mask & cond_mask & sub_mask;
	  
	  nvars = length(vars2analyze);
	  for ivar = 1:nvars
	    varstr = vars2analyze{ivar};
	    src_data = resp_st.data{respcols.(varstr)}(composite_mask);
	    
	    if ismember(varstr,question_vars)
	      src_data = enum2data(src_data);
	    end
	  
	    % Determine the result for this subject
	    if isempty(src_data)
	      result = NaN;
	    else
	      switch anal_str
		case {''}
			  
		otherwise
		  fh = str2func(anal_str);
	      
	      end		  
	      result = fh(src_data);
	    end
	    
	    % Assign the result
	    summary.(setstr).(anal_str){icat,icond}(isub,ivar) = result;
		  
	  end % for ivar
	end % for ianal
      end % for isub=
	  
      % Now run the group analyses
      setstr = 'group';
      fprintf('Running %s analyses ...\n', setstr);
	  
      % Now run each analysis (assuming this behavior was observed)
      for ianal = 1:num_analyses.(setstr)
	anal_str = analysis_types.(setstr){ianal};
	
	switch anal_str
	  case 'nsub'
	    fh = inline('sum(~isnan(x))');
	  otherwise
	    fh = str2func(anal_str);
	end
	src_data = summary.subject.nanmean{icat,icond};
	result_val = fh(src_data);
	    
	summary.(setstr).(anal_str){icat,icond} = result_val;
      end % for ianal
    end % for icond=
  end % for icat=
 
  if SAVE_ANALYSES
    analfstub = sprintf('rhythmTap_tapping_summary_%s.mat', datestr(now,30));
    analfname = fullfile(globals.paths.datapath, analfstub);
    fprintf('Saving data to: %s\n', analfname);
    save_vars = {'summary','globals','stimcats','tapconds'};
    save(analfname, save_vars{:})
  end
end % if RUN_ANALYSES
 
if GENERATE_FIGS
  nstimcats = length(stimcats);
  ntapconds = length(tapconds);
  
  groove_plot_order = {'high_groove','mid_groove','low_groove','silence'};
  
  seven_point_qids = [207.01 493.01 494.01 498.01 505.01];
  seven_point_mask = ismember([qinfo.compqid],seven_point_qids);
  quest_subset = qinfo(seven_point_mask);
  nquest = length(quest_subset);

  %
  % Generate figure showing the average responses to the poststim questions
  %
  %figure(1),clf
%  poststim_question_fig;
  
  measures2plot = {'tapping_var_about_peak','rp_entropy'};
  measures2plot = {'numPeaks'};
  measures2plot = {'meanCoherence','varCoherence',...
		   'meanVMTimingDev','varVMTimingDev','meanVMViolation',...
		   'varVMViolation','meanVMPrediction','varVMPrediction'};
  for ivar = 1:length(measures2plot)

    %subavg_tapping_corr_tap_question_fig;
    
    % Individual trial correlations
    %figure(7), clf
    indiv_trial_perf_x_quest_corr_fig;
    
    % Variable means as a function of the category and condition
    %avg_by_cat_cond
    
  end % for ivar =
end % if GENERATE_FIGS
