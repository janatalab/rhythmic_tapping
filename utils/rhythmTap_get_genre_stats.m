% script rhythmTap_get_genre_stats
%
% reports basic stats of stimulus genres used in rhythmic tapping

globals = rhythmTap_globals; 

dbstop if error

load (fullfile(globals.paths.datapath,...
	       'rhythmTap_response_rprofile_analysis_21May2008_11:21.mat'));

genres = an{1}.results.data{5}.data{7};

%remove blank genres. This should only be the "beep" stimulus for silence trials
genres(strmatch('',genres,'exact')) = [];

uniqueGenres = unique(genres);

nGenres = length(uniqueGenres);
for iGenre = 1:nGenres
  
  thisGenre = uniqueGenres{iGenre};
  
  genreCount(iGenre) = length(strmatch(thisGenre,genres,'exact'));
  
  
end

for iGenre = 1:nGenres
  
  thisGenre = uniqueGenres{iGenre};
  thisGenrePercent = genreCount(iGenre) ./ sum(genreCount) .* 100;
  
  fprintf('%20s: %4d %5.1f\n',thisGenre,genreCount(iGenre),thisGenrePercent);
  
end