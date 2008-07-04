function params = checkFileExistence(params)
%
% params = checkFileExistence(params)
%
% where params is any parameter structure with
% 'file' and 'pathname' fields
%
% accepts any param struct with 'path' and 'filename' fields
% checks to see if the file exists. If the file doesn't exist,
% will prompt user to either enter a new path and filename or 
% just hit 'enter' once the path and filename have been corrected
% in the filesystem.

while(exist(fullfile(params.path,params.filename)) ~= 2)
  disp([sprintf('File: %s does not',fullfile(params.path,params.filename)) ...
	'exist.\nPlease rename the file accordingly' ...
	' or enter a new location for the file.\n']);
  disp(['Just hit <Enter> or <Return> to use' ...
	' the filename above if you renamed the file in the filesystem:']);
  newLocation = input('Location of file: ');
  
  if(~isempty(newLocation))
    [newPath,newFname,newExt] = fileparts(newLocation);
    params.path = newPath;
    params.filename = [newFname newExt];
  end
  
end
