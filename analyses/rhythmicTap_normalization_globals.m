function defs = rhythmicTap_normalization_globals
% Used for analyses of rhythmic_tapping_normalization data

% 28Dec2013 Petr Janata - created script when modifying
% rhythmTap_normalization_analyze.m to export mean groove ratings

% Path info
project_root = '/data2/rhythm/rhythmic_tapping_v2'; check_dir(project_root);
defs.paths.analyses = fullfile(project_root,'analyses'); check_dir(defs.paths.analyses);
defs.paths.datapath = fullfile(project_root, 'project_data'); check_dir(defs.paths.datapath);

% Ensemble info
defs.mysql.host = 'atonal.ucdavis.edu';
defs.mysql.database = 'ensemble_main';
defs.mysql.conn_id = 7;
defs.mysql.login_type = 'researcher';
defs.mysql = mysql_login(defs.mysql);

% Filtering
defs.ensemble.filt.exclude.any.subject_id = {'tmp_*', '01fmt54011', ...
		    '01fss85301','01ttf*','01ttf50011','01ttf51011','01ttf52011','01ttf53011','01ttf84011','01ttf99011','09nlr84261','12hnd81021','05vsb78121'};

end