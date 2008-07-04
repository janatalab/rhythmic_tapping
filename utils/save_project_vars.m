%
%
%
% saves all of the existing variables in varnames (stored as a cell
% array of strings to a mat file, specified by filename
%
%
% S.T. 26, Feb, 2007

saveVars = {};

for ivar = 1:length(projectVarsSave)
  
  thisVar = projectVarsSave{ivar};
  
  if(exist(thisVar,'var'))
    saveVars{end+1} = thisVar;
  end
end

save(projectSavePath,saveVars{:});
