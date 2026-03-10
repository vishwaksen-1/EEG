%% assuming stim12 / stim34 is loaded -- from final destination

%% step 1: baseline RMS
baselineRMS12 = rmser(stim12.baseline, -1);
baselineRMS34 = rmser(stim34.baseline, -1);

%% step 2: initial segment RMS for whole_stim
SEGMENT_LENGTH = 300; %% 300 ms

whole_stimRMS12 = rmser(stim12.whole_stim, SEGMENT_LENGTH);
whole_stimRMS34 = rmser(stim34.whole_stim, SEGMENT_LENGTH);

%% t-test
ALPHA = 0.05;
[h12, p12, ci12, ~] = ttest(baselineRMS12, whole_stimRMS12, 'Alpha', ALPHA, 'Dim', 2);
[h34, p34, ci34, ~] = ttest(baselineRMS34, whole_stimRMS34, 'Alpha', ALPHA, 'Dim', 2);

hist(baselineRMS12)
hist(baselineRMS34)
hist(whole_stimRMS12)
hist(whole_stimRMS34)

hist(log(baselineRMS12))
hist(log(baselineRMS34))
hist(log(whole_stimRMS12))
hist(log(whole_stimRMS34))
%% t-test assuming lognormal
[h12_l, p12_l, ci12_l, ~] = ttest(log(baselineRMS12), log(whole_stimRMS12), 'Alpha', ALPHA);
[h34_l, p34_l, ci34_l, ~] = ttest(log(baselineRMS34), log(whole_stimRMS34), 'Alpha', ALPHA);

%%