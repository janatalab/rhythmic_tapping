%analysis list for rhythmic tapping


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
an{na}.params.mysql.conn_id = globals.ensemble.conn_id;
an{na}.requires = {struct('name','ensemble_load_expinfo','vars','response_data'),...
		   struct('name','parse_loudness_and_grooveLevel'),...
		   struct('name','ensemble_load_expinfo','vars','subject_info'),...
		  };

na=na+1;
an{na}.name = 'filter normalized high'
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
na=na+1;
an{na}.name=
an{na}.fun = 
an{na}.params = 
an{na}.requires = 

params.ensemble.conn_id = 7;
params.run_analyses = [5];
an = ensemble_jobman(an,params);
return