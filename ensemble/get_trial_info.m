function [trial_info,order_trial_info] = get_trial_info(trial_id,attributes)
%
% retrieve trial info for the trial_ids corresponding to the trial_id input
% vector and the given attributes (as a cell array of strings). The attributes
% argument is necessary since the stims for the given trials can belong to more
% than one attribute. Also includes trials whos stims have no attribute
% (attribute.name == null)
%


MYSQL_CONN_ID = 7;
  

attributes_comma_delim = sprintf('''%s'',',attributes{:});
attributes_comma_delim = attributes_comma_delim(1:end-1);

trials_comma_delim = sprintf('%d,',trial_id);
trials_comma_delim = trials_comma_delim(1:end-1);
      
sql_get_trial_info = ['SELECT trial_id,stimulus_id1,question_id,attribute.name from trial left join stimulus_x_attribute' ...
                      ' on (trial.stimulus_id1 = stimulus_x_attribute.stimulus_id) left join attribute using (attribute_id)' ...
		      sprintf(' where (attribute.name in (%s) or attribute.name is null) and trial_id in (%s)',attributes_comma_delim,trials_comma_delim)];
[trial_info{1:4}] = mysql(MYSQL_CONN_ID,sql_get_trial_info);

[tf,order_trial_info] = ismember(trial_id,trial_info{1});


trial_info{1} = trial_info{1}(order_trial_info);
trial_info{2} = trial_info{2}(order_trial_info);
trial_info{3} = trial_info{3}(order_trial_info);
trial_info{4} = trial_info{4}(order_trial_info);


music_mask = trial_info{2} ~= 6497;



if(length(unique(trial_info{2}(music_mask))) == length(trial_info{2}(music_mask)))
  disp('stimuli are unique');
else
  disp('stimuli are NOT unique');
end

if(isempty(find(trial_info{3}(1:end-1) == trial_info{3}(2:end))))
  disp('trial types are non-consecutive');
else
  disp('trial types ARE consecutive');
end

