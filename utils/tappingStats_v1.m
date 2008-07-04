function trialInfo = tappingStats(trialInfo,params)
%
% Calculates various tapping stats for an nmat obtained from
% tapping midi data
%
%
%
% 15 Dec, 2006 first version, S.T.

trialInfo.vars{end+1} = 'ioi_stats';
trialInfoCols = set_var_col_const(trialInfo);

nmat = trialInfo.data{trialInfoCols};

%need to mask out any notes that weren't on the bottom left or
%bottom right of the midi drum pad.
bothHandsMidiMask = ( (nmat(:,4) == params.leftHandMidiNote) | ...
    (nmat(:,4) == params.rightHandMidiNote) );
nmat = nmat(bothHandsMidiMask,:);


leftHand_nmat = nmat(find(nmat(:,4) == params.leftHandMidiNote),:);
rightHand_nmat = nmat(find(nmat(:,4) == params.rightHandMidiNote),:);


%IOIScaleFactor allows for normalizing iois by peak IOI or by
%stimulus tempo (see plot_summaryIOIHistByTrialType)
if(~isfield(params,'IOIScaleFactor') | isempty(params.IOIScaleFactor))
  params.IOIScaleFactor = 1;
end

if(~isfield(params,'left_IOIScaleFactor') | isempty(params.left_IOIScaleFactor))
  params.left_IOIScaleFactor = 1;
end

if(~isfield(params,'right_IOIScaleFactor') | isempty(params.right_IOIScaleFactor))
  params.right_IOIScaleFactor = 1;
end

ts.ioi = diff(nmat(:,6),1,1);
ts.ioi(find(ts.ioi < params.ioiMinThresh)) = [];


ts.ioi = ts.ioi./params.IOIScaleFactor;

ts.leftHand_ioi =  diff(leftHand_nmat(:,6),1,1);
ts.rightHand_ioi = diff(rightHand_nmat(:,6),1,1);

ts.leftHand_ioi(find(ts.leftHand_ioi < params.ioiMinThresh)) = [];
ts.rightHand_ioi(find(ts.rightHand_ioi < params.ioiMinThresh)) = [];
ts.leftHand_ioi = ts.leftHand_ioi./params.left_IOIScaleFactor;
ts.rightHand_ioi = ts.rightHand_ioi./params.right_IOIScaleFactor;

ts.ioiHistBinSize = params.ioiHistBinSize;

distributionVector = [params.ioiHistBinLim(1):params.ioiHistBinSize:params.ioiHistBinLim(2)];
ts.ioiHistBinCenters = distributionVector;

if(~isempty(ts.ioi))
  ts.ioiHist = hist(ts.ioi,distributionVector);
else
  ts.ioiHist = 0;
end

if(~isempty(ts.leftHand_ioi))
  ts.leftHand_ioiHist = hist(ts.leftHand_ioi,distributionVector);
else
  ts.leftHand_ioiHist = 0;
end

if(~isempty(ts.rightHand_ioi))
  ts.rightHand_ioiHist = hist(ts.rightHand_ioi,distributionVector);
else
  ts.rightHand_ioiHist = 0;
end
  
ts = ensemble_tree2datastruct(ts);

trialInfo.data{trialInfoCols.ioi_stats} = ts;




return
