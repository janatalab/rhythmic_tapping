% load_bert_data
% subids = {'01cgc83291_tape1a' '01cgc83291_tape2a' '01jlj86061_tape1a' ...
%     '01jlj86061_tape2a' '01jlj86061_tape2b' '01lot87121_tape1a'};
 subids = {'01cgc83291_tape1a' '01cgc83291_tape2a' '01jlj86061_tape1a' ...
    '01jlj86061_tape2a' '01jlj86061_tape2b' '_01lot87121_tape1a'...
    '_01lot87121_tape1b' '_01lot87121_tape1c' '_01lot87121_tape2a'...
    '_07vyk86161_tape1a' '_07vyk86161_tape2a' '_07vyk86161_tape2b'...
    '_08ana84041_tape1a' '_08ana84041_tape2a' '_08ana84041_tape2b'...
    '_08ana84041_tape2c' '_12hne87101_tape1a' '_12hne87101_tape2a'...
    '_12hne87101_tape2b' '_12hne87101_tape2c'};
seconds_subids = {'01cgc83291_tape1a' '01cgc83291_tape2a' '01jlj86061_tape1a' ...
    '01jlj86061_tape2a' '01jlj86061_tape2b'};
addpath('../analyses')
addpath('../../rhythm_profiler/params')
globals = rhythmTap_globals;
for isub = 1:length(subids)
    fpath = fullfile(globals.paths.datapath,'bert');
    if strmatch(subids{isub},seconds_subids)
        fname = sprintf('%s.mp4.txt',subids{isub});
    else
        fname = sprintf('%s.mp4_.txt',subids{isub});
    end
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
    point_vars = setdiff(vars,'Qtunits');

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
      fprintf('Time not monotonically increasing\n')
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
    
    
    % Remove the means from the data
    col_medians = median(data);
    if strmatch(subids{isub},seconds_subids)
            tscale = data(:,1)/qtps;
    else
        tscale = data(:,1);
    end
    data = data-repmat(col_medians,size(data,1),1);
        
    
    %% Plot the data
    npts = length(point_vars)/2;
    figure
    ylim = [-5 70];
    set(gcf,'defaultaxesylim', ylim)
    
    r = zeros(size(data,1), npts);
    ipt= 0;
    
    ipt = ipt+1;
    [th,r(:,ipt)] = cart2pol(data(:,cols.Nose_X),data(:,cols.Nose_Y));
    subplot(6,1,ipt)
    plot(tscale,r(:,ipt))
    title(subids(isub))
    hold on
    
    ipt = ipt+1;
    [th,r(:,ipt)] = cart2pol(data(:,cols.L_Eye_X),data(:,cols.L_Eye_Y));
    subplot(6,1,ipt)
    plot(tscale,r(:,ipt))
    hold on
    
    ipt = ipt+1;
    [th,r(:,ipt)] = cart2pol(data(:,cols.R_Eye_X),data(:,cols.R_Eye_Y));
    subplot(6,1,ipt)
    plot(tscale,r(:,ipt))
    hold on
    
    ipt = ipt+1;
    [th,r(:,ipt)] = cart2pol(data(:,cols.Chin_X),data(:,cols.Chin_Y));
    subplot(6,1,ipt)
    plot(tscale,r(:,ipt))
    hold on
    
    ipt = ipt+1;
    [th,r(:,ipt)] = cart2pol(data(:,cols.L_Lip_X),data(:,cols.L_Lip_Y));
    subplot(6,1,ipt)
    plot(tscale,r(:,ipt))
    hold on
    
    ipt = ipt+1;
    [th,r(:,ipt)] = cart2pol(data(:,cols.R_Lip_X),data(:,cols.R_Lip_Y));
    subplot(6,1,ipt)
    plot(tscale,r(:,ipt))
    
    set(gcf,'position',[100 100 800 1000],'paperposition',[.25 .5 8 10]);
    %% Plot resets
    fpath = fullfile(globals.paths.datapath,'bert');
    fname = sprintf('%s.mp4_reset_log.txt',subids{isub});
    resets = loadtxt(fullfile(fpath,fname)...
        ,'delim',[','],'skipline',2);
    for iplot = 1:6
        subplot(6,1,iplot)
            hold on       
            for ireset = 1:length(resets)
            
            line([1 1]*resets{ireset},[0 50],'color','r')
        end
    end
end



