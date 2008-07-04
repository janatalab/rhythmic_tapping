
sess2fix = setdiff(1:length(sess),[1 3 7 8 11 12]);

for isess = sess2fix
  
  numEvents = length(sess{isess}.data);

  if(~strcmp(sess{isess}.data{numEvents}.data{1}.type,'stim'))
    disp(sprintf('Updating resps for session %d',isess));
    numStims = numEvents/2;

  
    for ievent = 1:length(sess{isess}.data)
      
      eventData = sess{isess}.data{ievent}.data{1};
      if(strcmp(eventData.type,'resp'))
	eventData.stim_id = sess{isess}.data{ievent-numStims}.data{1}.stim_id;
	sess{isess}.data{ievent}.data{1} = eventData;
      end %if
    end %for
  
  end %if
end %for
