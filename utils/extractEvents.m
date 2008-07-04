function extractEvents = extractEvents(data)
%
%
% function to return session events of a specific type to a single event
% cell array

eventArray = {};

if(strcmp(data{1}.type,'event'))
  sess.data = data;
elseif(strcmp(data{1}.type,'session'))
  sess = data;
end


for isess = 1:length(sess)
  
  for ievent = 1:length(sess{isess}.data)
    
    if(isfield(params,'eventType'))
      if(strcmp(sess{isess}.data{ievent}.data{1}.type,params.eventType))
      
      eventArray{end+1} = sess{isess}.data{ievent};
      end
    else
      %if eventType is not set, simply return all events in a
      %single cell array
      eventArray{end+1} = sess{isess}.data{ievent};
    end
    
  end
end
