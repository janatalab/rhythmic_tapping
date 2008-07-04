%creates null entries for event data such as ani, rp, and tapping
%stats. Useful if you have an sess and event struct but no analysis
%data, and just want to have a few empty placeholders for doing a
%tapping_stats analysis for example, which assumes that data
%indices 2 and 3 exist.

%future sess structs shouldn't need to do this since this should be
%initialized during parsing.

for isess = 1:length(sess)

  for ievent = 1:length(sess{isess}.data)

    sess{isess}.data{ievent}.data{1}.data(2:4) = {[]};
    
  end
  
end
