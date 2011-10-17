%analysis list for rhythmic tapping
%
% Note that svn/private/matlab/projects/rhythmic_tapping/utils has to be on
% the path

% 24Sep2010 - PJ - picking up where script was left off

SUMMARIZE_SUBS_AND_STIMS = 0;

if isempty(which('parse_loudness_and_grooveLevel'))
  addpath('../utils')
end

globals = rhythmTap_globals; 

%store form defs in a more easily accessed variable
form_defs = globals.ensemble.form_defs;


% Create an array of analysis structures
%clear an;
na = 0;

na=na+1;
an{na}.name = 'ensemble_load_expinfo';
an{na}.fun  = @ensemble_load_expinfo;
an{na}.params.filt = globals.ensemble.filt;
an{na}.params.ensemble = globals.ensemble;
an{na}.params.ensemble.experiment_title='rhythmic_tapping_normalization';
an{na}.params.ensemble.remove_incomplete_sessions = 1;

na=na+1;
an{na}.name = 'parse_loudness_and_grooveLevel';
an{na}.fun = @parse_loudness_and_grooveLevel;
an{na}.requires = {struct('name','ensemble_load_expinfo','vars','stimulus_x_attribute_metadata')};

na=na+1;
an{na}.name = 'ensemble_export_respnstim';
an{na}.fun = @ensemble_export_respnstim;
an{na}.params.export.by_stimulus.stimulus_x_attribute_metadata.vars = {'stimulus_id','name','groove_level','norm_level'};
an{na}.params.write2file = 1;
an{na}.params.fname = fullfile(globals.paths.datapath,'rhythmic_tapping_normalization_responses.txt');
an{na}.params.export.var_name_map.s207_01 = 'enjoyed_music';
an{na}.params.export.var_name_map.s493_01 = 'music_grooved';
an{na}.params.export.var_name_map.s505_01 = 'continue_task';
an{na}.params.export.var_name_map.s506_01 = 'familiar';
an{na}.params.export.var_name_map.s911_01 = 'felt_in_groove';
an{na}.params.mysql.conn_id = globals.ensemble.conn_id;
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
an{na}.params = globals.stimIPEMParams;
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;
an{na}.requires = {struct('name','filter normalized high')};

%correlate timing with tempo

params.ensemble.conn_id = 7;
params.run_analyses = [3];
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
return