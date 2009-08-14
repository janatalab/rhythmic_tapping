function results = checkBehaveCoding(trialBehaviors,params)
% results = checkBehaveCoding(data_st,params);
%
% Examines the data structure returned by behaviorCodingAnalysis to look at
% consistency of ratings across coders.

% August 13, 2009 Petr Janata

data = trialBehaviors.data;
cols = set_var_col_const(trialBehaviors.vars);

% Determine the number of coders
coder_ids = unique(data{cols.coder_id});
num_coders = length(coder_ids);

% Determine the number of behaviors
behaviors = unique(data{cols.behavior});
num_behaviors = length(behaviors);

fprintf('Identified %d coders, and %d behaviors\n', num_coders, num_behaviors);

% Loop over each behavior and determine which coders it was rated by
fprintf('%50s\tCoders\n','Behavior');

num_coders_per_behave = zeros(num_behaviors,1);
for iBehave = 1:num_behaviors
  behavior_mask = ismember(data{cols.behavior}, behaviors{iBehave});
  
  curr_coders = unique(data{cols.coder_id}(behavior_mask));
  
  fprintf('%50s\t%s\n', behaviors{iBehave}, sprintf('%d ', curr_coders));
  
  num_coders_per_behave(iBehave) = length(curr_coders);
  
end % for iBehave

% Tally the number of behaviors with X coders each
codedBehaveHist = hist(num_coders_per_behave,1:num_coders);
fprintf('#Coders\t#Behaviors\n')
for icoder = 1:num_coders
  fprintf('%d\t%d\n', icoder, codedBehaveHist(icoder));
end


results = [];