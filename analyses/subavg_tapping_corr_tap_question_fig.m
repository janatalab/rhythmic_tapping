% subavg_tapping_corr_tap_question_fig.m
%
% Used in conjunction with rhythmTap_tapping_figs and
% tapping_corr_tap_question_fig
%

var2 = measures2plot{ivar};

% Enjoyment/tapping corr
figure(2), clf
var1 = 'compqid_207_1';
var1_idx = strmatch(var1, vars2analyze);
var2_idx = strmatch(var2, vars2analyze);
curr_qinfo = qinfo([qinfo.compqid]==207.01);
append_str = '';
tapping_corr_tap_question_fig;

% Music groove
figure(3), clf
append_str = '-append';
var1 = 'compqid_493_1';
var1_idx = strmatch(var1, vars2analyze);
var2_idx = strmatch(var2, vars2analyze);
curr_qinfo = qinfo([qinfo.compqid]==493.01);
tapping_corr_tap_question_fig;

% Self groove
figure(4), clf
append_str = '-append';
var1 = 'compqid_494_1';
var1_idx = strmatch(var1, vars2analyze);
var2_idx = strmatch(var2, vars2analyze);
curr_qinfo = qinfo([qinfo.compqid]==494.01);
tapping_corr_tap_question_fig;

% difficulty
figure(5), clf
append_str = '-append';
var1 = 'compqid_498_1';
var1_idx = strmatch(var1, vars2analyze);
var2_idx = strmatch(var2, vars2analyze);
curr_qinfo = qinfo([qinfo.compqid]==498.01);
tapping_corr_tap_question_fig;

% desire cont
figure(6), clf
append_str = '-append';
var1 = 'compqid_505_1';
var1_idx = strmatch(var1, vars2analyze);
var2_idx = strmatch(var2, vars2analyze);
curr_qinfo = qinfo([qinfo.compqid]==505.01);
tapping_corr_tap_question_fig;
