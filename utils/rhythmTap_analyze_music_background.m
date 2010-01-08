%script to analyze musical background for rhythmic tapping


globals = rhythmTap_globals; 

dbstop if error

load (fullfile(globals.paths.datapath,...
	       'rhythmTap_response_rprofile_analysis_21May2008_11:21.mat'));

resp = an{1}.results.data{3};
respCols = set_var_col_const(resp.vars);
uniqueQid = unique(resp.data{respCols.question_id});


%obtain metadata for all questions in the experiment
qMeta = mysql_extract_metadata('table','question','question_id',uniqueQid);

metaQids = [qMeta.question_id];
metaSubQ = [qMeta.subquestion];

respQids = resp.data{respCols.question_id};
respsubQ = resp.data{respCols.subquestion};

