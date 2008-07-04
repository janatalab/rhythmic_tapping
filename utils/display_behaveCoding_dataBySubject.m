%a quick and dirty display script to look at behavior coding
%analysis results - S.T>.

globals = rhythmTap_globals;

outputFile = fullfile(globals.paths.logpath,'behaveCodingQuickStats_9July.txt');

if(exist(outputFile,'file'))
  delete(outputFile);
end

behaveCoding = an{3}.results;
behaveCodingCols = set_var_col_const(behaveCoding.vars);

subIDList = unique(behaveCoding.data{behaveCodingCols.subject_id});


for iSub = 1:length(subIDList)

  thisSubID = subIDList{iSub};
  
  fprintf('Processing subject: %s',thisSubID);
  
  for thisCoderID = 1:2
  
    clear tmpFilt;
    tmpFilt.include.all.subject_id = {thisSubID};
    tmpFilt.include.all.coder_id = thisCoderID;
    behaveCodingThisSub = ensemble_filter(behaveCoding,tmpFilt);
    
    clear tmpFilt
    tmpFilt.include.all.stimulus_category = {'low_groove','mid_groove','high_groove'};
    tmpFilt.include.all.tapping_condition = {'iso_tap'};
    behaveCoding_music_iso = ensemble_filter(behaveCodingThisSub,tmpFilt);
    %only interested in hand tapping behaviors, so find indices
    %where these occur (since we're checking a substring, it's not
    %easy to filter)
    music_iso_idxs = strncmp(behaveCoding_music_iso.data{behaveCodingCols.behavior},'hand tapping',12);
    
    clear tmpFilt
    tmpFilt.include.all.stimulus_category = {'silence'};
    tmpFilt.include.all.tapping_condition = {'iso_tap'};
    behaveCoding_silence_iso = ensemble_filter(behaveCodingThisSub,tmpFilt);
    silence_iso_idxs = strncmp(behaveCoding_silence_iso.data{behaveCodingCols.behavior},'hand tapping',12);
    
    clear tmpFilt
    tmpFilt.include.all.stimulus_category = {'low_groove','mid_groove','high_groove'};
    tmpFilt.include.all.tapping_condition = {'free_form_tap'};
    behaveCoding_music_free_form = ensemble_filter(behaveCodingThisSub,tmpFilt);
    music_free_form_idxs = strncmp(behaveCoding_music_free_form.data{behaveCodingCols.behavior},'hand tapping',12);    

    clear tmpFilt
    tmpFilt.include.all.stimulus_category = {'silence'};
    tmpFilt.include.all.tapping_condition = {'free_form_tap'};
    behaveCoding_silence_free_form = ensemble_filter(behaveCodingThisSub,tmpFilt);
    silence_free_form_idxs = strncmp(behaveCoding_silence_free_form.data{behaveCodingCols.behavior},'hand tapping',12);
    
    mean_prop_music_iso = mean(behaveCoding_music_iso.data{behaveCodingCols.behavior_proportion}(music_iso_idxs));
    std_prop_music_iso = std(behaveCoding_music_iso.data{behaveCodingCols.behavior_proportion}(music_iso_idxs));
    mean_prop_silence_iso = mean(behaveCoding_silence_iso.data{behaveCodingCols.behavior_proportion}(silence_iso_idxs));
    std_prop_silence_iso = std(behaveCoding_silence_iso.data{behaveCodingCols.behavior_proportion}(silence_iso_idxs));
    mean_prop_music_free_form = mean(behaveCoding_music_free_form.data{behaveCodingCols.behavior_proportion}(music_free_form_idxs));
    std_prop_music_free_form = std(behaveCoding_music_free_form.data{behaveCodingCols.behavior_proportion}(music_free_form_idxs));
    mean_prop_silence_free_form = mean(behaveCoding_silence_free_form.data{behaveCodingCols.behavior_proportion}(silence_free_form_idxs));
    std_prop_silence_free_form = std(behaveCoding_silence_free_form.data{behaveCodingCols.behavior_proportion}(silence_free_form_idxs));  
    
    mean_propTotal_music_iso = mean(behaveCoding_music_iso.data{behaveCodingCols.beh_prop_total}(music_iso_idxs));
    std_propTotal_music_iso = std(behaveCoding_music_iso.data{behaveCodingCols.beh_prop_total}(music_iso_idxs));
    mean_propTotal_silence_iso = mean(behaveCoding_silence_iso.data{behaveCodingCols.beh_prop_total}(silence_iso_idxs));
    std_propTotal_silence_iso = std(behaveCoding_silence_iso.data{behaveCodingCols.beh_prop_total}(silence_iso_idxs));
    mean_propTotal_music_free_form = mean(behaveCoding_music_free_form.data{behaveCodingCols.beh_prop_total}(music_free_form_idxs));
    std_propTotal_music_free_form = std(behaveCoding_music_free_form.data{behaveCodingCols.beh_prop_total}(music_free_form_idxs));
    mean_propTotal_silence_free_form = mean(behaveCoding_silence_free_form.data{behaveCodingCols.beh_prop_total}(silence_free_form_idxs));
    std_propTotal_silence_free_form = std(behaveCoding_silence_free_form.data{behaveCodingCols.beh_prop_total}(silence_free_form_idxs));  

    fid = fopen(outputFile,'at');
    fprintf(fid,[repmat('-',1,80) '\n\n']);
    fprintf(fid,'Subject ID %s\n\n',thisSubID);
    
    fprintf(fid,'Coder %d results:\n\nMeans:\n---------------\n',thisCoderID);
    fclose(fid);
    
    disp = ensemble_init_data_struct;
    
    disp.vars = {'data' 'column_labels' 'column_formats'};
    dispCols = set_var_col_const(disp.vars);
    
    disp.data{dispCols.data} = ...
	{mean_prop_music_iso mean_prop_silence_iso ...
	 mean_prop_music_free_form mean_prop_silence_free_form ...
	 mean_propTotal_music_iso mean_propTotal_silence_iso ...
	 mean_propTotal_music_free_form mean_propTotal_silence_free_form};

    
    disp.data{dispCols.column_labels} = {'music_iso' 'silence_iso' ...
		    'music_free_form' 'silence_free_form' ...
		    'music_iso_total' 'silence_iso_total' ...
		    'music_free_form_total' 'silence_free_form_total'};
	
	
    disp.data{dispCols.column_formats} = {'%9.2f' '%11.2f' '%15.2f' ...
		    '%13.2f' '%15.2f' '%17.2f' '%21.2f' '%23.2f'};
    
    dispParams.fname = outputFile;
    dispParams.write2file = 1;
    dispParams.filemode = 'at';
    ensemble_display_table(disp,dispParams);
  
    fid = fopen(outputFile,'at');
    fprintf(fid,'\n\n\nStandard Devs:\n-------------\n');
    fclose(fid);
    
    disp.data{dispCols.data} = ...
	{std_prop_music_iso std_prop_silence_iso ...
	 std_prop_music_free_form std_prop_silence_free_form ...
	 std_propTotal_music_iso std_propTotal_silence_iso ...
	 std_propTotal_music_free_form std_propTotal_silence_free_form};

    disp.data{dispCols.column_formats} = {'%8.2f' '%10.2f' '%14.2f' ...
		    '%12.2f' '%14.2f' '%16.2f' '%20.2f' '%22.2f'};

    dispParams.filemode = 'at';
    ensemble_display_table(disp,dispParams);
  
 
  end

end
