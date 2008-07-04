project_dir = '/afs/cmb.ucdavis.edu/share/petrlab/rhythmic_tapping/v2';
wav_dir = fullfile(project_dir,'dp_stimuli');
midi_dir = fullfile(project_dir,'dp_responses');

wav_files = dir(fullfile(wav_dir,'*.wav'));

for ifile = 1:length(wav_files);
  
  wav_size = wavread(fullfile(wav_dir,wav_files(ifile).name),'size');
  wav_dur = wav_size(1)./44100;
  
  fname_spec = sscanf(wav_files(ifile).name,'stim_rec%s');
  [p,fname_spec] = fileparts(fname_spec);
  midi_fname = ['midi_resp' fname_spec '.mid'];
  
  tr = javamidi2tr(fullfile(midi_dir,midi_fname));
  
  midi_dur = tr(2).nmat(end,6);
  
  checksess(ifile).name = fname_spec;
  checksess(ifile).wav_dur = wav_dur;
  checksess(ifile).midi_dur = midi_dur;
  checksess(ifile).dur_diff = wav_dur - midi_dur;
  
  
  
end
