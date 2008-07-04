%deletes all responses from sess struct

for isess = 1:length(sess)
  delete_idxs = [];
  for ievent = 1:length(sess{isess}.data)
  
    if (strcmp(sess{isess}.data{ievent}.data{1}.type,'resp'))
      delete_idxs = [delete_idxs ievent];
    end

    
  end
  delete_idxs
  sess{isess}.data(delete_idxs) = [];
  
end
