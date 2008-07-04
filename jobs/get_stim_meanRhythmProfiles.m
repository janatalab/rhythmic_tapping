function outData = get_stim_meanRhythmProfiles(inData,params)
%
%

ensemble_globals;

  
meanResEnergy = ensemble_init_data_struct;
meanResEnergy.vars = {'stimulus_id' 'artist' 'song_name' 'stimulus_category' 'resonEnergy' ...
		    'meanEnergy' 'stdEnergy' 'resonFreqs' 'peakFreqs'};
mrCols = set_var_col_const(meanResEnergy.vars);

%fill in missing ipem params with defaults
%ipemDefaultParams = ipem_proc_series('getDefaultParams');
%missingAniFields = setdiff(fieldnames(ipemDefaultParams.ani),fieldnames(params.ani));
%missingRpFields  = setdiff(fieldnames(ipemDefaultParams.rp),fieldnames(params.rp));

%for iField = 1:length(missingAniFields)
%  params.ani.(missingAniFields{iField}) = ipemDefaultParams.ani.(missingAniFields{iField});
%end
%for iField = 1:length(missingRpFields)
%  params.rp.(missingRpFields{iField}) = ipemDefaultParams.rp.(missingRpFields{iField});
%end

clear searchCrit;
searchCrit.type = 'stimulus_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimMetaData = inData{findIdx};
stimMetaDataCols = set_var_col_const(stimMetaData.vars);
stimMetaData = ensemble_filter(stimMetaData,params.stims.filt);

clear searchCrit;
searchCrit.type = 'stimulus_x_attribute_metadata';
findIdx = ensemble_find_analysis_struct(inData,searchCrit);
stimAttMetaData = inData{findIdx};
stimAttMetaDataCols = set_var_col_const(stimAttMetaData.vars);
stimAttMetaData = ensemble_filter(stimAttMetaData,params.stimAttributes.filt);


nStims = length(stimMetaData.data{stimMetaDataCols.stimulus_id});

for iStim = 1:nStims

  thisStimID = ...
      stimMetaData.data{stimMetaDataCols.stimulus_id}(iStim);

  fprintf('Processing Stim %d, ID %d\n',iStim,thisStimID);
  
  stimAttIdx = find(stimAttMetaData.data{stimAttMetaDataCols.stimulus_id} == thisStimID);
  thisStimCat = stimAttMetaData.data{stimAttMetaDataCols.name}{stimAttIdx};
  
  thisLocation = stimMetaData.data{stimMetaDataCols.location}{iStim};
  [path,fstub,ext] = fileparts(fullfile(stimulus_ipem_analysis_root,thisLocation));
  
  rpPath = fullfile(path,fstub,'rp');
  
  %fprintf('Looking for rp match....');
  %clear matchParams;
  %matchParams.varName = 'rp';
  %matchParams.paramFind.ani = params.ani;
  %matchParams.paramFind.rp  = params.rp;
  %matchParams.ignore = {'ani.aniPath'};  
  %previousCalcFname = check_anal_exist(rpPath,matchParams);
  
  %if(~previousCalcFname)
  %  error(sprintf('Could not find rhythm profile for stim ID %d, path %s',...
  %		  thisStimID,rpPath));
  %  else
  %    fprintf('found match\n');
  %  end
  
  %  rpLoad = load(fullfile(rpPath,previousCalcFname));
  %  rp = rpLoad.rp;
  %  rpCols = set_var_col_const(rp.vars);
 
  ipemProc = ipem_proc_series(thisStimID,params.ipem);
  ipemProcCols = set_var_col_const(ipemProc.vars);
  rp = ipemProc.data{ipemProcCols.rp}{1};
  rpCols = set_var_col_const(rp.vars);

  artist = stimMetaData.data{stimMetaDataCols.artist}{iStim};
  song_name = stimMetaData.data{stimMetaDataCols.name}{iStim};
  
  resonFreqs = rp.data{rpCols.resonatorFreqs};
  resonEnergy = rp.data{rpCols.resonatorEnergy};
  meanEnergy = mean(resonEnergy,2);
  stdEnergy = std(resonEnergy,[],2);
  peakIdxs = find_peaks(meanEnergy,params.peakFinder);
  peakFreqs = resonFreqs(peakIdxs);
  
  meanResEnergy.data{mrCols.stimulus_id}(iStim,1) = thisStimID;
  meanResEnergy.data{mrCols.artist}{iStim,1} = artist;
  meanResEnergy.data{mrCols.song_name}{iStim,1} = song_name;
  meanResEnergy.data{mrCols.stimulus_category}{iStim,1} = thisStimCat;
  meanResEnergy.data{mrCols.resonEnergy}{iStim,1} = resonEnergy;
  meanResEnergy.data{mrCols.meanEnergy}{iStim,1} = meanEnergy';
  meanResEnergy.data{mrCols.stdEnergy}{iStim,1} = stdEnergy';
  meanResEnergy.data{mrCols.resonFreqs}{iStim,1} = resonFreqs;
  meanResEnergy.data{mrCols.peakFreqs}{iStim,1} = peakFreqs;

end

outData = meanResEnergy;

return





