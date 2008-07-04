% populates the trial table for rhythmic tapping experiment
% this was written for rhythmic_tapping_v2 (v1 only differs by question_ids as
% far as this is concerned)

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


sql_insert_low_groove_FFTM = ['insert into trial (stimulus_id1,question_id) select' ...
      sprintf(' stimulus_id,%d FROM stimulus_x_attribute LEFT JOIN attribute USING ( attribute_id )',QID(FREE_FORM_TAP_MUSIC)) ...
      ' WHERE attribute.name =  ''real_music_low_groove'' '];

mysql(MYSQL_CONN_ID,sql_insert_low_groove_FFTM);

sql_insert_low_groove_ITM = ['insert into trial (stimulus_id1,question_id) select' ...
      sprintf(' stimulus_id,%d FROM stimulus_x_attribute LEFT JOIN attribute USING ( attribute_id )',QID(ISO_TAP_MUSIC)) ...
      ' WHERE attribute.name =  ''real_music_low_groove'' '];

mysql(MYSQL_CONN_ID,sql_insert_low_groove_ITM);

sql_insert_low_groove_NTM = ['insert into trial (stimulus_id1,question_id) select' ...
      sprintf(' stimulus_id,%d FROM stimulus_x_attribute LEFT JOIN attribute USING ( attribute_id )',QID(NO_TAP_MUSIC)) ...
      ' WHERE attribute.name =  ''real_music_low_groove'' '];

mysql(MYSQL_CONN_ID,sql_insert_low_groove_NTM);

sql_insert_mid_groove_FFTM = ['insert into trial (stimulus_id1,question_id) select' ...
      sprintf(' stimulus_id,%d FROM stimulus_x_attribute LEFT JOIN attribute USING ( attribute_id )',QID(FREE_FORM_TAP_MUSIC)) ...
      ' WHERE attribute.name =  ''real_music_mid_groove'' '];

mysql(MYSQL_CONN_ID,sql_insert_mid_groove_FFTM);

sql_insert_mid_groove_ITM = ['insert into trial (stimulus_id1,question_id) select' ...
      sprintf(' stimulus_id,%d FROM stimulus_x_attribute LEFT JOIN attribute USING ( attribute_id )',QID(ISO_TAP_MUSIC)) ...
      ' WHERE attribute.name =  ''real_music_mid_groove'' '];

mysql(MYSQL_CONN_ID,sql_insert_mid_groove_ITM);

sql_insert_mid_groove_NTM = ['insert into trial (stimulus_id1,question_id) select' ...
      sprintf(' stimulus_id,%d FROM stimulus_x_attribute LEFT JOIN attribute USING ( attribute_id )',QID(NO_TAP_MUSIC)) ...
      ' WHERE attribute.name =  ''real_music_mid_groove'' '];

mysql(MYSQL_CONN_ID,sql_insert_mid_groove_NTM);

sql_insert_high_groove_FFTM = ['insert into trial (stimulus_id1,question_id) select' ...
      sprintf(' stimulus_id,%d FROM stimulus_x_attribute LEFT JOIN attribute USING ( attribute_id )',QID(FREE_FORM_TAP_MUSIC)) ...
      ' WHERE attribute.name =  ''real_music_high_groove'' '];

mysql(MYSQL_CONN_ID,sql_insert_high_groove_FFTM);

sql_insert_high_groove_ITM = ['insert into trial (stimulus_id1,question_id) select' ...
      sprintf(' stimulus_id,%d FROM stimulus_x_attribute LEFT JOIN attribute USING ( attribute_id )',QID(ISO_TAP_MUSIC)) ...
      ' WHERE attribute.name =  ''real_music_high_groove'' '];

mysql(MYSQL_CONN_ID,sql_insert_high_groove_ITM);

sql_insert_high_groove_NTM = ['insert into trial (stimulus_id1,question_id) select' ...
      sprintf(' stimulus_id,%d FROM stimulus_x_attribute LEFT JOIN attribute USING ( attribute_id )',QID(NO_TAP_MUSIC)) ...
      ' WHERE attribute.name =  ''real_music_high_groove'' '];

mysql(MYSQL_CONN_ID,sql_insert_high_groove_NTM);


%insert the silent stims

sql_insert_silence_iso = sprintf('insert into trial (stimulus_id1,question_id) values(%d,%d) ',SILENCE_CUE_STIM_ID,QID(ISO_TAP_SILENCE));
mysql(MYSQL_CONN_ID,sql_insert_silence_iso);

sql_insert_silence_fft = sprintf('insert into trial (stimulus_id1,question_id) values(%d,%d) ',SILENCE_CUE_STIM_ID,QID(FREE_FORM_TAP_SILENCE));
mysql(MYSQL_CONN_ID,sql_insert_silence_fft);