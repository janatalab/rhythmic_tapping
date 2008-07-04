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
an{na}.params.ensemble.experiment_title='rhythmic_tapping_v2';
an{na}.params.ensemble.remove_incomplete_sessions = 1;
an{na}.params.filt = globals.ensemble.filt;
an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;

na=na+1;
an{na}.name = 'background_responses';
an{na}.fun = @background_responses;
an{na}.requires = {struct('name','ensemble_load_expinfo','vars', ...
			  'response_data')};

params.ensemble.conn_id = 7;
params.run_analyses = [1 2];
an = ensemble_jobman(an,params);
return
