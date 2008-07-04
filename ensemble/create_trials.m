%script for inserting trials into the trial table for the rhythmic tapping experiment

MYSQL_CONN_ID = 7;
mysql_make_conn([],[],MYSQL_CONN_ID)


music_attributes = {'real_music_low_groove','real_music_mid_groove','real_music_high_groove'};

nattr = length(music_attributes);

FREE_FORM_TAP_MUSIC = 1;
FREE_FORM_TAP_SILENCE = 2;
NO_TAP_MUSIC = 3;
ISO_TAP_MUSIC = 4;
ISO_TAP_SILENCE = 5;

%question ids corresponding to each of the trial types
QID(FREE_FORM_TAP_MUSIC) = 474;
QID(FREE_FORM_TAP_SILENCE) = 477;
QID(NO_TAP_MUSIC) = 476;
QID(ISO_TAP_MUSIC) = 475;
QID(ISO_TAP_SILENCE) = 478;

for(iattr = 1:nattr)

  sql_insert_free_form_tap_music = ['insert into trial(stimulus_id1,question_id) ' ...
	                           sprintf('select stimulus_id,%d from stimulus_x_attribute left join attribute using (attribute_id) where attribute.name = ''%s''', ...
				           QID(FREE_FORM_TAP_MUSIC),music_attributes{iattr})]

  sql_no_tap_music = ['insert into trial(stimulus_id1,question_id) ' ...
	                           sprintf('select stimulus_id,%d from stimulus_x_attribute left join attribute using (attribute_id) where attribute.name = ''%s''', ...
				           QID(NO_TAP_MUSIC),music_attributes{iattr})]

  sql_iso_tap_music = ['insert into trial(stimulus_id1,question_id) ' ...
	                           sprintf('select stimulus_id,%d from stimulus_x_attribute left join attribute using (attribute_id) where attribute.name = ''%s''', ...
				           QID(ISO_TAP_MUSIC),music_attributes{iattr})]

 mysql(MYSQL_CONN_ID,sql_insert_free_form_tap_music);
 mysql(MYSQL_CONN_ID,sql_no_tap_music);
 mysql(MYSQL_CONN_ID,sql_iso_tap_music);

end

sql_free_form_tap_silence = sprintf('insert into trial(stimulus_id1,question_id) values(6497,%d)', QID(FREE_FORM_TAP_SILENCE))
sql_iso_tap_silence = sprintf('insert into trial(stimulus_id1,question_id) values(6497,%d)', QID(ISO_TAP_SILENCE))
mysql(MYSQL_CONN_ID,sql_free_form_tap_silence);
mysql(MYSQL_CONN_ID,sql_iso_tap_silence);

