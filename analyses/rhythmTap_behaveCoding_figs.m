% rhythmTap_behaveCoding_figs.m
%
% Generates figures associated with analyses of movement data
%
% Original version by P.J.
%
% 8/14/09 - S.T. changed 'body_group' tag to 'body_group_by_rhythm'
%           to accomodate new body_group behavior category in globals

LOAD_DATA = 1;
RUN_ANALYSES = 1;
SAVE_ANALYSES = 0;
GENERATE_FIGS = 1;

globals = rhythmTap_globals;

% The behaviors have been coded at a fairly fine level of detail.  For the
% purpose of generating figures that are simpler and easier to understand, it
% is useful to group sets of behaviors, e.g. all rhythmic hand movements, into
% a single variable.  The various behavior groups are defined in
% rhythmTap_globals.

behavior_grouping_types = {'indiv','body_group_by_rhythm','rhythmic_vs_non_rhythmic','misc'};
use_behave_groups = [2 4];

analysis_types.subject = {'sum_prop', ... % sum the proportion of time per stim
      'mean_prop', ... % mean proportion of time spent in behavior across stims
      'min_prop', ... % minimum proportion of time spent in behavior 
      'max_prop', ... % maximum proportion of time spent in behavior 
      };
analysis_types.group = {'nanmean','nanstd','nsub'};

if LOAD_DATA
  datafstub = 'rhythmTap_behaveCodingAnalysis_6Aug2009.mat';
  datafname = fullfile(globals.paths.datapath, datafstub);

  fprintf('Loading data from: %s\n', datafname);
  load(datafname); % Load the data

  % Reload the current globals (in case saved globals clobber necessary
  % modifications, e.g. paths)
  globals = rhythmTap_globals;
  
  analfstub = 'rhythmTap_secondaryAnalyses_';
  analfname = fullfile(globals.paths.datapath, analfstub);
  if exist(analfname)
    fprintf('Loading secondary analysis data from: %s\n', analfname);
    load(analfname); % Load the data from a previous analysis
  end
end % if LOAD_DATA

% Find the analysis structure that contains the data and extract it
crit.name = 'behavioral_coding_analysis';
an_idx = ensemble_find_analysis_struct(an,crit);

data_st = an{an_idx}.results;
cols = set_var_col_const(data_st.vars);

% Remove subjects for whom trial alignment may be off
clear tmpfilt
tmpfilt.exclude.any.subject_id = ...
    {'03mxv76151','08bin87131','01lot87121'};
data_st = ensemble_filter(data_st,tmpfilt);

% Get the number of stimulus categories
stimcats = unique(data_st.data{cols.stimulus_category});
nstimcats = length(stimcats);

% Get the number of tapping conditions
tapconds = unique(data_st.data{cols.tapping_condition});
ntapconds = length(tapconds);

% Construct the list of all individually coded behaviors
behaviors = unique(data_st.data{cols.behavior});

% Determine how many coders we have
coder_ids = unique(data_st.data{cols.coder_id});
ncoders = length(coder_ids);

% Construct a subject mask matrix
[sub_mask_mtx, subids] = make_mask_mtx(data_st.data{cols.subject_id});
nsub = length(subids);

% Construct a stimulus_id mask matrix
[stimid_mask_mtx, stimids] = make_mask_mtx(data_st.data{cols.stimulus_id});
nstim_total = length(stimids);

%
% Construct matrices containing summary analyses
%

analysis_sets = fieldnames(analysis_types);
num_anal_sets = length(analysis_sets);

if RUN_ANALYSES
  clear amt_behave
  
  %
  % Open an output file
  %
  outfname = ...
      fullfile(globals.paths.logpath,'rhythmTap_behaveCoding_data_7Aug2009.txt');
  fprintf('Writing data table to: %s', outfname);
  fid = fopen(outfname,'wt');
  fprintf(fid,'Subject\tStimulus\tTapcond\tBodyGroup\tAmtMove\n');
  
  % Initialize output data
  for iset = 1:num_anal_sets
    nbehave_groups = length(use_behave_groups);
    for ibehave_group = 1:nbehave_groups
      behave_group_idx = use_behave_groups(ibehave_group);
      behave_group_tag = behavior_grouping_types{behave_group_idx};
	
      setstr = analysis_sets{iset};
      num_analyses.(setstr) = length(analysis_types.(setstr));
      for ianal = 1:num_analyses.(setstr)
	amt_behave.(behave_group_tag).(setstr).(analysis_types.(setstr){ianal}) = cell(nstimcats,ntapconds);
      end
    end
  end
  
  for icat = 1:nstimcats
    % Create a stimulus category mask
    stimcat_mask = ismember(data_st.data{cols.stimulus_category}, stimcats{icat});
    
    % Figure out which stimuli are in this category
    cat_stimids = unique(data_st.data{cols.stimulus_id}(stimcat_mask));
    nstim_cat = length(cat_stimids);
    
    for icond = 1:ntapconds
      % Create a tapping condition mask
      cond_mask = ismember(data_st.data{cols.tapping_condition}, ...
	  tapconds{icond});
      
      % Deal with figuring out how many sets of behavior groupings we need to
      % analyze
      nbehave_groups = length(use_behave_groups);
      for ibehave_group = 1:nbehave_groups
	behave_group_idx = use_behave_groups(ibehave_group);
	behave_group_tag = behavior_grouping_types{behave_group_idx};
	
	behavior_info = assign_behavior_info(behave_group_tag);
	
	nbehave_sets = size(behavior_info,1);
	for ibehave = 1:nbehave_sets
	  % Create a behavior mask
	  behave_mask = ismember(data_st.data{cols.behavior}, behavior_info{ibehave,2});
	  
	  % Run the subject analyses first
	  setstr = 'subject';
	  curr_analyses = analysis_types.(setstr);

	  fprintf('Running %s analyses (%s,%s) ...\n', setstr, stimcats{icat}, tapconds{icond});
	  for isub = 1:nsub
	    sub_mask = sub_mask_mtx(:,isub);
	    
	    for ianal = 1:num_analyses.(setstr)
	      anal_str = analysis_types.(setstr){ianal};
	      
	      switch anal_str
		case 'sum_prop'
		  fh = str2func('sum');
		  
		  for istim = 1:nstim_cat
		    % Get the stimulus mask
		    stim_mask = stimid_mask_mtx(:,stimids==cat_stimids(istim));

		    composite_mask = stimcat_mask & stim_mask & cond_mask & ...
			behave_mask & sub_mask;
		    
		    num_instances = length(unique(data_st.data{cols.trial_order}(composite_mask)));
		    %num_instances = 1;
		    
		    if any(composite_mask)
		      src_data = ...
			  data_st.data{cols.behavior_proportion}(composite_mask);
		      result_val = fh(src_data)/num_instances;
		    elseif any(stimcat_mask & stim_mask & cond_mask & sub_mask)
		      result_val = 0;
		    else
		      result_val = NaN;
		    end
		    % Currently divide by the number of coders to get the
		    % average amount of coded behavior
		    amt_behave.(behave_group_tag).(setstr).(anal_str){icat,icond}{isub,ibehave}(istim) = result_val/ncoders;
		  end % for istim
		  
		case {'mean_prop','min_prop','max_prop'}
		  fh = str2func(anal_str(1:findstr(anal_str,'_')-1));
		  src_data = ...
		      amt_behave.(behave_group_tag).(setstr).sum_prop{icat,icond}{isub,ibehave};
		  if any(~isnan(src_data))
		    result = fh(src_data(~isnan(src_data)));
		  else
		    result = NaN;
		  end
		  
		  amt_behave.(behave_group_tag).(setstr).(anal_str){icat,icond}(isub,ibehave) = result;
		  
		  % Write the data to an output file that can be fed into SAS
		  if strcmp(anal_str,'mean_prop') & ~isnan(result)
		    fmt_str = '%s\t%s\t%s\t%s\t%1.4f\n';
		    fprintf(fid,fmt_str, ...
			subids{isub}, ...
			stimcats{icat}, ...
			tapconds{icond}, ...
			behavior_info{ibehave,1}, ...
			result);
		  end
		otherwise
		  
	      end % switch anal_str
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
	    src_data = amt_behave.(behave_group_tag).subject.mean_prop{icat,icond};
	    result_val = fh(src_data);
	    
	    amt_behave.(behave_group_tag).(setstr).(anal_str){icat,icond} = result_val;
	  end % for ianal
	end % for ibehave
      end % for ibehave_group =
    end % for icond=
  end % for icat=
  
  fclose(fid);
  
  if SAVE_ANALYSES
    analfstub = sprintf('rhythmTap_secondaryAnalyses_%s.mat', datestr(now,30));
    analfname = fullfile(globals.paths.datapath, analfstub);
    fprintf('Saving data to: %s\n', analfname);
    save_vars = {'amt_behave','globals','stimcats','tapconds','behaviors'};
    save(analfname, save_vars{:})
  end
end % if RUN_ANALYSES

if GENERATE_FIGS

  groove_plot_order = {'high_groove','mid_groove','low_groove','silence'};
  
  nbehave_groups = length(use_behave_groups);
  for ibehave_group = 1:nbehave_groups
    behave_group_idx = use_behave_groups(ibehave_group);
    behave_group_tag = behavior_grouping_types{behave_group_idx};
    
    behavior_info = assign_behavior_info(behave_group_tag);

    figure(ibehave_group), clf  % Plot mean data into figure 1
  
    nstimcats = length(stimcats);
    ntapconds = length(tapconds);
    nbehave = size(behavior_info,1);
  
    % Determine y-lim for set of plots - exclude silence conditions for now    
    for icat = 1:nstimcats
      curr_cat = groove_plot_order{icat};
      curr_cat_idx = strmatch(curr_cat,stimcats,'exact');
      
      for icond = 1:ntapconds
	
	if strcmp(curr_cat,'silence') && strcmp(tapconds{icond},'no_tap')
	  continue
	end
	
	subplot(nstimcats,ntapconds,(icat-1)*ntapconds+icond)
	bh = ...
	    bar(amt_behave.(behave_group_tag).group.nanmean{curr_cat_idx,icond});
	errorbar_data = ...
	    amt_behave.(behave_group_tag).group.nanstd{curr_cat_idx,icond}./ ...
	    sqrt(amt_behave.(behave_group_tag).group.nsub{curr_cat_idx,icond});
	add_errorbars(bh,errorbar_data');

	switch behave_group_tag
	  case 'body_group_by_rhythm'
	    ymax = 1;
	  case 'misc'
	    ymax = 0.02;
	end
	set(gca,'ylim',[0 ymax]);
	set(gca,'xlim',[0 nbehave+1])
      
	if icond == 1
	  ylabel(strrep(stimcats{curr_cat_idx},'_','\_'))
	end
	if icat == 1
	  title(strrep(tapconds{icond},'_','\_'))
	end
	if icat == nstimcats
	  set(gca,'xticklabel', '')
	  for ib = 1:nbehave
	    text(ib,0,strrep(behavior_info{ib,1},'_','\_'),'rotation',-90);
	  end
	else
	  set(gca,'xticklabel', '')
	end
      
      end % for icond=
    end % for icat =
    
    append_str = '';
    if ibehave_group > 1
      append_str = '-append';
    end
    figfname = fullfile(globals.paths.figpath,'behave_summary_6Aug2009.ps');
    fprintf('Printing figure to %s\n', figfname);
    print(figfname,'-dpsc','-adobecset',append_str);
    
  end % for ibehave_group
end % if GENERATE_FIGS
