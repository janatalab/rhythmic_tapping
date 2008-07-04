function trials_by_type = get_rt_trials_by_type


%indices of the QID and PCT vectors, which contain parameters for each of the trial types
FREE_FORM_TAP_MUSIC = 1;
FREE_FORM_TAP_SILENCE = 2;
NO_TAP_MUSIC = 3;
ISO_TAP_MUSIC = 4;
ISO_TAP_SILENCE = 5;
  
%question ids corresponding to each of the trial types
QID(FREE_FORM_TAP_MUSIC) = 602;
QID(FREE_FORM_TAP_SILENCE) = 604;
QID(NO_TAP_MUSIC) = 476;
QID(ISO_TAP_MUSIC) = 603;
QID(ISO_TAP_SILENCE) = 605;

SILENCE_CUE_STIM_ID = 6497;

MYSQL_CONN_ID = 7;
mysql_make_conn([],[],MYSQL_CONN_ID);


sql_free_form_tap_music = sprintf('select trial_id from trial where question_id = %d',QID(FREE_FORM_TAP_MUSIC));
trials_by_type.free_form_tap_music = mysql(MYSQL_CONN_ID,sql_free_form_tap_music);

sql_free_form_tap_silence = sprintf('select trial_id from trial where question_id = %d',QID(FREE_FORM_TAP_SILENCE));
trials_by_type.free_form_tap_silence = mysql(MYSQL_CONN_ID,sql_free_form_tap_silence);

sql_no_tap_music =  sprintf('select trial_id from trial where question_id = %d',QID(NO_TAP_MUSIC));
trials_by_type.no_tap_music = mysql(MYSQL_CONN_ID,sql_no_tap_music);

sql_iso_tap_music = sprintf('select trial_id from trial where question_id = %d',QID(ISO_TAP_MUSIC));
trials_by_type.iso_tap_music = mysql(MYSQL_CONN_ID,sql_iso_tap_music);

sql_iso_tap_silence = sprintf('select trial_id from trial where question_id = %d',QID(ISO_TAP_SILENCE));
trials_by_type.iso_tap_silence = mysql(MYSQL_CONN_ID,sql_iso_tap_silence);


qid_set = ['(' sprintf('%d,',QID(1:end-1)) num2str(QID(end)) ')'];



sql_low_groove = ['select trial_id from trial left join' ...
		    ' stimulus_x_attribute on (trial.stimulus_id1' ...
		    ' = stimulus_x_attribute.stimulus_id) left join' ...
		    ' attribute using (attribute_id) where' ...
		    ' attribute.name = ''real_music_low_groove''' ...
		    ' and question_id in ' qid_set];

trials_by_type.low_groove = mysql(MYSQL_CONN_ID,sql_low_groove);

sql_mid_groove = ['select trial_id from trial left join' ...
		    ' stimulus_x_attribute on (trial.stimulus_id1' ...
		    ' = stimulus_x_attribute.stimulus_id) left join' ...
		    ' attribute using (attribute_id) where' ...
		    ' attribute.name = ''real_music_mid_groove''' ...
		    ' and question_id in ' qid_set];

trials_by_type.mid_groove = mysql(MYSQL_CONN_ID,sql_mid_groove);

sql_high_groove = ['select trial_id from trial left join' ...
		    ' stimulus_x_attribute on (trial.stimulus_id1' ...
		    ' = stimulus_x_attribute.stimulus_id) left join' ...
		    ' attribute using (attribute_id) where' ...
		    ' attribute.name = ''real_music_high_groove''' ...
		    ' and question_id in ' qid_set];

trials_by_type.high_groove = mysql(MYSQL_CONN_ID,sql_high_groove);

trials_by_type.free_form_tap_low_groove = ...
    intersect(trials_by_type.free_form_tap_music,trials_by_type.low_groove);
trials_by_type.free_form_tap_mid_groove = ...
    intersect(trials_by_type.free_form_tap_music,trials_by_type.mid_groove);
trials_by_type.free_form_tap_high_groove = ...
    intersect(trials_by_type.free_form_tap_music,trials_by_type.high_groove);

trials_by_type.iso_tap_low_groove = ...
    intersect(trials_by_type.iso_tap_music,trials_by_type.low_groove);
trials_by_type.iso_tap_mid_groove = ...
    intersect(trials_by_type.iso_tap_music,trials_by_type.mid_groove);
trials_by_type.iso_tap_high_groove = ...
    intersect(trials_by_type.iso_tap_music,trials_by_type.high_groove);

trials_by_type.free_form_tap = [trials_by_type.free_form_tap_music ...
		    ; trials_by_type.free_form_tap_silence];

trials_by_type.iso_tap = [trials_by_type.iso_tap_music ; ...
		    trials_by_type.iso_tap_silence];

trials_by_type.silence = [trials_by_type.free_form_tap_silence ;trials_by_type.iso_tap_silence];
