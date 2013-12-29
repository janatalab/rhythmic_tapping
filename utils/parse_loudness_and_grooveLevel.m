function inData = parse_loudness_and_grooveLevel(inData,params)
%
% parses the attribute names of stims used in rhythmic_tapping_normalization
% experiment and returns columns for normalization level, and groove level
%
% S.T. 6/10/2010
% 28Dec2013 PJ - added filtering abilities

if isfield(params,'filt')
  inData = ensemble_filter(inData,params.filt);
end

inData.vars = {inData.vars{:} 'groove_level' 'norm_level'};
inData.data = {inData.data{:} {} {} };
inDataCols = set_var_col_const(inData.vars);

uniqueAttributes = unique(inData.data{inDataCols.name});
nAttributes = length(uniqueAttributes);


for iAttribute = 1:nAttributes
  
  thisAtt = uniqueAttributes{iAttribute};
  
  attStrings = regexp(thisAtt,'real_music_(\w+_\w+)_(normalized\w+)','tokens');
  
  grooveStr = attStrings{1}{1};
  normLevelStr = attStrings{1}{2};
  
  stimIdxsThisAtt = find(strcmp(inData.data{inDataCols.name},thisAtt));
  nStimsThisAtt = length(stimIdxsThisAtt);
  
  inData.data{inDataCols.groove_level}(stimIdxsThisAtt,1) = repmat({grooveStr},nStimsThisAtt,1);
  inData.data{inDataCols.norm_level}(stimIdxsThisAtt,1) = repmat({normLevelStr},nStimsThisAtt,1);
  
end

outData = [];
