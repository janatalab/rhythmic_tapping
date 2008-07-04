function outData = plot_stimRPMovieFrames(inData,params)

ensemble_globals;

%PROBABLY NOT NEEDED. TAKE IT OUT NEXT TIME IT'S RUN
%clear searchCrit;
%searchCrit.type = 'session_x_trial_info';
%findIdx = ensemble_find_analysis_struct(inData,searchCrit);
%sessTrials = inData{findIdx};
%sessTrialsCols = set_var_col_const(sessTrials.vars);

thisStimID = params.stimulus_id;

ipemOut = ipem_proc_series(thisStimID,params.ipem);
ipemOutCols = set_var_col_const(ipemOut.vars);
rp = ipemOut.data{ipemOutCols.rp};

%deal with cell data struct weirdness
if(iscell(rp))
  rp = rp{1};
end

[stimPath,fname,ext] = fileparts(params.location);

stimDir = sprintf('stimulusID_%d_%s_%s',params.stimulus_id,params.artist,params.song_name);
stimDir = strrep(stimDir,' ','_');
stimDir = regexprep(stimDir,'[^\w_]*','');

params.plot.path = fullfile(params.movieRootPath,stimDir);

status = check_dir(params.plot.path);
if(status)
  error(sprintf('Could not create directory %s',params.plot.path));
end

mp3FLoc = fullfile(stimulus_root,params.location);
success = copyfile(mp3FLoc,params.plot.path);
if(~success)
  error(sprintf('Error coping file %s to movie directory',mp3FLoc));
end


movieData{1} = rp;

if(ismember('tapdata',params.process))

  params.getTrialsParams.ensemble = params.ensemble;  
  numTrialGroups = length(params.tappingConditions);
  groupIdxs = [];
  for iTapCond = 1:numTrialGroups
    params.getTrialsParams.filt.include.all.stimulus_id = params.stimulus_id;
    params.getTrialsParams.filt.include.all.tapping_condition = {params.tappingConditions{iTapCond}};
    trialsThisStimCond = filtSessTrials(inData,params.getTrialsParams);
    trialAudGroup = trialMidiResp2Aud(trialsThisStimCond,params.nmat2aud);
  
    %alternate between black and red line colors for tap data groups
    params.plot.tapData.lineColor = [1 0 0].*mod(iTapCond-1,2);
  end
 

  params.plot.tapData.tappingConditions = params.tappingConditions;
  params.plot.tapData.inputSigType = 'impulse';
  
  movieData(end+1:end+length(trialAudGroup)) = trialAudGroup;
  %deal with existence of params.plot.process field or 
  %missing 'tapdata tag
  if(~isfield(params.plot,'process'))
    params.plot.process = {'tapdata'};
  end
  params.plot.process = union(params.plot.process,'tapdata');
else
  params.plot.process = {};
end

plot_rpMovieFrames(movieData,params.plot);

outData = [];

return

