%analysis list for rhythmic tapping
%
% Note that svn/private/matlab/projects/rhythmic_tapping/utils has to be on
% the path

% 24Sep2010 - PJ - picking up where script was left off
% 28Dec2013 PJ - modified to handle mean groove rating analysis for
%                collaboration with Michael Hove

SUMMARIZE_SUBS_AND_STIMS = 0;
REPORT_AVERAGE_GROOVE_RATING = 1;
avgGrooveRatingFile = 'rhythmic_tapping_normalization_mean_goove_rating.txt';

if isempty(which('parse_loudness_and_grooveLevel'))
  addpath('../utils')
end

globals = rhythmicTap_normalization_globals; % rhythmTap_globals for original March 2012 analyses of the data

%store form defs in a more easily accessed variable
form_defs = make_form_name_defs(globals);

% Create an array of analysis structures
%clear an;
na = 0;

na=na+1;
an{na}.name = 'ensemble_load_expinfo';
an{na}.fun  = @ensemble_load_expinfo;
if isfield(globals, 'mysql')
  an{na}.params.mysql = globals.mysql;
end
if isfield(globals,'ensemble')
  an{na}.params.ensemble = globals.ensemble;
end
an{na}.params.ensemble.experiment_title='rhythmic_tapping_normalization';
an{na}.params.ensemble.remove_incomplete_sessions = 1;
an{na}.params.filt = globals.ensemble.filt;

na=na+1;
an{na}.name = 'parse_loudness_and_grooveLevel';
an{na}.fun = @parse_loudness_and_grooveLevel;
an{na}.params.filt.include.all.name = {'real_music_high_groove_normalizedHigh','real_music_high_groove_normalizedMid','real_music_high_groove_normalizedLow', ...
  'real_music_mid_groove_normalizedHigh','real_music_mid_groove_normalizedMid','real_music_mid_groove_normalizedLow', ...
  'real_music_low_groove_normalizedHigh','real_music_low_groove_normalizedMid','real_music_low_groove_normalizedLow'};
an{na}.requires = {struct('name','ensemble_load_expinfo','vars','stimulus_x_attribute_metadata')};

na=na+1;
an{na}.name = 'ensemble_export_respnstim';
an{na}.fun = @ensemble_export_respnstim;
an{na}.params.mysql = globals.mysql;
an{na}.params.export.by_stimulus.stimulus_x_attribute_metadata.vars = {'stimulus_id','name','groove_level','norm_level'};
an{na}.params.write2file = 0;
an{na}.params.fname = fullfile(globals.paths.datapath,'rhythmic_tapping_normalization_responses.txt');
an{na}.params.export.var_name_map.s207_01 = 'enjoyed_music';
an{na}.params.export.var_name_map.s493_01 = 'music_grooved';
an{na}.params.export.var_name_map.s505_01 = 'continue_task';
an{na}.params.export.var_name_map.s506_01 = 'familiar';
an{na}.params.export.var_name_map.s911_01 = 'felt_in_groove';
an{na}.requires = {struct('name','ensemble_load_expinfo','vars','response_data'),...
		   struct('name','parse_loudness_and_grooveLevel'),...
		   struct('name','ensemble_load_expinfo','vars','subject_info'),...
		  };

na=na+1;
an{na}.name = 'filter normalized high';
an{na}.fun = @ensemble_filter;
an{na}.params.include.all.norm_level = {'normalizedHigh'};
an{na}.requires = {struct('name','parse_loudness_and_grooveLevel')};



%run rhythm profiler
na=na+1;
an{na}.name = 'rhythm_profiler';
an{na}.fun = @ipem_proc_series;
if isfield(globals,'stimIPEMParams')
  an{na}.params = globals.stimIPEMParams;
end
an{na}.params.mysql = globals.mysql;
an{na}.requires = {struct('name','filter normalized high')};

%correlate timing with tempo

params.ensemble.conn_id = 7;
params.run_analyses = [];
an = ensemble_jobman(an,params);

if SUMMARIZE_SUBS_AND_STIMS
	an_idx = 3;
	
	data = an{an_idx}.results.data;
	cols = set_var_col_const(an{an_idx}.results.vars);
	
	subs = unique(data{cols.subject_id});
	nsubs = length(subs);
	fprintf('%d subjects\n', nsubs);
	
	groove_levels = unique(data{cols.groove_level});
	ngrv = length(groove_levels);
	
	norm_levels = unique(data{cols.norm_level});
	nnorm = length(norm_levels);
	
	for isub = 1:nsubs
		submask = ismember(data{cols.subject_id}, subs{isub});
		for igrv = 1:ngrv
			grvmask = ismember(data{cols.groove_level}, groove_levels{igrv});
			for inorm = 1:nnorm
				normmask = ismember(data{cols.norm_level}, norm_levels{inorm});
				fprintf('%s, %s, %s: %d\n', subs{isub}, groove_levels{igrv}, norm_levels{inorm}, ...
					sum(submask & grvmask & normmask));
			end
		end % for igrv
	end % for isub=
end % if SUMMARIZE_SUBS_AND_STIMS

if REPORT_AVERAGE_GROOVE_RATING
  an_idx = 3;
  outfname = fullfile(globals.paths.analyses, avgGrooveRatingFile);
  fprintf('Writing aveage groove rating data to: %s\n', outfname);
  fid = fopen(outfname,'wt');
	
	data = an{an_idx}.results.data;
	cols = set_var_col_const(an{an_idx}.results.vars);
  
  p.conflict.name = 'keep_original';
  stim_st = ensemble_datastruct2tree(an{1}.results.data{5}, p);
  
  % Get the stimulus IDs
  stimids = unique(data{cols.stimulus_id});
  nstim = length(stimids);
  fprintf(fid,'StimulusID\tName\tN\tMeanGrvRating\tSEMGrvRating\n');
  for istim = 1:nstim
    currStim = stimids(istim);
    stimmask = data{cols.stimulus_id} == currStim;
    
    stim_st_mask = stim_st.stimulus_id == currStim;
    stimName = stim_st.name{stim_st_mask};
    
    rating_mean = mean(data{cols.music_grooved}(stimmask));
    rating_sem = std(data{cols.music_grooved}(stimmask))/sqrt(sum(stimmask));
    fprintf(fid,'%d\t%s\t%d\t%1.2f\t%1.2f\n', currStim, stimName, sum(stimmask), rating_mean, rating_sem);
  end
  fclose(fid);
end
return