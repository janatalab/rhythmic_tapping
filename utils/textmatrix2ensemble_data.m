%function outData = textmatrix2ensemble_data(inData,params)
%
% general purpose data file parser
% Assumes that the general format is a number of header rows,
% followed by the data (double format) in the following rows.
% Each header row should contain a different data type.
% Returns an ensemble data struct with variables corresponding to
% each header, and an additional variable called 'data' that
% contains the data in matrix format.
% 
% PARAMS:
% params.headerRows -    a cell array of header labels. Each header
%                        row should be given a label, since the number of headers will be
%                        calculated from this.
%
% params.headerFormats - a cell array of string formats
%                        corresponding to the headerRows
%
%
% Copyright (c) 2009 The Regents of the University of California
% All Rights Reserved
% Author(s):
% Stefan Tomic 7/16/2009
%

params.headerRows = {'tape_name','fps','column_labels'};
params.headerFormats = {'%s','FPS: %f','%s'};

fname = '12yhm84241_tape1a.mp4.txt';
fpath = '/data2/rhythm/rhythmic_tapping_v2/BERT/patch_data';

fullfpath = fullfile(fpath,fname);

fid = fopen(fullfpath,'r');

headerRows = params.headerRows;
headerFormats = params.headerFormats;
nHeaderRows = length(headerRows);

outData = ensemble_init_data_struct;
outData.vars = {headerRows{:} 'data'};
outDataCols = set_var_col_const(outData.vars);

for iHeadRow = 1:nHeaderRows
    lineContents = fgetl(fid);
    parsedHeader = sscanf(lineContents,headerFormats{iHeadRow});
    outData.data{outDataCols.(headerRows{iHeadRow})} = parsedHeader;
end

parsedData = dlmread(fullfpath,',',nHeaderRows,0);
outData.data{outDataCols.data} = parsedData;

fclose(fid);
