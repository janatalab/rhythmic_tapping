% script for testing rhythmic_tapping_normalized_select (stim selection function) 
% S.T. May, 2010

stimMapFile = '/nfs/stim_scripts/rhythmic_tapping_loudness_map.mat';
 stimMapLoad = load(stimMapFile);
 grooveStimMap = stimMapLoad.grooveStimMap;
 gsmCols = set_var_col_const(grooveStimMap.vars);
 
 clear rhythmic_tapping_normalized_select;
 clear grooveLevels;
 clear loudness;
 
 retVal = [];
 iStim = 1;
 
 
 while(~strcmp(retVal,'end'))
   
   
   retVal = rhythmic_tapping_normalized_select;
   
   if(strcmp(retVal,'end'))
     break;
   end
   
   newID(iStim) = str2num(retVal);
   
   
   if(ismember(newID(iStim),grooveStimMap.data{gsmCols.highNorm_stimID}))
     loudness(iStim) = 3;
     rowIdx = find(grooveStimMap.data{gsmCols.highNorm_stimID} == newID(iStim));
     grooveLevels{iStim} = grooveStimMap.data{gsmCols.groove_category}{rowIdx};
     origID(iStim) = grooveStimMap.data{gsmCols.orig_stimID}(rowIdx);
   elseif(ismember(newID(iStim),grooveStimMap.data{gsmCols.midNorm_stimID}))
     loudness(iStim) = 2;
     rowIdx = find(grooveStimMap.data{gsmCols.midNorm_stimID} == newID(iStim));
     grooveLevels{iStim} = grooveStimMap.data{gsmCols.groove_category}{rowIdx};
     origID(iStim) = grooveStimMap.data{gsmCols.orig_stimID}(rowIdx);
   elseif(ismember(newID(iStim),grooveStimMap.data{gsmCols.lowNorm_stimID}))
     loudness(iStim) = 1;
     rowIdx = find(grooveStimMap.data{gsmCols.lowNorm_stimID} == newID(iStim));
     grooveLevels{iStim} = grooveStimMap.data{gsmCols.groove_category}{rowIdx};
     origID(iStim) = grooveStimMap.data{gsmCols.orig_stimID}(rowIdx);
   end
   
   iStim = iStim + 1;
   
   
 end
 
 
 
 lowGrooveLowLevel = find(strcmp('real_music_low_groove',grooveLevels) & loudness  == 1);
 lowGrooveMidLevel = find(strcmp('real_music_low_groove',grooveLevels) & loudness  == 2);
lowGrooveHighLevel = find(strcmp('real_music_low_groove',grooveLevels) & loudness  == 3);

midGrooveLowLevel = find(strcmp('real_music_mid_groove',grooveLevels) & loudness  == 1);
midGrooveMidLevel = find(strcmp('real_music_mid_groove',grooveLevels) & loudness  == 2);
midGrooveHighLevel = find(strcmp('real_music_mid_groove',grooveLevels) & loudness  == 3);

highGrooveLowLevel = find(strcmp('real_music_high_groove',grooveLevels) & loudness  == 1);
highGrooveMidLevel = find(strcmp('real_music_high_groove',grooveLevels) & loudness  == 2);
highGrooveHighLevel = find(strcmp('real_music_high_groove',grooveLevels) & ...
			   loudness  == 3);


fprintf('Low Groove - lowLevel: %d, midLevel: %d, highLevel: %d\n\n', ...
	length(lowGrooveLowLevel),length(lowGrooveMidLevel),length(lowGrooveHighLevel));
fprintf('Mid Groove - lowLevel: %d, midLevel: %d, highLevel: %d\n\n', ...
	length(midGrooveLowLevel),length(midGrooveMidLevel),length(midGrooveHighLevel));
fprintf('High Groove - lowLevel: %d, midLevel: %d, highLevel: %d\n\n',length(highGrooveLowLevel),length(highGrooveMidLevel),length(highGrooveHighLevel));
