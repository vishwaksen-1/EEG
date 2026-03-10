function results = analyze_behavior(data, varargin)
% =========================================================================
%  ANALYZE_BEHAVIOR  (Cleaned-Up Version)
%
%  Extract lag and response only once → compute RT + correctness →
%  run all analyses using clean arrays.
% =========================================================================

%% === Parse optional args =================================================
p = inputParser;
addParameter(p, 'saveResults', false, @islogical);
addParameter(p, 'savePrefix',  'behav', @ischar);
parse(p, varargin{:});

saveResults = p.Results.saveResults;
prefix      = p.Results.savePrefix;

%% === Basic sizes =========================================================
[numSubj, numStim, numTrials] = size(data);

periodic   = [1 3];
aperiodic  = [2 4];

%% ========================================================================
%   EXTRACT RT + Correctness (ONLY ONCE)
% ========================================================================

% Preallocate
lag_raw = nan(numSubj,numStim,numTrials);
res_raw = nan(numSubj,numStim,numTrials);

for s = 1:numSubj
    for st = 1:numStim
        for t = 1:numTrials
            lag_raw(s,st,t) = data(s,st,t).lag;
            res_raw(s,st,t) = data(s,st,t).res;
        end
    end
end

% --- Clean LAG values ---
RT = lag_raw - 3.6 + 0.592; % subtract once
RT(RT <= 0) = NaN;          % negative/zero = invalid→NaN

% --- Correctness ---
correct = res_raw;          % already 0 or 1 values

% --- RTs_all cell (for compatibility with old code) ---
RTs_all = cell(numSubj,numStim);
for s = 1:numSubj
    for st = 1:numStim
        lag_vals = squeeze(RT(s,st,:));
        RTs_all{s,st} = lag_vals(~isnan(lag_vals));
    end
end

%% ========================================================================
%   1. Accuracy
% ========================================================================
accuracy = nan(numSubj, numStim);
for s = 1:numSubj
    for st = 1:numStim
        valid = ~isnan(correct(s,st,:));
        accuracy(s,st) = mean(correct(s,st,valid)==1);
    end
end

figure;
imagesc(accuracy);
colorbar; xlabel('Stimulus'); ylabel('Subject number'); clim([0 1]);
title('subject-wise Accuracy (Percent Correct)');

%% ========================================================================
%   2. d-prime
% ========================================================================
zc = @(p) norminv(max(min(p, 1-1/(2*50)), 1/(2*50)));

dprime = nan(numSubj,1);

for s = 1:numSubj
    
    yesP = ~isnan(RT(s,periodic,:));
    hit_rate = mean(yesP(:));
    
    yesA = ~isnan(RT(s,aperiodic,:));
    fa_rate = mean(yesA(:));

    dprime(s) = zc(hit_rate) - zc(fa_rate);
end

figure; bar(dprime);
xlabel('Subject number'); ylabel('d-prime'); title('subject-wise d-prime Sensitivity');

%% ========================================================================
%   3. RT vs Correctness
% ========================================================================
meanRT_correct = nan(numSubj,1);
meanRT_wrong   = nan(numSubj,1);

for s = 1:numSubj
    allRT = squeeze(RT(s,:,:));
    allC  = squeeze(correct(s,:,:));

    meanRT_correct(s) = mean(allRT(allC==1),'omitnan');
    meanRT_wrong(s)   = mean(allRT(allC==0),'omitnan');
end

figure; hold on; grid on;
plot(meanRT_correct, 'o-','LineWidth',2);
plot(meanRT_wrong,   'o-','LineWidth',2);
legend({'Correct RT','Wrong RT'});
xlabel('Subject number'); ylabel('RT (s)');
title('subject-wise Mean Reaction Time vs Correctness');

%% ========================================================================
%   4. Miss Rate (Periodic) & FA Rate (Aperiodic)
% ========================================================================

miss_rate_periodic = squeeze(mean(isnan(RT(:,periodic,:)), 3));
fa_rate_aperiodic  = squeeze(mean(~isnan(RT(:,aperiodic,:)), 3));

% Bootstrap
numBoot = 500;

miss_boot = nan(numBoot, numel(periodic));
fa_boot   = nan(numBoot, numel(aperiodic));

for i = 1:numel(periodic)
    vals = miss_rate_periodic(:,i);
    for b = 1:numBoot
        miss_boot(b,i) = mean(vals(randi(numSubj,numSubj,1)));
    end
end

for i = 1:numel(aperiodic)
    vals = fa_rate_aperiodic(:,i);
    for b = 1:numBoot
        fa_boot(b,i) = mean(vals(randi(numSubj,numSubj,1)));
    end
end

miss_mean = mean(miss_boot); miss_CI = prctile(miss_boot,[2.5 97.5]);
fa_mean   = mean(fa_boot);   fa_CI   = prctile(fa_boot,[2.5 97.5]);

figure;
subplot(1,2,1);
bar(miss_mean); hold on;
for i=1:length(miss_mean), plot([i i], miss_CI(:,i),'k-','LineWidth',2); end
xticklabels({'Stim1','Stim3'}); ylim([0 1]);
title('Overall Miss Rate (Periodic Only)(boostrapped @ 500)');

subplot(1,2,2);
bar(fa_mean); hold on;
for i=1:length(fa_mean), plot([i i], fa_CI(:,i),'k-','LineWidth',2); end
xticklabels({'Stim2','Stim4'}); ylim([0 1]);
title('Overall False Alarm Rate (Aperiodic Only)(boostrapped @ 500)');

%% ========================================================================
%   5. Correlation periodic vs aperiodic RT
% ========================================================================
meanRT_period_120 = squeeze(mean(RT(:,1,:), 3, "omitnan"));
meanRT_ap_120     = squeeze(mean(RT(:,2,:), [3], "omitnan"));
meanRT_period_270 = squeeze(mean(RT(:,3,:), [3], "omitnan"));
meanRT_ap_270     = squeeze(mean(RT(:,4,:), [3], "omitnan"));
xx = 0:2.2;
xy = xx;

[rho_120,pval_120] = corr(meanRT_period_120, meanRT_ap_120, "rows","complete");
[rho_270,pval_270] = corr(meanRT_period_270, meanRT_ap_270, "rows","complete");

figure; scatter(meanRT_period_120, meanRT_ap_120,60,'ro','filled', 'DisplayName','120 ITI'); hold on;
scatter(meanRT_period_270, meanRT_ap_270,60,'bo','filled', 'DisplayName','270 ITI');
plot(xx, xy, '--r', 'DisplayName','x=y line'); hold off; legend();
% xlim([0 2.4]);
% ylim([0 2.4]);
title(sprintf('Periodic vs Aperiodic RT\n(r 120 = %.2f, p 120 = %.3f)\n(r 270 = %.2f, p 270 = %.3f)', rho_120, pval_120, rho_270, pval_270));
xlabel('Periodic RT'); ylabel('Aperiodic RT'); grid on;
xx = -1:1.5;
xy = xx;
figure; scatter(log(meanRT_period_120), log(meanRT_ap_120),60,'ro','filled', 'DisplayName','120 ITI'); hold on;
scatter(log(meanRT_period_270), log(meanRT_ap_270),60,'bo','filled', 'DisplayName','270 ITI');
plot(xx, xy, '--r', 'DisplayName','x=y line'); hold off; legend();
title("Periodic vs Aperiodic RT (in Log scale)");
xlabel('Periodic RT'); ylabel('Aperiodic RT'); grid on;
%% ========================================================================
%   6. Original Code Plots (RT histograms, imagesc)
% ========================================================================

% Per-subject RT histograms
figure;
for s = 1:numSubj
    allRT = vertcat(RTs_all{s,:});   % combine stim RTs

    subplot(5,5,s);
    histogram(allRT,20);
    title(['Subject ' num2str(s)]); ylim([0 6]); xlim([0 3]);
end
sgtitle('Subjectwise individual reactiontime histograms');

% RT by stim (imagesc)
RT_by_stim = permute(RT, [1 3 2]);   % subj × trial × stim

figure;
subplot(1,2,1); imagesc(RT_by_stim(:,:,1)); colorbar; clim([0 3]);
title('120 ITI Periodic'); xlabel('Trial'); ylabel('Subject');

subplot(1,2,2); imagesc(RT_by_stim(:,:,2)); colorbar; clim([0 3]);
title('120 ITI Aperiodic'); xlabel('Trial'); ylabel('Subject');
sgtitle('Subject-wise RT Across trials for 120 ITI');

figure;
subplot(1,2,1); imagesc(RT_by_stim(:,:,3)); colorbar; clim([0 3]);
title('270 ITI Periodic');

subplot(1,2,2); imagesc(RT_by_stim(:,:,4)); colorbar; clim([0 3]);
title('270 ITI Aperiodic');
sgtitle('Subject-wise RT Across trials for 270 ITI');

% Global histograms
allRT_flat = vertcat(RTs_all{:});

figure; histogram(allRT_flat,30);
title('All RTs (All Subjects Histogram)'); xlabel('RT'); ylabel('Count');

rt_13 = vertcat(RTs_all{s,1},RTs_all{s,3});
figure; histogram(rt_13,30);
title('RT: Stims 1 & 3');

rt_24 = vertcat(RTs_all{s,2},RTs_all{s,4});
figure; histogram(rt_24,30);
title('RT: Stims 2 & 4');

% === (2×2) Subplots: Reaction Time Histograms for Each Stimulus ===
figure;
for st = 1:4
    % Collect all RTs for this stimulus across all subjects
    rt_stim = [];
    for s = 1:numSubj
        rt_stim = [rt_stim; RTs_all{s,st}(:)];
    end
    rt_stim = rt_stim(~isnan(rt_stim));  % clean
    
    subplot(2,2,st);
    histogram(rt_stim, 30);
    title(['Reaction Times: Stim ' num2str(st)]);
    xlabel('Reaction Time (s)');
    ylabel('Count');
    xlim([0 3]);
    ylim([0 35]);
end

% Bootstrap
numBoot = 500;
boot_means = zeros(numBoot,1);
N = numel(allRT_flat);
for b = 1:numBoot
    boot_means(b) = mean(allRT_flat(randi(N,N,1)));
end

figure; histogram(boot_means,30);
title('Bootstrap Mean RT Distribution');

if saveResults
    save([prefix '_bootstrap.mat'], 'boot_means');
end

%% ========================================================================
%   SAVE OUTPUT STRUCT
% ========================================================================
results.RT   = RT;
results.correct = correct;
results.accuracy = accuracy;
results.dprime   = dprime;
results.miss_rate = miss_rate_periodic;
results.meanRT_correct = meanRT_correct;
results.meanRT_wrong   = meanRT_wrong;
results.meanRT_period_120  = meanRT_period_120;
results.meanRT_ap_120      = meanRT_ap_120;
results.meanRT_period_270  = meanRT_period_270;
results.meanRT_ap_270      = meanRT_ap_270;
% results.corr_periodic_aperiodic = struct('r',rho,'p',pval);
results.boot_means = boot_means;

if saveResults
    save([prefix '_results.mat'], 'results');
end

end
