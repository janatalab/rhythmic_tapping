function results = behaviorCodingAnalysis(parsedTrials,params)

SILENCE_STIM_ID = 6497;

trial_qids = [602 604 476 603 605];
trial_conds = {'free_form_tap','free_form_tap', ...
	       'no_tap','iso_tap','iso_tap'};

%build a stim/groove attribute data struct
lowGrooveAttributeID = mysql_extract_data('table','attribute', ...
					     'name','real_music_low_groove','extract_flds','attribute_id','conn_id',params.ensemble.conn_id);
midGrooveAttributeID = mysql_extract_data('table','attribute', ...
					     'name','real_music_mid_groove','extract_flds','attribute_id','conn_id',params.ensemble.conn_id);
highGrooveAttributeID = mysql_extract_data('table','attribute', ...
					      'name','real_music_high_groove','extract_flds','attribute_id','conn_id',params.ensemble.conn_id);

stimGrooveData = mysql_extract_data('table','stimulus_x_attribute','attribute_id',[lowGrooveAttributeID{1},midGrooveAttributeID{1},highGrooveAttributeID{1}],'conn_id',params.ensemble.conn_id,'extract_flds',{'stimulus_id','attribute_id'});


stimGsroove = ensemble_init_data_struct;
stimGroove.vars = {'stimulus_id','groove_rating'};
stimGrooveCols = set_var_col_const(stimGroove.vars);
stimGroove.data{stimGrooveCols.stimulus_id} = ...
    stimGrooveData{1};
stimGroove.data{stimGrooveCols.groove_rating}(stimGrooveData{2} ==  lowGrooveAttributeID{1},1) = {'low_groove'};
stimGroove.data{stimGrooveCols.groove_rating}(stimGrooveData{2} == ...
					       midGrooveAttributeID{1},1) = {'mid_groove'};
stimGroove.data{stimGrooveCols.groove_rating}(stimGrooveData{2} == ...
					       highGrooveAttributeID{1},1) = {'high_groove'};

stimGroove.data{stimGrooveCols.stimulus_id}(end+1) = ...
    SILENCE_STIM_ID;
stimGroove.data{stimGrooveCols.groove_rating}{end+1} = 'silence';

behaveTableFullPath = fullfile(params.behaveTable_path,params.behaveTable_fname);

if(ismember('load_behaviors',params.perform))
  load(behaveTableFullPath,'behaveTable','behaveTableCols');
  behaveTable.vars = {behaveTable.vars{:}};
  behaveTableCols = set_var_col_const(behaveTable.vars);
%  behaveTable.data{behaveTableCols.offset_from_dp} = repmat(NaN, ...
	%					    length(behaveTable.data{behaveTableCols.Time}),1);
  %behaveTable.data{behaveTableCols.tape_label} = repmat({''}, ...
	%					    length(behaveTable.data{behaveTableCols.Time}),1);

elseif(ismember('parse_behaviors',params.perform))
  %parse the behavior coding event logs
  bhParams = params.behave_parser;
  behaveTable = parser_behavioral_coding([],bhParams);
  behaveTable.vars = {behaveTable.vars{:} 'dpTime'};
  behaveTableCols = set_var_col_const(behaveTable.vars);
  behaveTable.data{behaveTableCols.dpTime} = repmat(NaN, ...
						    length(behaveTable.data{behaveTableCols.Time}),1);
  behaveTable.data{behaveTableCols.offset_from_dp} = repmat(NaN, ...
						    length(behaveTable.data{behaveTableCols.Time}),1);
  %behaveTable.data{behaveTableCols.tape_label} = repmat({''}, ...
%						  length(behaveTable.data{behaveTableCols.Time}),1);

  if(ismember('save_behaviors',params.perform))
    
    %the following saves the data that was parsed out from all the
    %coder log files. Since parsing is a lengthy process, the data
    %is saved as an intermediary step here.
    %the trials have not yet been organized into easy to analyze
    %variables (behavior proportion, stimulus ID, tapping cond.,
    %etc). The reorganization occurs in the next block in the
    %trialBehaviors structure
    if(confirm_overwrite_file(behaveTableFullPath))
      save(behaveTableFullPath,'behaveTable','behaveTableCols');
    else
     fprintf('Did not save behavior data because file already exists.\n\n'); 
    end
  end
  
end

%remove subjects that were in the exclude list
clear tmpFilt
tmpFilt.exclude.any.Subject = params.ignoreSubs;
behaveTable = ensemble_filter(behaveTable,tmpFilt);


%read in the start times of the first audio stim in each video recording
%from a log file
fidAudioLog = fopen(params.audioStartLog);
audioLog = textscan(fidAudioLog,'%s%s%s');
audioLogVars = {'tape_label','audio_start_time','tape_dur'};
audioLogCols = set_var_col_const(audioLogVars);
fclose(fidAudioLog);


parsedTrialCols = set_var_col_const(parsedTrials.vars);

%create a tapeEntry structure that has information on each tape
%This loop just makes it easier to calculate the time offsets of
%each video from the DP recording
iTapeEntry = 1;
for audLogIdx = 1:length(audioLog{1})
  
  thisSubjectID = audioLog{audioLogCols.tape_label}{audLogIdx}(1:10);
  thisSessionID = str2num(audioLog{audioLogCols.tape_label}{audLogIdx}(12:15));
  
  if(ismember(thisSubjectID,params.ignoreSubs))
    %if this tape is for a subject we are excluding, go to the next tape
    continue;
  end
  
  %find the session for this tape in the parsedTrials data struct,
  %which contains the start time for each trial relative to the DP recording
  sessionMask = (thisSessionID == parsedTrials.data{parsedTrialCols.session_id}) & ...
		    strcmp(thisSubjectID,parsedTrials.data{parsedTrialCols.subject_id});

  if(~any(sessionMask))
    fprintf(1,'Audio parsing for subject %s not found. Skipping this subject\n\n',thisSubjectID);
    
    %clearing behavioral info for this subject
    
    %NOTE: assuming one session per subject, which is currently the
    %case for rhythmic tapping
    clear tmpFilt
    tmpFilt.exclude.any.Subject = {thisSubjectID};
    behaveTable = ensemble_filter(behaveTable,tmpFilt);
    
    
  else

    %convert time to seconds
    startTimeStr = audioLog{audioLogCols.audio_start_time}{audLogIdx};
    startTimeVals = sscanf(startTimeStr,'%d:%f');  
    durStr = audioLog{audioLogCols.tape_dur}{audLogIdx};
    durTimeVals = sscanf(durStr,'%d:%f');
    tapeEntries(iTapeEntry).tape_label = ...
	audioLog{audioLogCols.tape_label}{audLogIdx};
    tapeEntries(iTapeEntry).audio_start_time = startTimeVals(1)*60+ ...
      startTimeVals(2);
    tapeEntries(iTapeEntry).tape_dur = durTimeVals(1)*60 + durTimeVals(2);
    tapeEntries(iTapeEntry).subject_id = thisSubjectID;
    tapeEntries(iTapeEntry).session_id = thisSessionID;
    tapeEntries(iTapeEntry).tape_num = ...
	str2num(tapeEntries(iTapeEntry).tape_label(17));
    
    parsedTrialList = parsedTrials.data{parsedTrialCols.trial_info}{sessionMask};
    
    parsedTrialListCols = set_var_col_const(parsedTrialList.vars);
    
    if(tapeEntries(iTapeEntry).tape_num == 1)

      %obtain the offset of the video recording relative to DP by
      %looking at the start time of the first stim in each recording
      firstDPOffset = parsedTrialList.data{parsedTrialListCols.start_time_sec}(1);
      tapeEntries(iTapeEntry).offset_from_dp = firstDPOffset - tapeEntries(iTapeEntry).audio_start_time;
      
    elseif(tapeEntries(iTapeEntry).tape_num == 2)
      
      
      %params.secondTapeStartTrial is set when the second tape has
      %an unusual start time (i.e. it doesn't occur right after the
      %first, in between trials). This is a mechanism for handling
      %problems during the videotaping where one or more trials
      %were not videotaped for some reason.
      [knowNextTapeStartTrial,lookupLoc] = find(strcmp(tapeEntries(iTapeEntry).subject_id,params.secondTapeStartTrial{:,1}));
      if(~isempty(knowNextTapeStartTrial))
	nextStimIdx = params.secondTapeStartTrial{lookupLoc,2};
      else
	tapeSubIDs = {tapeEntries.subject_id};
	tapeSessIDs = [tapeEntries.session_id];
	tapeNums = [tapeEntries.tape_num];
	firstTapeMask = strcmp(tapeEntries(iTapeEntry).subject_id,tapeSubIDs) & ...
	    (tapeEntries(iTapeEntry).session_id == tapeSessIDs) ...
	    & tapeNums == 1;
      
	%make sure there is only one tape log per tape
	if(sum(firstTapeMask) ~= 1)
	  fprintf(1,'Tape label %s has more than one tape log\n\n',tapeEntries(iTapeEntry).tape_label);
	end
	
	%let's make sure the subjects match and the tape numbers
        %are as expected for sanity's sake
	if( ~strcmp(tapeEntries(firstTapeMask).subject_id,tapeEntries(iTapeEntry).subject_id) | ...
	   (tapeEntries(firstTapeMask).tape_num ~= 1) | ...
	   (tapeEntries(iTapeEntry).tape_num ~= 2) )
	  fprintf(1,'Problem with tape %s\n\n',tapeEntries(iTapeEntry).tape_label);
	end
	
	firstTapeEndOffset = tapeEntries(firstTapeMask).offset_from_dp ...
	    + tapeEntries(firstTapeMask).tape_dur;
      
	nextStimIdx = ...
	    find(parsedTrialList.data{parsedTrialListCols.start_time_sec} >= firstTapeEndOffset,1);
      end
      
      nextDPOffset = parsedTrialList.data{parsedTrialListCols.start_time_sec}(nextStimIdx);
      
      tapeEntries(iTapeEntry).offset_from_dp = ...
	  nextDPOffset - tapeEntries(iTapeEntry).audio_start_time;
      
      %check to see if the nextDPOffset is one of the has one of
      %the largest time diffs (i.e. it has one of the longest
      %breaks between trials). This will help us ensure that we
      %found the right place to pick nextStimIdx
      
      [trialTimeDiffs,trialTimeDiffIdxs] = sort(diff(parsedTrialList.data{parsedTrialListCols.start_time_sec}));
      
      %trialTimeDiffidxs has the indices of the sorted list (the
      %indices at the end of the list have the greatest diffs)
      %diff indices are also offset by one so we're subtracting one here
      if(~ismember(nextStimIdx-1,trialTimeDiffIdxs(end-5:end)))
	fprintf(1,'Tape label %s doesn''t seem to be matched with the correct trial index\n\n',tapeEntries(iTapeEntry).tape_label);
      end
      
    end

    %add a time column for this tape to behaveTable that reflects
    %the DP time
    behaveTableTapeIdxs = strcmp(tapeEntries(iTapeEntry).tape_label,behaveTable.data{behaveTableCols.ObservationName});
    behaveTable.data{behaveTableCols.dpTime}(behaveTableTapeIdxs,1) = ...
	behaveTable.data{behaveTableCols.Time}(behaveTableTapeIdxs,1) + ...
	tapeEntries(iTapeEntry).offset_from_dp;
    
    %record the offset from dp, so if we want to go back to video
    %time, we can.
    %behaveTable.data{behaveTableCols.offset_from_dp}(behaveTableTapeIdxs,1) = ...
%	repmat(tapeEntries(iTapeEntry).offset_from_dp,sum(behaveTableTapeIdxs),1);
    
    iTapeEntry = iTapeEntry + 1;
  end
  
end

%now put together all the info from behaveTable, tapeEntries, and
%parsedTrials to construct info on which behaviors corresponded
%with which trials and groove attributes

%initialize the new data struct
trialBehaviors = ensemble_init_data_struct;

switch(params.outputFormat)
 case 'one_behavior_per_line'
  body_group_info = assign_behavior_info('body_group_by_rhythm');
  trialBehaviors.vars = {'stimulus_id','trial_id','trial_order', ...
		    'subject_id','stimulus_category', ...
		    'tapping_condition','behavior','body_group','coder_id', ...
		    'behavior_proportion' 'coder_time' 'beh_prop_total' ...
		    'trial_start_stop' 'beh_start_stop' 'offset_from_dp' ...
		   'tape_label'};
 case  'body_group_by_coder'
  body_group_info = assign_behavior_info('body_group');
  nGroups = size(body_group_info,1);
  trialBehaviors.vars = {'stimulus_id','trial_id','trial_order', ...
		    'subject_id','stimulus_category', ...
		    'tapping_condition'};
  trialBehaviors.vars = {trialBehaviors.vars{:} body_group_info{:,1} 'coder_id', ...
		    'coder_time' 'trial_start_stop' 'offset_from_dp' ...
		   'tape_label'};
  timeResolution = params.timeResolution;
end
  
trialBehaviorCols = set_var_col_const(trialBehaviors.vars);
trialBehaviors.data = cell(size(trialBehaviors.vars));

subIDList = unique(behaveTable.data{behaveTableCols.Subject});
coderIDs = unique(behaveTable.data{behaveTableCols.Event_Log_Num});
nCoders = length(coderIDs);

for iSub = 1:length(subIDList)

  thisSubjectID = subIDList{iSub};
  
  clear tmpFilt;
  tmpFilt.include.all.Subject = {thisSubjectID};
  behaviorsThisSub = ensemble_filter(behaveTable,tmpFilt);
  
  %NOTE THAT WE ARE RECORDING BEHAVIOR START AND STOP TIMES IN
  %DIGITAL PEFORMER RELATIVE TIME, RATHER THAN TIME RELATIVE TO THE
  %VIDEO. THIS IS OK, BECAUSE WE ARE ALSO RECORDING TRIAL START AND
  %STOP TIMES RELATIVE TO DP. HOWEVER, THIS IS IMPORTANT IF ONE
  %WANTS TO PARSE THE ACTUAL VIDEO RECORDING
  subBehaviorStartTimes = behaviorsThisSub.data{behaveTableCols.dpTime};
  subBehaviorEndTimes = behaviorsThisSub.data{behaveTableCols.dpTime} ...
      + behaviorsThisSub.data{behaveTableCols.Duration};
	
  %get the list of trials for this subject
  clear tmpFilt
  tmpFilt.include.all.subject_id = {thisSubjectID};
  parsedTrialsForSub = ensemble_filter(parsedTrials,tmpFilt);
  trialList = parsedTrialsForSub.data{parsedTrialCols.trial_info}{1};
  trialListCols = set_var_col_const(trialList.vars);
  
  numPracticeTrials = params.numPracticeTrials;
  %skip the 5 practice trials
  for iTrial = (numPracticeTrials+1):length(trialList.data{trialListCols.trial_id})
    
      thisTrialID = trialList.data{trialListCols.trial_id}(iTrial);
      thisTrialOrder = iTrial - numPracticeTrials;
      thisStimID  = trialList.data{trialListCols.stimulus_id}(iTrial);
      trialStartTime = trialList.data{trialListCols.start_time_sec}(iTrial);
      trialDuration  = trialList.data{trialListCols.dur_sec}(iTrial);
      trialEndTime = trialStartTime + trialDuration;
      grooveRatingIdx = find(stimGroove.data{stimGrooveCols.stimulus_id} ...
			     == thisStimID);
      grooveRating = stimGroove.data{stimGrooveCols.groove_rating}{grooveRatingIdx};
      
      trialInfo = mysql_extract_data('table','trial','trial_id', ...
				     thisTrialID,'extract_vars',{'trial_id','question_id'},...
				     'conn_id',params.ensemble.conn_id);
      taskIdx = find(trialInfo{2} == trial_qids);
      trialCondition = trial_conds{taskIdx};
      
      %these behaviors were seen during this trial. Assign them to trialBehaviors
      behaviorIdxs = find( (subBehaviorStartTimes < trialEndTime) & (subBehaviorEndTimes > trialStartTime) );

      switch(params.outputFormat)
       case 'one_behavior_per_line'
	numToAdd = length(behaviorIdxs);
       case  'body_group_by_coder'
	numToAdd = nCoders;
	nCurrentRecords = length(trialBehaviors.data{trialBehaviorCols.stimulus_id});
	coderIdxs = nCurrentRecords+1:nCurrentRecords+numToAdd;
      end
            
      trialBehaviors.data{trialBehaviorCols.tapping_condition}(end+1:end+numToAdd,1) ...
	  = repmat({trialCondition},numToAdd,1);
      trialBehaviors.data{trialBehaviorCols.stimulus_category}(end+1:end+numToAdd,1) ...
	  = repmat({grooveRating},numToAdd,1);
      trialBehaviors.data{trialBehaviorCols.stimulus_id}(end+1:end+numToAdd,1) = ...
	  repmat(thisStimID,numToAdd,1);
      trialBehaviors.data{trialBehaviorCols.trial_id}(end+1:end+numToAdd,1) = ...
	  repmat(thisTrialID,numToAdd,1);
      trialBehaviors.data{trialBehaviorCols.trial_order}(end+1:end+numToAdd,1) = ...
	  repmat(thisTrialOrder,numToAdd,1);
      trialBehaviors.data{trialBehaviorCols.subject_id}(end+1:end+numToAdd,1)= repmat({thisSubjectID},numToAdd,1);
      nRows = size(trialBehaviors.data{trialBehaviorCols.trial_start_stop},1);
      trialBehaviors.data{trialBehaviorCols.trial_start_stop}(nRows+1:nRows+numToAdd,1:2) = ...
	  repmat([trialStartTime trialEndTime],numToAdd,1);

      %find out which tape this trial was on, and add the
      %offset_from_dp to it. We could have done this from the
      %behaviorsThisSub struct, but not all trials have behavior
      %info
      tapesThisSub = strmatch(thisSubjectID,{tapeEntries(:).subject_id});
      nTapes = length(tapesThisSub);
      for iTape = 1:nTapes
	
	trialTapeTime = trialStartTime - tapeEntries(tapesThisSub(iTape)).offset_from_dp;
	if((trialTapeTime < tapeEntries(tapesThisSub(iTape)).tape_dur) ...
	   && (trialTapeTime > 0) )
	  offsetThisTrial = tapeEntries(tapesThisSub(iTape)).offset_from_dp;
	  tapeLabel = tapeEntries(tapesThisSub(iTape)).tape_label;
	end
      end
      
      trialBehaviors.data{trialBehaviorCols.offset_from_dp}(nRows+1:nRows+numToAdd,1) = ...
	  repmat(offsetThisTrial,numToAdd,1);
      trialBehaviors.data{trialBehaviorCols.tape_label}(nRows+1:nRows+numToAdd,1) = ...
	  repmat({tapeLabel},numToAdd,1);
         
      switch(params.outputFormat)
	
       case 'one_behavior_per_line'

	trialBehaviors.data{trialBehaviorCols.coder_id}(end+1:end+numToAdd,1) = behaviorsThisSub.data{behaveTableCols.Event_Log_Num}(behaviorIdxs);
	trialBehaviors.data{trialBehaviorCols.behavior}(end+1:end+numToAdd,1) ...
	    = behaviorsThisSub.data{behaveTableCols.Behavior}(behaviorIdxs);
            
	useStarts = max(trialStartTime,subBehaviorStartTimes(behaviorIdxs));
	useEnds = min(trialEndTime,subBehaviorEndTimes(behaviorIdxs));
	proportionBehaviors = (useEnds - useStarts)./ (trialEndTime - trialStartTime);
	
	proportionBehaviorsTotals = (subBehaviorEndTimes(behaviorIdxs) ...
				     - subBehaviorStartTimes(behaviorIdxs))./ (trialEndTime - trialStartTime);
      
	trialBehaviors.data{trialBehaviorCols.behavior_proportion}(end+1:end+numToAdd,1) = proportionBehaviors;
	trialBehaviors.data{trialBehaviorCols.beh_prop_total}(end+1:end+numToAdd,1) = proportionBehaviorsTotals;

	trialBehaviors.data{trialBehaviorCols.beh_start_stop}(nRows+1:nRows+numToAdd,1:2) = ...
	    [subBehaviorStartTimes(behaviorIdxs) subBehaviorEndTimes(behaviorIdxs)];
	trialBehaviors.data{trialBehaviorCols.coder_time}(end+1:end+numToAdd,1)=...
	    behaviorsThisSub.data{behaveTableCols.Time}(behaviorIdxs);
      
       case 'body_group_by_coder'
	
	for iCoder = 1:nCoders
	  thisCoderIdx = coderIdxs(iCoder);
	  timeVector = trialStartTime:timeResolution:trialEndTime; 
	  trialBehaviors.data{trialBehaviorCols.coder_id}(thisCoderIdx,1) = iCoder;
	  coderFilt.include.all.Event_Log_Num = iCoder;
	  behaviorsThisCoder = ensemble_filter(behaviorsThisSub,coderFilt);
	  
	  for ibg = 1:nGroups
	    bgTag = body_group_info{ibg,1};
	    bodyGroupIdxs = find(ismember(behaviorsThisCoder.data{behaveTableCols.Behavior},body_group_info{ibg,2}));
	    nBehaviors = length(bodyGroupIdxs);
	    timeMtx = repmat(timeVector,nBehaviors,1);
	    behStartTimes = behaviorsThisCoder.data{behaveTableCols.dpTime}(bodyGroupIdxs);
	    behStopTimes = behaviorsThisCoder.data{behaveTableCols.dpTime}(bodyGroupIdxs) ...
		+  behaviorsThisCoder.data{behaveTableCols.Duration}(bodyGroupIdxs);
	    
	    %creating matrices of behavior start and stop
            %times. Each row corresponds to a given behavior. The
            %start and stop times are simply repeated so that we
            %can create a true/false mask on a time grid
	    behStartTimes = repmat(behStartTimes,1,size(timeVector,2));
	    behStopTimes = repmat(behStopTimes,1,size(timeVector,2));	    
	    timeMtxMask = ((timeMtx >= behStartTimes) & (timeMtx <= behStopTimes));

	    %time grid is squashed so that we have a simple
            %true/false vector for the whole behavior group.
	    timeMask = any(timeMtxMask);

	    %time proportion is simply then the number of time
            %samples which behavior was exhibited over all time samples 
	    timeProp = sum(timeMask)./length(timeMask);
	    trialBehaviors.data{trialBehaviorCols.(bgTag)}(thisCoderIdx,1) = timeProp;
	    
	  end
	  
	end
      end
  end
  

end

%%%%%%ASSIGN RHYTHMIC/NON-RHYTHMIC, BODY PART COLUMNS IF OUTPUTTING
%ONE BEHAVIOR PER LINE %%%%%

if(strcmp(params.outputFormat,'one_behavior_per_line'))

  %initialize the is_rhythmic variable to NaNs. If
  %any(isnan(is_rhythmic)) after assigning data to this variable,
  %then we are missing some behaviors in body_rhythmic_groups
  datasize = size(trialBehaviors.data{trialBehaviorCols.stimulus_id});
  trialBehaviors.data{trialBehaviorCols.is_rhythmic} = nan(datasize);
  trialBehaviors.data{trialBehaviorCols.body_group} = {};
  
  body_rhythmic_groups = assign_behavior_info('body_group_by_rhythm');
  nbg = size(body_rhythmic_groups,1);
  behaviorList = trialBehaviors.data{trialBehaviorCols.behavior};

  %assign rhythmic/non-rhythmic column to body_rhythmic_groups
  for ibg = 1:nbg
  
    [rhythTag,remTok] = strtok(body_rhythmic_groups{ibg,1},',');
    body_group = strtok(remTok,',');
  
    all_behavior_groups{ibg,1} = body_group;
    all_behavior_groups{ibg,2} = rhythTag;
    all_behavior_groups{ibg,3} = body_rhythmic_groups{ibg,2};
  end

  misc_groups = assign_behavior_info('misc');
  nmisc = size(misc_groups,1);
  nall = size(all_behavior_groups,1);
  all_behavior_groups(nall+1:nall+nmisc,1) = misc_groups(:,1);
  all_behavior_groups(nall+1:nall+nmisc,2) = repmat({'non_rhythmic'},nmisc,1);
  all_behavior_groups(nall+1:nall+nmisc,3) = misc_groups(:,2);

  nbg = size(all_behavior_groups,1);
  for ibg = 1:nbg
  
    behaviorsThisGroup = all_behavior_groups{ibg,3};
    maskThisGroup = ismember(behaviorList,behaviorsThisGroup);
    
    body_group = all_behavior_groups{ibg,1};
    rhythTag = all_behavior_groups{ibg,2};
    
    is_rhythmic = strcmp(rhythTag,'rhythmic');

    %a little sanity check here to make sure we are only dealing with
    %'rhythmic' and 'non_rhythmic' strings
    if(~is_rhythmic && ~strcmp(rhythTag,'non_rhythmic'))
      error(['Found behavior which is not rhythmic but ''non_rhythmic''' ...
	     ' string did not match']);
    end
  
    trialBehaviors.data{trialBehaviorCols.is_rhythmic}(find(maskThisGroup),1) = is_rhythmic;
    trialBehaviors.data{trialBehaviorCols.body_group}(find(maskThisGroup),1) = repmat({body_group},sum(maskThisGroup),1);
   
  end
  

  if(any(isnan(trialBehaviors.data{trialBehaviorCols.is_rhythmic})))
    error('Did not match all behaviors to ''is_rhythmic'' property');
  end
end

%%%%%% WRITE TO TEXT FILE %%%%%%

if(params.outputResultToFile)
  outFileParams.fname = fullfile(params.behaveTable_path,params.outputTextFile);
  outFileParams.write2file = 1;

  outFileData.vars = {'column_labels','column_formats','data'};
  ofCols = set_var_col_const(outFileData.vars);

  outFields = trialBehaviorCols;
  outFieldNames = fieldnames(trialBehaviorCols);
  removeFields = intersect({'trial_start_stop','beh_start_stop','coder_time'},outFieldNames);
  outFields = rmfield(outFields,removeFields);
  outFieldIdxs = struct2array(outFields);
  outFileData.data{ofCols.column_labels} = fieldnames(outFields)';
  switch(params.outputFormat)
   case 'one_behavior_per_line'
    outFileData.data{ofCols.column_formats} = {'%d' '%d' '%d' '%s' '%s' '%s' '%s' '%d' '%s' '%d' '%.4f' '%.4f'};
   case  'body_group_by_coder'
    outFileData.data{ofCols.column_formats} = {'%d' '%d' '%d' '%s' ' %s' ' %s' '%.2f' '%.2f' '%.2f' '%.2f' '%.2f' ...
		    '%.2f' '%.2f' '%.2f' ' %.2f' ' %.2f' ' %d' };
  end
  
  outFileData.data{ofCols.data} = trialBehaviors.data(outFieldIdxs);
  ensemble_display_table(outFileData,outFileParams);
end


results = trialBehaviors;


