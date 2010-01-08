globals = rhythmTap_globals;
close all

LOAD_DATA = 1;
SILENCE_STIM_ID = globals.ensemble.silence_stim_id;
subject_rpProfile_fstub = 'meanEnergies_peakWidths_byTrialSub_14Oct2009.mat';
figtitle = 'Iso ITI Standard Deviation vs. Model Metrics';
plotFname = 'itiVar_vs_modelMetrics_normITI2.ps';

plotPath = '/data2/groove/smpc09/plots';

if LOAD_DATA
  % Load tapping data and responses to post-stim questions
  datafstub = subject_rpProfile_fstub;
  datafname = fullfile(globals.paths.resp_rp_path, datafstub);

  fprintf('Loading data from: %s\n', datafname);
  load(datafname); 
end

meCols = set_var_col_const(meanEnergies.vars);

mask_iso_tap = strcmp('iso_tap',meanEnergies.data{meCols.tapping_cond});

nRecords = length(meanEnergies.data{1});
%obtain mask of those that actually tapped during iso trials
for iRecord = 1:nRecords 
  thisTappingStats = meanEnergies.data{meCols.tapping_stats}{iRecord};
  tsCols = set_var_col_const(thisTappingStats.vars);
  bothStats = thisTappingStats.data{tsCols.both};
  bsCols = set_var_col_const(bothStats.vars);
  bothVarList(iRecord,1) = bothStats.data{bsCols.var_about_peak};
  bothIOI = bothStats.data{bsCols.ioi};
  mask_did_tap(iRecord,1) = ~isempty(bothIOI);
end

mask_silence_stim = meanEnergies.data{meCols.stimulus_id} == ...
    SILENCE_STIM_ID;

mask_use = (mask_iso_tap & mask_did_tap);

iso_var = bothVarList(mask_use);
iso_meanVMTimingDev = meanEnergies.data{meCols.meanVMTimingDev}(mask_use);

nTrials = sum(mask_use);
trialsUse = find(mask_use);
for iTrial = 1:nTrials
  
  trialIdx = trialsUse(iTrial);
  
  tappingStats = meanEnergies.data{meCols.tapping_stats}{trialIdx};
  tsCols = set_var_col_const(tappingStats.vars);
  bothStats = tappingStats.data{tsCols.both};
  bsCols = set_var_col_const(bothStats.vars);
  itiStdDev(iTrial) = bothStats.data{bsCols.var_about_peak};
  
  histBinCenters = bothStats.data{bsCols.hist_bin_centers};
  ioiHist = bothStats.data{bsCols.ioi_hist};
  
  peakITIIdx = find(ioiHist == max(ioiHist));
  
  if((length(peakITIIdx) > 1) && (all(diff(peakITIIdx)) == 1))
    thisPeakITI = mean(histBinCenters(peakITIIdx));
  elseif((length(peakITIIdx) > 1) && ~(all(diff(peakITIIdx)) == 1))
    warning('found more than one non-adjacent peak ITI. Using the smallest one.');
    thisPeakITI = histBinCenters(peakITIIdx(1));
  else
    thisPeakITI = histBinCenters(peakITIIdx);
  end
  
  peakITIs(iTrial) = thisPeakITI;
  
  %getting peak reson from meanEnergy (MPP). We normally should be able
  %to do this from peakFreqs and normPeakFreqs, but this was messed up by midiResp_rhythm_profiler
  thisMPP = meanEnergies.data{meCols.meanEnergy}{trialIdx};
  resonFreqs = meanEnergies.data{meCols.resonFreqs}{trialIdx};
  peakResonIdx = find(thisMPP == max(thisMPP));
  peakFreqs(iTrial) = resonFreqs(peakResonIdx);
  
  meanVMTimingDev(iTrial) = meanEnergies.data{meCols.meanVMTimingDev}(trialIdx);
  
  
  
end


figure;
set(gcf,'paperposition',[0.25 0.5 8.0 10.5],'position',[100 100 800 1050]);
axes('position',[0 0.9 1 0.1],'visible','off');
text(0.5,0.5,'VMTimingDev and ITI Correlations','fontsize',16);


subplot(2,2,1);
plot(peakFreqs,itiStdDev,'o');
axis square;
xlabel('Model Peak Freq (Hz)');
ylabel('ITI Std Dev');
[c,p] = corr(peakFreqs',itiStdDev');
ax_pos = get(gca,'position');
corrLabelAxH = axes('position',[ax_pos(1) ax_pos(2)-0.05 ax_pos(3) .05],'visible','off');
text(0.5,0.5,sprintf('Corr: %.2f pval: %.4f',c,p),'horizontalalignment','center');

subplot(2,2,2);
plot(peakFreqs,meanVMTimingDev,'o');
axis square;
xlabel('Model Peak Freq (Hz)');
ylabel('meanVMTimingDev (Radians)');
[c,p] = corr(peakFreqs',meanVMTimingDev');
ax_pos = get(gca,'position');
corrLabelAxH = axes('position',[ax_pos(1) ax_pos(2)-0.05 ax_pos(3) .05],'visible','off');
text(0.5,0.5,sprintf('Corr: %.2f pval: %.4f',c,p),'horizontalalignment','center');

subplot(2,2,3);
plot(peakFreqs,1./peakITIs,'o');
axis square;
xlabel('Model Peak Freq (Hz)');
ylabel('inverse of peak ITI (Hz)');
[c,p] = corr(peakFreqs',1./peakITIs');
ax_pos = get(gca,'position');
corrLabelAxH = axes('position',[ax_pos(1) ax_pos(2)-0.05 ax_pos(3) .05],'visible','off');
text(0.5,0.5,sprintf('Corr: %.2f pval: %.4f',c,p),'horizontalalignment','center');
