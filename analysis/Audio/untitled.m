% correct(1,1,1) = 0;
% correct(2,1,1) = 0;
% correct(4,1,1) = 0;
% correct(2,1,2) = 0;
% correct(18,1,2) = 0;
% correct(2,1,3) = 0;
% correct(4,1,3) = 0;
% correct(2,1,4) = 0;
% correct(11,1,4) = 0;
% correct(2,1,5) = 0;
% correct(2,1,6) = 0;
% correct(16,1,6) = 0;
% correct(2,1,8) = 0;
% correct(2,1,9) = 0;
% correct(2,1,10) = 0;
% correct(16,3,1) = 0;
% correct(22,3,5) = 0;
% correct(10,3,8) = 0;

%after subs removal
% correct(1,1,1) = 0;
% correct(12,3,1) = 0;

RT = res.RT;
correct = res.correct;

nSub = size(RT,1);

RT1 = nan(nSub,1);
RT3 = nan(nSub,1);


for s=1:nSub
rt1 = squeeze(RT(s,1,:));
c1 = squeeze(correct(s,1,:));

rt3 = squeeze(RT(s, 3, :));
c3 = squeeze(correct(s, 3, :));

rt1 = rt1 .* c1;
rt3 = rt3 .* c3;

RT1(s) = mean(rt1,'omitmissing');
RT3(s) = mean(rt3,'omitmissing');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% --- 1. Accuracy: Stim 1 vs Stim 3 ---
acc1 = accuracy(:, 1);
acc3 = accuracy(:, 3);

% A. Basic t-test
[~, p_acc_ttest] = ttest(acc1, acc3);

% B. Log t-test (adding small constant to avoid log(0))
[~, p_acc_log] = ttest(log(acc1 + 0.01), log(acc3 + 0.01));

% C. Wilcoxon Signed Rank
p_acc_wilcoxon = signrank(acc1, acc3);

% D. Logit-then-ttest (with correction for 0 or 1 values)
logit_trans = @(p) log((p * 10 + 0.5) ./ (10 - p * 10 + 0.5)); % Adjusts for 10 trials
[~, p_acc_logit] = ttest(logit_trans(acc1), logit_trans(acc3));

%% --- 2. Accuracy: (Stim 1+2) vs (Stim 3+4) ---
acc_12 = mean(accuracy(:, 1:2), 2);
acc_34 = mean(accuracy(:, 3:4), 2);

[~, p_pool_ttest]  = ttest(acc_12, acc_34);
[~, p_pool_logit]  = ttest(logit_trans(acc_12), logit_trans(acc_34));
p_pool_wilcoxon    = signrank(acc_12, acc_34);

%% --- 3. Reaction Time Analysis ---
% Convert 0 (incorrect) to NaN so they don't bias the mean
RT_cleaned = RT;
RT_cleaned(correct == 0) = NaN;

% Collapse 10 trials into 1 mean per subject per stim
% Result is 25 x 4
subj_RT = squeeze(nanmean(RT_cleaned, 3)); 

rt1 = subj_RT(:, 1);
rt3 = subj_RT(:, 3);

% A. Basic t-test on Raw RT
[~, p_rt_ttest] = ttest(rt1, rt3);

% B. Wilcoxon Signed Rank on Raw RT
p_rt_wilcoxon = signrank(rt1, rt3);

% C. Basic t-test on Log RT
[~, p_rt_log_ttest] = ttest(log(rt1), log(rt3));

% D. Wilcoxon on Log RT (Note: Wilcoxon results will be identical to Raw RT)
p_rt_log_wilcoxon = signrank(log(rt1), log(rt3));

Variable = {'Acc (1 v 3)'; 'Acc (Pool)'; 'RT (1 v 3)'};
T_test = [p_acc_ttest; p_pool_ttest; p_rt_ttest];
Log_T_test = [p_acc_log; nan; p_rt_log_ttest];
Wilcoxon = [p_acc_wilcoxon; p_pool_wilcoxon; p_rt_wilcoxon];
Logit_T = [p_acc_logit; p_pool_logit; nan];

resultsTable = table(Variable, T_test, Log_T_test, Logit_T, Wilcoxon)