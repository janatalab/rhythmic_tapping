% load_bert_data

addpath('../analyses')
globals = rhythmTap_globals;

fpath = fullfile(globals.paths.datapath,'bert');
fname = '12yhm84142_tape1a_test2.mp4.txt';

fid = fopen(fullfile(fpath,fname),'rt');

srcfile = fgetl(fid);
l = fgetl(fid);
[str,fps] = strread(l,'%s%f','delimiter',' ');

l = fgetl(fid);
[str,qtps] = strread(l,'%s%f','delimiter',' ');

vars = fgetl(fid);
vars = strread(vars,'%s','delimiter',',');
vars = strrep(vars,' ', '_');
cols = set_var_col_const(vars);

fclose(fid);

%data = loadtxt(fullfile(fpath,fname),'skipline',4);

fid = fopen(fullfile(fpath,fname),'rt');

tic
[data] = textscan(fid,repmat('%f',1,13), 'delimiter', ',', 'headerLines', 4);
toc

% Pack all of the data into a matrix
data = cell2mat(data);

fclose(fid);

%% Perform some sanity checks
fprintf('Running sanity checks\n')

% Make sure that time is monotonically increasing
dt = diff(data(:,cols.Qtunits));
if ~all(dt > 0)
  fprintf('Time not monotonically decreasing\n')
  if any(dt<0)
    error('Time running backward!\n')
  end
  if any(dt == 0)
    dt0_idxs = find(dt==0);
    fprintf('Time stood still for %d observations\n', length(dt0_idxs));
    
    % Eliminating duplicates
    fprintf('Eliminating duplicates\n');
    data(dt0_idxs,:) = [];
    
    % Eliminating any time=0
    fprintf('Eliminating time=0\n');
    data(data(:,1) == 0,:) = [];
  end
end



%% Plot the data
[th,r] = cart2pol(data(:,cols.Nose_X)-mean(data(:,cols.Nose_X)),data(:,cols.Nose_Y)-mean(data(:,cols.Nose_Y)));
tscale = data(:,1)/qtps;

plot(tscale,r)