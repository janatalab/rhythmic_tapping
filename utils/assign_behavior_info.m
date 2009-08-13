function behavior_info = assign_behavior_info(behave_group_tag)
% behavior_info = assign_behavior_info(behave_group_tag);
%
% 

globals = rhythmTap_globals;

behavior_info = {};

switch behave_group_tag
  case 'indiv'
   behavior_info = repmat(globals.behaviors.indiv',1,2);
  case 'rhythmic_vs_non_rhythmic'
   behavior_info{1,1} = 'rhythmic';
   behavior_info{1,2} = globals.behaviors.rhythmic.all;
   behavior_info{2,1} = 'non_rhythmic';
   behavior_info{2,2} = globals.behaviors.non_rhythmic.all;
  case 'body_group'
   subsets = {'rhythmic','non_rhythmic'};
   %subsets = {'rhythmic'};
   ng = 0;
   for iset = 1:length(subsets)
     setstr = subsets{iset};
     body_groups = ...
	 setdiff(fieldnames(globals.behaviors.(setstr)),'all');
     for ibody_group = 1:length(body_groups)
       ng = ng+1;
       body_group = body_groups{ibody_group};
       behavior_info{ng,1} = sprintf('%s,%s', setstr,body_group);
       behavior_info{ng,2} = globals.behaviors.(setstr).(body_group);
     end
   end
 case 'misc'
  behavior_info = repmat(globals.behaviors.misc',1,2);
 otherwise
  fprintf('Undefined behavior grouping option: %s\n', behave_group_tag);
end % switch behave_group_tag
