%analysis list for rhythmic tapping
%
% Groove evaluation histograms by groove category and task type

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


%ENUM RESPONSE ANALYSES

na=na+1;
an{na}.name = 'low_groove_stimulus_filter';
an{na}.requires = {struct('name','ensemble_load_expinfo',...
			 'type','stimulus_x_attribute_metadata')};
an{na}.fun = @ensemble_filter;
an{na}.params.filt.include.all.name = {'real_music_low_groove'};
an{na}.params.clobber = 0;

na=na+1;
an{na}.name = 'mid_groove_stimulus_filter';
an{na}.requires = {struct('name','ensemble_load_expinfo',...
			 'type','stimulus_x_attribute_metadata')};
an{na}.fun = @ensemble_filter;
an{na}.params.filt.include.all.name = {'real_music_mid_groove'};
an{na}.params.clobber = 0;

na=na+1;
an{na}.name = 'high_groove_stimulus_filter';
an{na}.requires = {struct('name','ensemble_load_expinfo',...
			 'type','stimulus_x_attribute_metadata')};
an{na}.fun = @ensemble_filter;
an{na}.params.filt.include.all.name = {'real_music_high_groove'};
an{na}.params.clobber = 0;


%running the first four analyses to use the results
%in a subsequent filter

na=na+1;
filterAnSearchCrit.name = 'low_groove_stimulus_filter';
filterAnIdx = ensemble_find_analysis_struct(an,filterAnSearchCrit);
filterResultsSearchCrit.type = 'stimulus_x_attribute_metadata';
filterResultData = an{filterAnIdx}.results{ensemble_find_analysis_struct(an{filterAnIdx}.results,filterResultsSearchCrit)};
filterResultDataCols = set_var_col_const(filterResultData.vars);
an{na}.name = 'low_groove_responses';
an{na}.requires = {struct('name','ensemble_load_expinfo','type','response_data')};
an{na}.params.filt.include.all.stimulus_id = filterResultData.data{filterResultDataCols.stimulus_id};
an{na}.fun = @ensemble_filter;
an{na}.params.clobber = 0;

na=na+1;
filterAnSearchCrit.name = 'mid_groove_stimulus_filter';
filterAnIdx = ensemble_find_analysis_struct(an,filterAnSearchCrit);
filterResultsSearchCrit.type = 'stimulus_x_attribute_metadata';
filterResultData = an{filterAnIdx}.results{ensemble_find_analysis_struct(an{filterAnIdx}.results,filterResultsSearchCrit)};
filterResultDataCols = set_var_col_const(filterResultData.vars);
an{na}.name = 'mid_groove_responses';
an{na}.requires = {struct('name','ensemble_load_expinfo','type','response_data')};
an{na}.params.filt.include.all.stimulus_id = filterResultData.data{filterResultDataCols.stimulus_id};
an{na}.fun = @ensemble_filter;
an{na}.params.clobber = 0;

na=na+1;
filterAnSearchCrit.name = 'high_groove_stimulus_filter';
filterAnIdx = ensemble_find_analysis_struct(an,filterAnSearchCrit);
filterResultsSearchCrit.type = 'stimulus_x_attribute_metadata';
filterResultData = an{filterAnIdx}.results{ensemble_find_analysis_struct(an{filterAnIdx}.results,filterResultsSearchCrit)};
filterResultDataCols = set_var_col_const(filterResultData.vars);
an{na}.name = 'high_groove_responses';
an{na}.requires = {struct('name','ensemble_load_expinfo','type','response_data')};
an{na}.params.filt.include.all.stimulus_id = filterResultData.data{filterResultDataCols.stimulus_id};
an{na}.fun = @ensemble_filter;
an{na}.params.clobber = 0;

na=na+1;
an{na}.name = 'music_no_tap_low_groove_eval';
an{na}.requires = {struct('name','low_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_NOTAP_EVAL_V2;
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_no_tap_low_groove_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_iso_tap_low_groove_eval';
an{na}.requires = {struct('name','low_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_ISO_EVAL_V2;
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_iso_tap_low_groove_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_free_form_tap_low_groove_eval';
an{na}.requires = {struct('name','low_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_FREE_FORM_EVAL_V2;
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_free_form_tap_low_groove_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_no_tap_mid_groove_eval';
an{na}.requires = {struct('name','mid_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_NOTAP_EVAL_V2;
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_no_tap_mid_groove_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_iso_tap_mid_groove_eval';
an{na}.requires = {struct('name','mid_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_ISO_EVAL_V2;
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_iso_tap_mid_groove_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_free_form_tap_mid_groove_eval';
an{na}.requires = {struct('name','mid_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_FREE_FORM_EVAL_V2;
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_free_form_tap_mid_groove_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_no_tap_high_groove_eval';
an{na}.requires = {struct('name','high_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_NOTAP_EVAL_V2;
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_no_tap_high_groove_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_iso_tap_high_groove_eval';
an{na}.requires = {struct('name','high_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_ISO_EVAL_V2;
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_iso_tap_high_groove_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_free_form_tap_high_groove_eval';
an{na}.requires = {struct('name','high_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_FREE_FORM_EVAL_V2;
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_free_form_tap_high_groove_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_low_groove_all_tasks_eval';
an{na}.requires = {struct('name','low_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = ...
    [form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_NOTAP_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_ISO_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_FREE_FORM_EVAL_V2];
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_low_groove_all_tasks_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_mid_groove_all_tasks_eval';
an{na}.requires = {struct('name','mid_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = ...
    [form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_NOTAP_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_ISO_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_FREE_FORM_EVAL_V2];
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_mid_groove_all_tasks_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


na=na+1;
an{na}.name = 'music_high_groove_all_tasks_eval';
an{na}.requires = {struct('name','high_groove_responses','type','response_data')};
an{na}.fun = @ensemble_enum_hist;
an{na}.params.filt.include.all.form_id = ...
    [form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_NOTAP_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_ISO_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_MUSIC_FREE_FORM_EVAL_V2];
an{na}.params.filt.include.all.question_id = fix([globals.groove_question_ids.all]);
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'music_high_groove_all_tasks_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;

%%%%%%%%%%



na=na+1;
an{na}.name = 'silence_all_tasks_eval';
an{na}.fun = @ensemble_enum_hist;
an{na}.requires = {struct('name','ensemble_load_expinfo','type','response_data')};
an{na}.params.filt.include.all.form_id = ...
    [form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_SILENCE_FREE_FORM_EVAL_V2 ...
     form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_SILENCE_ISO_EVAL_V2];
an{na}.params.filt.include.all.question_id =  fix([globals.groove_question_ids.all]);
an{na}.params.filt.include.all.stimulus_id = globals.ensemble.silence_stim_id;
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'silence_all_tasks_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;

na=na+1;
an{na}.name = 'silence_iso_tap_eval';
an{na}.fun = @ensemble_enum_hist;
an{na}.requires = {struct('name','ensemble_load_expinfo','type','response_data')};
an{na}.params.filt.include.all.form_id = [form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_SILENCE_ISO_EVAL_V2];
an{na}.params.filt.include.all.question_id =  fix([globals.groove_question_ids.all]);
an{na}.params.filt.include.all.stimulus_id = globals.ensemble.silence_stim_id;
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'silence_iso_tap_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;

na=na+1;
an{na}.name = 'silence_free_form_tap_eval';
an{na}.fun = @ensemble_enum_hist;
an{na}.requires = {struct('name','ensemble_load_expinfo','type','response_data')};
an{na}.params.filt.include.all.form_id = ...
    [form_defs.form_id_const.RHYTHMIC_TAPPING_GROOVE_SILENCE_FREE_FORM_EVAL_V2];
an{na}.params.filt.include.all.question_id =  fix([globals.groove_question_ids.all]);
an{na}.params.filt.include.all.stimulus_id = globals.ensemble.silence_stim_id;
an{na}.params.display.figs.plot = 1;
an{na}.params.display.figs.write2file = 1;
figstub = 'silence_free_form_tap_eval';
an{na}.params.display.figs.figfname = fullfile(globals.paths.figpath,figstub);
an{na}.params.display.figs.printargs = {'-dps','-append'};
an{na}.params.display.figs.pagehdr.titlefontsize = 12;
an{na}.params.clobber = 0;


globals.run_analyses = 5:length(an);
an = ensemble_jobman(an);

return
