% quick script for testing the max amplitude levels of three loudness stim categories
% S.T. May, 2010

ensemble_globals;

conn_id = 7;

highNormAtt = '';
midNormAtt = '';
lowNormAtt = '';


mysql_make_conn('atonal.ucdavis.edu','ensemble_main',conn_id);

sql_get_high_locs = ['select location from stimulus left join' ...
		    ' stimulus_x_attribute using (stimulus_id) left join' ...
		    ' attribute using (attribute_id) where attribute.name like' ...
		    '''%normalizedHigh'''];

sql_get_mid_locs = ['select location from stimulus left join' ...
		    ' stimulus_x_attribute using (stimulus_id) left join' ...
		    ' attribute using (attribute_id) where attribute.name like' ...
		    '''%normalizedMid'''];

sql_get_low_locs = ['select location from stimulus left join' ...
		    ' stimulus_x_attribute using (stimulus_id) left join' ...
		    ' attribute using (attribute_id) where attribute.name like' ...
		    '''%normalizedLow'''];

high_locs = mysql(conn_id,sql_get_high_locs);
mid_locs = mysql(conn_id,sql_get_mid_locs);
low_locs = mysql(conn_id,sql_get_low_locs);

clear maxHigh maxMid maxLow



nHigh = length(high_locs);
for iHigh = 1:nHigh
  
  thisLoc = fullfile(stimulus_root,high_locs{iHigh});
  
  sig = wavread(thisLoc);
  
  maxHigh(iHigh) = max(abs(sig(:)));
  
  
end

nMid = length(mid_locs);
for iMid = 1:nMid
  
  thisLoc = fullfile(stimulus_root,mid_locs{iMid});
  
  sig = wavread(thisLoc);
  
  maxMid(iMid) = max(abs(sig(:)));
  
  
end

nLow = length(low_locs);
for iLow = 1:nLow
  
  thisLoc = fullfile(stimulus_root,low_locs{iLow});
  
  sig = wavread(thisLoc);
  
  maxLow(iLow) = max(abs(sig(:)));
  
  
end



highRatio = max(maxHigh) ./ min(maxHigh);
midRatio = max(maxMid) ./ min(maxMid);
lowRatio = max(maxLow) ./ min(maxLow);

highdB = 20*log10(highRatio);
middB = 20*log10(midRatio);
lowdB = 20*log10(lowRatio);
