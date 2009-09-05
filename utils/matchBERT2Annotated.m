function outData = matchBERT2Annotated(inData,params)
% matches trial times in annotated behavioral coding with BERT patch videos
%
% 
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved.
%
% Author: Stefan Tomic 08/21/09

TEST_SYNC = 0; %whether or not to display figures and write wav files for sanity-checking 
TEST_PARSE = 1; % whether or not to test the trial start/stop time parsing

annot = inData;
annotCols = set_var_col_const(annot.vars);


% Hardcoding columns. 
% If this becomes a useful function, may want to make this
% automatic from header labels
bertVars = {'Name','Annot_Name','Duration','Media_Start','Media_End','Vid_Rate'};
bertCols = set_var_col_const(bertVars);
colMask = ismember(bertVars,{'Duration','Media_Start','Media_End'});
convertCols = find(colMask);


bertPath = params.bertPath;
bertLogFullPath = fullfile(bertPath,params.bertLogFile);
bertWavPath = fullfile(bertPath,params.bertWavDir);
annotWavPath = fullfile(bertPath,params.annotWavDir);

annotatedCoding = inData;
annotCols = set_var_col_const(inData.vars);

annot_startStop = annotatedCoding.data{annotCols.trial_start_stop};

%there is probably a cleaner way to read the log in so that it
%doesn't have to be reshaped, but doing this now to save time
bertLog = textread(bertLogFullPath,'%s','headerlines',1,'delimiter',',');
logLen = length(bertLog);
nCols = 6;
nRows = logLen/nCols;
bertLog = reshape(bertLog,nCols,nRows)';

%convert SMTPE time columns to seconds
for iRow = 1:nRows
  fpsString = bertLog{iRow,bertCols.Vid_Rate};
  fps = sscanf(fpsString,'%f fps');
  for iCol = convertCols
    smpteTime = bertLog{iRow,iCol};
    timeSecs = smpteTime2sec(smpteTime,fps);
    bertLog{iRow,iCol} = timeSecs;
  end
end

%read in the first nSyncSecs seconds of audio from each tape
nSamps = params.nSyncSecs * params.Fs;

bertDirInfo = dir(fullfile(bertWavPath,'*.wav'));
bertTapeFnames = {bertDirInfo.name};

nFiles = length(bertTapeFnames);
for iFile = 1:nFiles

  bertWavFile = bertTapeFnames{iFile};
  [dummy,bertFstub] = fileparts(bertWavFile);
  
  fprintf('Processing %s...\n',bertWavFile);
  
  bertTapeFullPath = fullfile(bertWavPath,bertWavFile);
  
  %bertTapeFstub = bertLog{iRow,bertCols.Name};
  %bertTapeFullPath = fullfile(bertWavPath,[bertTapeFstub '.wav']);
  rowNum = find(strcmp(bertFstub,bertLog(:,1)));
  
  bertStart = bertLog{rowNum,bertCols.Media_Start};
  bertDur = bertLog{rowNum,bertCols.Duration};
  
  annotTapeFname = bertLog{rowNum,bertCols.Annot_Name};
  [dummy,annotTapeFstub] = fileparts(annotTapeFname);
  annotTapeFullPath = fullfile(annotWavPath,annotTapeFname);
  
  bertSig = wavread(bertTapeFullPath,nSamps);
  
  %convert to mono
  bertSig = mean(bertSig,2);
  sigLen = size(bertSig,1);
  
  noldusStart = round(bertStart * params.Fs);
  noldusStop = noldusStart + sigLen - 1;
  
  %read in Noldus video
  annotSig = wavread(annotTapeFullPath,[noldusStart noldusStop]);
  annotSig = mean(annotSig,2);
  
  %normalize both signals
  bertSig = bertSig ./ max(abs(bertSig)) .* 0.96;
  annotSig = annotSig ./ max(abs(annotSig)) .* 0.96;
  
  %run xcorr between Noldus and bert video to find lag
  [xc,lags] = xcorr(bertSig,annotSig,'coeff');
  maxCorr = max(xc);
  if(maxCorr < params.xcorrThresh)
    warning(sprintf('BERT tape %s could not be synced with Noldus video',bertFstub));
    continue;
  end
  offsetIdx = find(xc == maxCorr);
  lagVal = lags(offsetIdx);
  
  % offset of noldus from bert
  % This offset is added to bert time to get noldus time
  % (i.e. a positive offset means bert signal is earlier than noldus signal)
  noldusOffsetSec = bertStart - lagVal./params.Fs;

  if(TEST_SYNC)
    %read in the wav files again with the offset value and write to
    %new wav files for sanity check
    testStartOffsetSec = 1*60;
    if(noldusOffsetSec > 0)
      noldusTestStart = round((noldusOffsetSec+testStartOffsetSec).*params.Fs);
      bertTestStart = testStartOffsetSec * params.Fs + 1;
    else
      noldusTestStart =testStartOffsetSec * params.Fs + 1;
      bertTestStart = -1 * round((noldusOffsetSec+testStartOffsetSec).*params.Fs);
    end
    testSec = 60;
    testLen = testSec * params.Fs;
    noldusTestStop = noldusTestStart + testLen - 1;
    bertTestStop = bertTestStart + testLen - 1;
  
    testAnnot = wavread(annotTapeFullPath,[noldusTestStart noldusTestStop]);
    testBert = wavread(bertTapeFullPath,[bertTestStart bertTestStop]);

    figure(1);subplot(2,1,1);plot(mean(testAnnot,2));
    subplot(2,1,2);plot(mean(testBert,2));
    %wavwrite(testAnnot,44100,16,fullfile(bertPath,sprintf('test_annot_%s',bertFstub)));
    %wavwrite(testBert,44100,16,fullfile(bertPath,sprintf('test_bert_%s',bertFstub)));
  
  end %if(TEST_SYNC)
  
  thisSubjectID = strtok(bertFstub,'_');
  
  %kludging typo fix here. This would be better done in the
  %original CSV file by adding a subject ID column
  [doSub,subIdx] = ismember(thisSubjectID,params.substituteSubID(:,1));
  if(doSub)
    thisSubjectID = params.substituteSubID{subIdx,2};
  end
  
  subRows = find(strcmp(annot.data{annotCols.subject_id},thisSubjectID));

  %obtain unique trial information from the annot struct by finding
  %unique trialOrders
  trialOrders = annot.data{annotCols.trial_order}(subRows);
  [trialOrders,uniqueIdxs] = unique(trialOrders);
  trialIDs = annot.data{annotCols.trial_id}(subRows(uniqueIdxs));
 
  stimIDs = annot.data{annotCols.stimulus_id}(subRows(uniqueIdxs));
  dp_trial_start_stop = annot.data{annotCols.trial_start_stop}(subRows(uniqueIdxs),:);

  %obtaining offset of noldus (annot) recording from dp, since the
  %annot struct records trial starts and stops in dp time. This
  %needs to be converted to Noldus video time, which in turn is
  %converted to the mpeg4 (BERT) time
  dpOffsetSec = annot.data{annotCols.offset_from_dp}(subRows(uniqueIdxs));
  annotTapeStubs = annot.data{annotCols.tape_label}(subRows(uniqueIdxs));
  
  
  bert_trial_start_stop = (dp_trial_start_stop - repmat(dpOffsetSec,1,2)) - noldusOffsetSec;
  trialStarts = bert_trial_start_stop(:,1);
  trialStops = bert_trial_start_stop(:,2);
 
  %note that this will throw away trials that were cut off mid way
  %in the video clip. We may not want to use these trials in the
  %analysis anyway
  useTrials = find(trialStops <= bertDur & trialStarts >= 0 & ...
		   strcmp(annotTapeFstub,annotTapeStubs));
  outFilePath = fullfile(params.outPath,[bertFstub '.txt']);
 
  if(TEST_PARSE)
    
    noldusStartStop = (dp_trial_start_stop - repmat(dpOffsetSec,1,2));
    
    %wavwrite the first three trials to see if they were parsed correctly
    for iTrial = 1:min(5,length(useTrials))
      fname = sprintf('testBert_%s_trial_%d.wav',bertFstub,iTrial);
      testParseStart = round(trialStarts(useTrials(iTrial)) * params.Fs);
      testParseStop = round(trialStops(useTrials(iTrial)) * params.Fs);
      testSig = wavread(bertTapeFullPath,[testParseStart testParseStop]);
      wavwrite(testSig,44100,16,fullfile(bertPath,fname));   
    
      nfname = sprintf('testNoldus_%s_trial_%d.wav',bertFstub,iTrial);
      noldusStart = round(noldusStartStop(useTrials(iTrial),1) * params.Fs);
      noldusStop = round(noldusStartStop(useTrials(iTrial),2) * params.Fs);
      tstNoldusSig = wavread(annotTapeFullPath,[noldusStart noldusStop]);
      wavwrite(tstNoldusSig,44100,16,fullfile(bertPath,nfname));
    end
    
  end
  
  outFid = fopen(outFilePath,'w');
  fprintf(outFid,'trial_id,stimulus_id,trial_start,trial_stop\n');
  nOutRow = length(useTrials);
  for iRow = 1:nOutRow
    rowIdx = useTrials(iRow);
    fprintf(outFid,'%d,%d,%.3f,%.3f\n',trialIDs(rowIdx),stimIDs(rowIdx),trialStarts(rowIdx),trialStops(rowIdx));
  end
 
end
  
outData = [];
