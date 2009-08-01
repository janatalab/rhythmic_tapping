% rhythmTap_behaveCoding_figs.m
%
% Generates figures associated with analyses of movement data
%

% 02/14/09 PJ - updated for SMPC09 abstract analyses
% 7/5/09 ST - added coherence, von mises timing


LOAD_DATA = 1;
RUN_SUPPLEMENTARY_ANALYSES = 0;
EXPORT_STIMDATA = 0;
EXPORT_TRIALDATA = 0;
RUN_SUMMARY_ANALYSES = 0;
SAVE_ANALYSES = 0;
GENERATE_FIGS = 0;

globals = rhythmTap_globals;
globals.stimIPEMParams.rp.perform.calcTemporalExpect = 1;
globals.stimIPEMParams.rp.perform.calcVonMises = 1;
globals.stimIPEMParams.rp.perform.calcPhaseCoherence = 1;

% List of analysis files we need to load

% Load stimulus related information and metrics
stim_rpProfile_fstub = ...
    'rhythmTap_stimulus_rprofile_analysis_27July2007_11:30.mat';

% File with post stim responses
subject_grooveEnum_fstub = ...
    'rhythmTap_grooveEnumByTapStats_17July2007_14:15.mat';
  
% File with subject tapping metrics
subject_rpProfile_fstub = 'RP_corr_by_trial.mat';
%subject_rpProfile_fstub = 'meanEnergies_peakWidths_byTrialSub_normIOI.mat';

% Where to write trialdata and stimdata
trialdata_fname = fullfile(globals.paths.datapath, 'rhythmTap_trialdata.txt');
stimdata_fname = fullfile(globals.paths.datapath, 'rhythmTap_stimdata.txt');

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
  matfname = fullfile(globals.paths.resp_rp_path, subject_rpProfile_fstub);
  fprintf('Loading data from: %s\n',matfname);
  load(matfname,'trialMPP');
  rp_ds = trialMPP;
  clear trialMPP
  rpcols = set_var_col_const(rp_ds.vars);
   
  % Copy the variables from rp_ds to appropriate locations in 
  % resp_st so that we only have to deal with a single datastruct from here on out.
  copy_vars = {'meanEnergy','stdEnergy','resonFreqs','peakFreqs', ...
    'meanCoherence','varCoherence','meanVMTimingDev','varVMTimingDev',...
    'meanVMViolation','varVMViolation','meanVMPrediction','varVMPrediction',...
    'corr'};
 
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
  
  % Now we need to go and get the stimulus info like coherence and other
  % good stuff
  get_stim_vars = {'coherence'};
  
  stim_st.vars = [stim_st.vars get_stim_vars];
  stimcols = set_var_col_const(stim_st.vars);
  
  stimIDs = unique(stim_st.data{stimcols.stimulus_id});
  for iStim = 1:length(stimIDs)
    thisStimulusID = stimIDs(iStim);
    thisStimIdx = find(stim_st.data{stimcols.stimulus_id} == thisStimulusID);
    try 
      thisStimCategory = stim_st.data{stimulus_category}{thisStimIdx};
    catch
      thisStimCategory = '';
    end
    
    if ~strcmp(thisStimCategory, 'silence') || ~isempty(thisStimCategory)
      stimIPEMOut = ipem_proc_series(thisStimulusID,globals.stimIPEMParams);
      stimIPEMOutCols = set_var_col_const(stimIPEMOut.vars);
    
      thisStimRP = stimIPEMOut.data{stimIPEMOutCols.rp};
      
      if(iscell(thisStimRP))
        thisStimRP = thisStimRP{1};
      end
      thisStimRPCols = set_var_col_const(thisStimRP.vars);
      cohcols = set_var_col_const(thisStimRP.data{thisStimRPCols.coherence}.vars);
    
      meanCoh = mean(cellfun(@mean,thisStimRP.data{thisStimRPCols.coherence}.data{cohcols.cohPerPeakPerBand}));
      stim_st.data{stimcols.coherence}(thisStimIdx) = meanCoh;
    else
      stim_st.data{stimcols.coherence}(thisStimIdx) = NaN;
    end
  end % for iStim=
  
  
end % if LOAD_DATA

if RUN_SUPPLEMENTARY_ANALYSES
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

  curr_var = 'fisher_z';
  if ~ismember(curr_var, fieldnames(respcols)) && ismember('corr', fieldnames(respcols))
    resp_st.vars{end+1} = curr_var;
    respcols = set_var_col_const(resp_st.vars);
    resp_st.data{respcols.(curr_var)} = ...
      fisher_r2z(resp_st.data{respcols.corr});
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
  
end % if RUN_SUPPLEMENTARY_ANALYSES

%
% Retrieve information about the questions that were encountered
%

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

if EXPORT_STIMDATA
  clear export_st
  
  ignore_mask = ismember(stim_st.vars,globals.export.stimdata.ignore_cols);
  export_st.vars = {'data','column_labels','column_formats'};
  exportcols = set_var_col_const(export_st.vars);
  
  export_st.data{exportcols.data} = stim_st.data(~ignore_mask);
  output_vars = stim_st.vars(~ignore_mask);
  export_st.data{exportcols.column_labels} = output_vars;
  
  export_st.data{exportcols.column_formats} = cell(size(output_vars));
  curr_mask = ismember(output_vars,{'stimulus_id','numPeaks'});
  export_st.data{exportcols.column_formats}(curr_mask) = {'%d'};
  
  curr_mask = ismember(output_vars,{'stimulus_category'});
  export_st.data{exportcols.column_formats}(curr_mask) = {'%s'};
  
  curr_mask = cellfun('isempty',export_st.data{exportcols.column_formats});
  export_st.data{exportcols.column_formats}(curr_mask) = {'%1.6f'};

  print_params.fname = stimdata_fname;
  print_params.write2file = 1;
  print_params.replace_nan = true;
  print_params.nan_str = '.';
  print_params.add_datestamp = false;
  ensemble_display_table(export_st,print_params);

end % if EXPORT_STIMDATA

% Export trial data to a text file that we can send to a SAS analysis
if EXPORT_TRIALDATA
  clear export_st
  
  % Identify variables that we don't want to export
  ignore_mask = ismember(resp_st.vars,globals.export.trialdata.ignore_cols);
  export_st.vars = {'data','column_labels','column_formats'};
  exportcols = set_var_col_const(export_st.vars);
  
  export_st.data{exportcols.data} = resp_st.data(~ignore_mask);
  output_vars = resp_st.vars(~ignore_mask);
  export_st.data{exportcols.column_labels} = output_vars;
  
  export_st.data{exportcols.column_formats} = cell(size(output_vars));
  curr_mask = ismember(output_vars,{'session_id',question_vars{:}, ...
    'stimulus_id','numPeaks'});
  export_st.data{exportcols.column_formats}(curr_mask) = {'%d'};
  
  curr_mask = ismember(output_vars,{'subject_id','stimulus_category', ...
    'tapping_condition'});
  export_st.data{exportcols.column_formats}(curr_mask) = {'%s'};
  
  curr_mask = cellfun('isempty',export_st.data{exportcols.column_formats});
  export_st.data{exportcols.column_formats}(curr_mask) = {'%1.6f'};
  
  % Replace question ID variables with something a bit more readable
  groove_quest_labels = fieldnames(globals.groove_question_ids);
  groove_quest_labels(1) = [];  % remove all field
  
  % Figure out which original question variable matches the appropriate
  % output variable
  [quest_mask,quest_idxs] = ismember(output_vars,question_vars);

  % Get the question ID for the corresponding variable
  good_qids = qidlist(quest_idxs(quest_mask));
  
  [qid_mask,qid_idxs] = ismember(good_qids,globals.groove_question_ids.all);
  new_question_vars = groove_quest_labels(qid_idxs(qid_mask));
  
  export_st.data{exportcols.column_labels}(quest_mask) = lower(new_question_vars);
  
  % Convert enum data for question variables to proper values
  mod_idxs = find(quest_mask);
  for iidx = 1:length(mod_idxs)
    export_st.data{exportcols.data}{mod_idxs(iidx)} = enum2data(export_st.data{exportcols.data}{mod_idxs(iidx)});
  end
  
  %
  % Copy any relevant stimulus-related information to the export structure
  %
  
  % Get a list of stimids that we need to copy
  datacols = set_var_col_const(export_st.data{exportcols.column_labels});
  stimids = unique(export_st.data{exportcols.data}{datacols.stimulus_id});
  numvals = size(export_st.data{exportcols.data}{1},1);
  
  copy_vars = {'numPeaks', '%d'; 'coherence','%1.4f'}; % variables to copy
  
  for ic = 1:size(copy_vars,1)
    export_st.data{exportcols.column_labels}{end+1} = [copy_vars{ic,1} ...
      '_stim'];
    export_st.data{exportcols.column_formats}{end+1} = copy_vars{ic,2};
    
    % Initialize the output data vector
    switch copy_vars{ic,2}
      case '%s'
        outvect = cell(numvals,1);
      otherwise
        outvect = nan(numvals,1);
    end
    export_st.data{exportcols.data}{end+1} = outvect;
    
    for istim = 1:length(stimids)
      curr_stimid = stimids(istim);
      % Get a mask for the destination
      stimmask = export_st.data{exportcols.data}{datacols.stimulus_id} == curr_stimid;
    
      % Find the relevant stimulus
      srcstim_idx = find(stim_st.data{stimcols.stimulus_id} == curr_stimid);
      if isempty(srcstim_idx)
        fprintf('Could not find information for stimid: %d\n', curr_stimid);
      else
        % copy the data
        export_st.data{exportcols.data}{end}(stimmask) = ...
          stim_st.data{stimcols.(copy_vars{ic,1})}(srcstim_idx);
      end
    end % for istim=
  end % for ic=
  
  % Write out the data to a tab-delimited file
  print_params.fname = trialdata_fname;
  print_params.write2file = 1;
  print_params.replace_nan = true;
  print_params.nan_str = '.';
  print_params.add_datestamp = false;
  ensemble_display_table(export_st,print_params);
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


vars2analyze = [vars2analyze question_vars];

%
% Construct matrices containing summary analyses
%

analysis_sets = fieldnames(analysis_types);
num_anal_sets = length(analysis_sets);

if RUN_SUMMARY_ANALYSES
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
end % if RUN_SUMMARY_ANALYSES
 
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
