% analyze_sas_matrix.m
%
% Loads and examines data matrix that is fed to SAS analyses

% 09/23/2010 - PJ - yields same mean result as lsmeans

datapath ='/data2/rhythm/rhythmic_tapping_v2/project_data/';
fstub = 'behaveCoding_matlabParsed_17Aug2009.txt';

LOAD_DATA = 0;

exclude_coders = 3;
analyze_conds = {'no_tap'};
vars2analyze = {'foot'};
exclude_stimcats = {'silence'};

if LOAD_DATA
  fname = fullfile(datapath,fstub);
  fprintf('Loading %s\n', fname);
  
  colnames = loadtxt(fname,'nlines',1);
  data = loadtxt(fname,'skipline',1);
  
  col = set_var_col_const(colnames);
end

coder_mask = ~ismember(cell2mat(data(:,col.coder_id)),exclude_coders);
cond_mask = ismember(data(:,col.tapping_condition), analyze_conds);

stimcats = unique(data(:,col.stimulus_category));
stimcats = setdiff(stimcats,exclude_stimcats);

for ivar = 1:length(vars2analyze)
  currvar = vars2analyze{ivar};
  fprintf('\nMeans for %s\n', currvar);
  
  for icat = 1:length(stimcats)
    catmask = ismember(data(:,col.stimulus_category), stimcats{icat});
    
    fprintf('%s: %2.1f\n', stimcats{icat}, ...
      mean(cell2mat(data(coder_mask&cond_mask&catmask, col.(currvar))))*100std(cell2mat(data(coder_mask&cond_mask&catmask, col.(currvar))))*100);
    
  end % for icat=
end % for ivar=