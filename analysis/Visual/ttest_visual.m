% ttest - three segments 
load('segmentedX.mat');
cc=load('segmentedX.mat');
cc=cc.segmentedX;

% Subject x Trial x Channel x Segment x DataPoints
% First calculate RMS of each segment's data points
% Then average across all trials for each subject 
rms_data = sqrt(mean(cc.^2, 5));  % RMS across data points (dimension 5)
avgData = squeeze(mean(rms_data, 2));  % Average across trials (dimension 2)  

% Perform paired t-test between segments for channels 1-14
% avgData is now Subject x Channel x Segment

% Initialize results structure
ttest_results = struct();

% T-test between segment 1 and 2
for channel = 1:14
    seg1_data = avgData(:, channel, 1);
    seg2_data = avgData(:, channel, 2);
    
    [h, p, ci, stats] = ttest(seg2_data, seg1_data, 'tail', 'both');
    
    ttest_results.seg1_vs_seg2.h(channel) = h;
    ttest_results.seg1_vs_seg2.p(channel) = p;
    
    fprintf('Channel %d, Seg2 > Seg1: t(%.0f) = %.3f, p = %.4f\n', ...
            channel, stats.df, stats.tstat, p);
end

% Count significant channels for Seg2 > Seg1
num_sig_seg2_gt_seg1 = sum(ttest_results.seg1_vs_seg2.h);
fprintf('\nNumber of channels where Seg2 > Seg1 is significant: %d out of 14\n', num_sig_seg2_gt_seg1);

% T-test between segment 2 and 3
for channel = 1:14
    seg2_data = avgData(:, channel, 2);
    seg3_data = avgData(:, channel, 3);
    
    [h, p, ci, stats] = ttest(seg2_data, seg3_data, 'tail', 'both');
    
    ttest_results.seg2_vs_seg3.h(channel) = h;
    ttest_results.seg2_vs_seg3.p(channel) = p;
    
    fprintf('Channel %d, Seg2 > Seg3: t(%.0f) = %.3f, p = %.4f\n', ...
            channel, stats.df, stats.tstat, p);
end

% Count significant channels for Seg2 > Seg3
num_sig_seg2_gt_seg3 = sum(ttest_results.seg2_vs_seg3.h);
fprintf('\nNumber of channels where Seg2 > Seg3 is significant: %d out of 14\n', num_sig_seg2_gt_seg3);

