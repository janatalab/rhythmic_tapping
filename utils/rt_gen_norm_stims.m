% generate normalized versions of rhythmic tapping stims
% original stims were not normalized
%
% 5/4/2010, S.T.

LOAD_STIM_METADATA = 0;
SUBMIT_TO_DATABASE = 0;
SAVE_TO_DEST = 1;
MAP_STIM_CATS = 0;

CONVERT_TO_WAV = 1; 

maxAmp = 0.999;

halfP = 10.^( -6./20);
quarterP = 10.^(-12./20);

perform = 'maxP';

switch(perform)
 
 case 'halfP'
  pctNorm = maxAmp .* halfP;
  fstubAdd = 'halfP';
 case 'quarterP'
  pctNorm = maxAmp .* quarterP;
  fstubAdd = 'quarterP';
 case 'maxP'
  pctNorm = maxAmp;
  fstubAdd = '0.999max';
end


destStimPath = 'audio/rhythmic_tapping_normalized/';
%destStimPath = '/home/stefan/rt_norm_temp';

ensemble_globals;
globals = rhythmTap_globals;
conn_id = 7;
mysql_make_conn('atonal.ucdavis.edu','ensemble_main',conn_id);

%stimulus_root = '';

if(LOAD_STIM_METADATA)

  na=1;
  an{na}.name = 'ensemble_load_expinfo';
  an{na}.fun  = @ensemble_load_expinfo;
  an{na}.params.ensemble.experiment_title='rhythmic_tapping_v2';
  an{na}.params.ensemble.remove_incomplete_sessions = 1;
  an{na}.params.filt = globals.ensemble.filt;
  an{na}.params.filt.exclude.all.stimulus_id = globals.ensemble.silence_stim_id;
  an{na}.params.ensemble.conn_id = globals.ensemble.conn_id;
  
  jmParams.ensemble.conn_id = conn_id;
  jmParams.run_analyses = [1];
  an = ensemble_jobman(an,jmParams);
  
  load_expinfo_results = an{1}.results;
  leCols = set_var_col_const(load_expinfo_results.vars);
  
  stimulus_metadata = load_expinfo_results.data{leCols.stimulus_metadata};
  smCols = set_var_col_const(stimulus_metadata.vars);
end
  
  
nStims = length(stimulus_metadata.data{smCols.stimulus_id});

clear maxSig monoNormRMS monoRMS;

%find the greatest RMS level that we can use
%without causing any stims to clip when normalizing
%we simply normalize all the stims by max amp., find what
%the RMS levels would be, then record the lowest RMS level among these.
%this is the highest possible RMS level we can use to normalize without
%clipping any audio
%{
fprintf('Finding maximum possible RMS level to use. Checking stim ');
for iStim = 1:nStims
  fprintf('%d ',iStim);
  thisStimID = stimulus_metadata.data{smCols.stimulus_id}(iStim);
  thisLocation = fullfile(stimulus_root,stimulus_metadata.data{smCols.location}{iStim});
  
  stimSig = read_audio_stim(thisStimID,[],[],[],conn_id);
 
  %normalizing by the maximum sample
  maxSig(iStim) = max(abs(stimSig(:)));
  normSig = stimSig ./ maxSig(iStim) .* ;
  
  monoNormSig = mean(normSig,2);
  monoNormRMS(iStim) = sqrt(mean(monoNormSig .^ 2));
  
  monoSig = mean(stimSig,2);
  monoRMS(iStim) = sqrt(mean(monoSig .^ 2));

end
%}
%normToRMS = min(monoNormRMS);

insertVals = '';
clear finalRMS finalMax finalSaveRMS finalSaveMax
for iStim = 1:nStims

  thisStimID = stimulus_metadata.data{smCols.stimulus_id}(iStim);
  thisLocation = fullfile(stimulus_root,stimulus_metadata.data{smCols.location}{iStim});
  [p,fstub,ext] = fileparts(thisLocation);
  
  fstub = sprintf('%s_%s',fstub,fstubAdd);
  
  if(CONVERT_TO_WAV)
    fname = [fstub '.wav'];
  else
    fname = [fstub ext];
  end
  
  %normRatio = normToRMS ./ monoRMS(iStim);
  
  stimSig = read_audio_stim(thisStimID,[],[],[],conn_id);

  finalSig = stimSig ./ max(abs(stimSig(:))) .* pctNorm;
  %finalMono = mean(finalSig,2);
  %finalRMS(iStim) = sqrt(mean(finalMono .^ 2));
  finalMax(iStim) = max(abs(finalSig(:)));

  if(SUBMIT_TO_DATABASE)
    
    databaseLoc = fullfile(destStimPath,fname);
    
    if(CONVERT_TO_WAV)
      stimName = [ strrep(stimulus_metadata.data{smCols.name}{iStim},'''','\''') ...
		   sprintf(' (normalized to %.3f max)',pctNorm)];
      stimDesc = sprintf('stim ID %d normalized to %.3f max',thisStimID,pctNorm);
      stimArtist = [strrep(stimulus_metadata.data{smCols.artist}{iStim},'''','\''') ...
		    sprintf(' (normalized to %.3f max)',pctNorm)];
      fileFormat = 'wav';
    else
      stimName = [ strrep(stimulus_metadata.data{smCols.name}{iStim},'''','\''') ...
		   sprintf(' (normalized to %.3f max)',pctNorm)];
      stimDesc = sprintf('stim ID %d normalized to %.3f max',thisStimID,pctNorm);
      stimArtist = [strrep(stimulus_metadata.data{smCols.artist}{iStim},'''','\''') ...
		    sprintf(' (normalized to %.3f max)',pctNorm)];
      fileFormat = 'mp3';
    end
      
    stimAlbum = strrep(stimulus_metadata.data{smCols.album}{iStim},'''','\''');
    stimGenre = strrep(stimulus_metadata.data{smCols.genre}{iStim},'''','\''');
    stimDuration = stimulus_metadata.data{smCols.duration}(iStim);
    stimSr = stimulus_metadata.data{smCols.sample_rate}(iStim);
    
    
    insertVals = [insertVals  sprintf('(''%s'',''%s'',''%s'',''%s'',''%s'',%d,128,''%s'',''%s'')',...
				      stimName,stimDesc,stimArtist,stimAlbum,stimGenre,stimSr,fileFormat,databaseLoc)];
    
    if(iStim ~= nStims)
      insertVals = [insertVals ','];
    end
    
    
  end
  
  
  if(SAVE_TO_DEST)
    
    destLoc = fullfile(stimulus_root,destStimPath,fname);
    if(CONVERT_TO_WAV)
      wavwrite(finalSig,44100,16,destLoc);
      finalSaveSig = wavread(destLoc);
    else
      mp3write(finalSig,44100,16,destLoc);
      finalSaveSig = mp3read(destLoc);
    end
    

    finalSaveMono = mean(finalSaveSig,2);
    finalSaveRMS(iStim) = sqrt(mean(finalSaveMono .^ 2));
    finalSaveMax(iStim) = max(abs(finalSaveSig(:)));
    
  end
  
  
  
  
end

if(SUBMIT_TO_DATABASE)
  
  sql_insert_record = ['insert into stimulus (name,description,artist,album,genre,sample_rate,' ...
		    ' compression_bit_rate,file_format,location) values ' insertVals]
  
  mysql(conn_id,sql_insert_record);
  
  
end

%would have been better to map when creating the stims. But this was done after
%the fact.
if(MAP_STIM_CATS)
  
  begin_stim_id = 50137;
  end_stim_id = 50184;

  [orig_low_groove_stims,low_groove_att] = mysql(conn_id,['select stimulus_id,attribute.name from attribute left' ...
		    ' join stimulus_x_attribute using (attribute_id) where' ...
		     ' attribute.name = ''real_music_low_groove''']);
  [orig_mid_groove_stims,mid_groove_att] = mysql(conn_id,['select stimulus_id,attribute.name from attribute left' ...
		    ' join stimulus_x_attribute using (attribute_id) where' ...
		     ' attribute.name = ''real_music_mid_groove''']);
  [orig_high_groove_stims,high_groove_att] = mysql(conn_id,['select stimulus_id,attribute.name from attribute left' ...
		    ' join stimulus_x_attribute using (attribute_id) where' ...
		     ' attribute.name = ''real_music_high_groove''']);
  
  
  
  
  
  sql_get_new_stims = sprintf(['select description,stimulus_id from stimulus' ...
		    ' where stimulus_id >= %d and stimulus_id <= %d'],begin_stim_id,end_stim_id);
  [newDesc,newStimIDs] = mysql(conn_id,sql_get_new_stims);
  nStims = length(newStimIDs);

  new_low_groove_attribute_id = mysql(conn_id,'select attribute_id from attribute where name = ''real_music_low_groove_normalizedMid''');
  new_mid_groove_attribute_id = mysql(conn_id,['select attribute_id from' ...
		    ' attribute where name = ''real_music_mid_groove_normalizedMid''']);
  new_high_groove_attribute_id = mysql(conn_id,['select attribute_id from' ...
		    ' attribute where name = ''real_music_high_groove_normalizedMid''']);  
  new_low_groove_stims = [];
  new_mid_groove_stims = [];
  new_high_groove_stims = [];
  
  if(~exist('grooveStimMap'))
    grooveStimMap = ensemble_init_data_struct;
    grooveStimMap.vars = {'orig_stimID','highNorm_stimID','midNorm_stimID','lowNorm_stimID','groove_category'};
    gsmCols = set_var_col_const(grooveStimMap.vars);
    
    grooveStimMap.data{gsmCols.orig_stimID} = [orig_low_groove_stims ; orig_mid_groove_stims ; orig_high_groove_stims];
    grooveStimMap.data{gsmCols.groove_category} = low_groove_att;
    grooveStimMap.data{gsmCols.groove_category}(end+1:end+16) = mid_groove_att;
    grooveStimMap.data{gsmCols.groove_category}(end+1:end+16) = high_groove_att;
	
  end
    
  for iStim = 1:nStims
      
    thisNewID = newStimIDs(iStim);
    thisDesc = newDesc{iStim};
    matches = regexp(thisDesc,'stim ID (\d+).*','tokens');
    origStimID = str2num(matches{1}{1});
      
     
    if(ismember(origStimID,orig_low_groove_stims))
      new_low_groove_stims(end+1) = thisNewID;
      sql_attr = sprintf('insert into stimulus_x_attribute (attribute_id,stimulus_id) values (%d,%d)',new_low_groove_attribute_id,thisNewID);
    elseif(ismember(origStimID,orig_mid_groove_stims))
      new_mid_groove_stims(end+1) = thisNewID;
      sql_attr = sprintf('insert into stimulus_x_attribute (attribute_id,stimulus_id) values (%d,%d)',new_mid_groove_attribute_id,thisNewID);
    elseif(ismember(origStimID,orig_high_groove_stims))
      new_high_groove_stims(end+1) = thisNewID;
      sql_attr = sprintf('insert into stimulus_x_attribute (attribute_id,stimulus_id) values (%d,%d)',new_high_groove_attribute_id,thisNewID);
    end
    
  
    %stimM(iStim,:) = [origStimID thisNewID];
    
    
    rowIdx = find(grooveStimMap.data{gsmCols.orig_stimID} == origStimID);
    grooveStimMap.data{gsmCols.lowNorm_stimID}(rowIdx) = thisNewID;
    iStim
    sql_attr
    mysql(conn_id,sql_attr)    
    
    
    
  end
  
  
  
  
  
end