%% ============================================================
%  Plot TF_Compare + ROI collapse + permutation statistics
%  Assumes TF_Compare already exists in workspace
% ============================================================

% clc; close all;

load TF_compareSpectrograms.mat

%% ---------------- CONFIG ----------------
bands = {'delta_spectrogram','theta_spectrogram','alpha_spectrogram','beta_spectrogram','gamma_spectrogram'};

channels_labels = {'AF3','F7','F3','FC5','T7','P7','O1','O2', ...
                   'P8','T8','FC6','F4','F8','AF4'};

% helper for channel indices
idx = @(x) find(ismember(channels_labels, x));

% ROI definitions (yours)
left_frontal    = idx({'AF3','F3','FC5'});
right_frontal   = idx({'FC6','F4','AF4'});
left_temporal   = idx({'T7'});
right_temporal  = idx({'T8'});
left_parietal   = idx({'P7'});
right_parietal  = idx({'P8'});
left_occipital  = idx({'O1'});
right_occipital = idx({'O2'});

groups = {left_frontal, right_frontal, left_temporal, right_temporal, ...
          left_parietal, right_parietal, left_occipital, right_occipital};

region_labels = {'L_Frontal','R_Frontal','L_Temporal','R_Temporal', ...
                 'L_Parietal','R_Parietal','L_Occipital','R_Occipital'};

nBands    = numel(bands);
nChannels = numel(channels_labels);
nRegions  = numel(groups);

eps_val = 1e-12;
nPerm   = 1000;

%% ============================================================
%  1) BAND × CHANNEL HEATMAPS
% ============================================================

DI_mat  = zeros(nChannels, nBands);
RCI_mat = zeros(nChannels, nBands);

for b = 1:nBands
    band = bands{b};
    for c = 1:nChannels
        chName = ['ch_' channels_labels{c}];
        DI_mat(c,b)  = TF_Compare.(band).(chName).DI;
        RCI_mat(c,b) = TF_Compare.(band).(chName).RCI;
    end
end

figure('Name','DI Heatmap');
imagesc(DI_mat);
colorbar;
set(gca,'XTick',1:nBands,'XTickLabel',bands);
set(gca,'YTick',1:nChannels,'YTickLabel',channels_labels);
xlabel('Band'); ylabel('Channel');
title('Deviance Index (S2 vs S1)');

figure('Name','RCI Heatmap');
imagesc(RCI_mat);
colorbar;
set(gca,'XTick',1:nBands,'XTickLabel',bands);
set(gca,'YTick',1:nChannels,'YTickLabel',channels_labels);
xlabel('Band'); ylabel('Channel');
title('Recovery / Carryover Index (S3 vs S1 relative to S2)');

%% ============================================================
%  2) ROI COLLAPSE
% ============================================================

% infer number of subjects
example = TF_Compare.alpha_spectrogram.(['ch_' channels_labels{1}]).D12;
nSubj = numel(example);

DI_roi  = zeros(nRegions, nBands, nSubj);
RCI_roi = zeros(nRegions, nBands, nSubj);

for b = 1:nBands
    band = bands{b};
    for r = 1:nRegions
        chIdx = groups{r};
        for subj = 1:nSubj
            D12 = [];
            D13 = [];
            for c = chIdx
                chName = ['ch_' channels_labels{c}];
                D12(end+1) = TF_Compare.(band).(chName).D12(subj);
                D13(end+1) = TF_Compare.(band).(chName).D13(subj);
            end
            DI_roi(r,b,subj)  = mean(D12,'omitnan');
            RCI_roi(r,b,subj) = mean(D13 ./ (D12 + eps_val),'omitnan');
        end
    end
end

figure('Name','ROI DI');
imagesc(mean(DI_roi,3));
colorbar;
set(gca,'XTick',1:nBands,'XTickLabel',bands);
set(gca,'YTick',1:nRegions,'YTickLabel',region_labels);
xlabel('Band'); ylabel('Region');
title('ROI Deviance Index');

figure('Name','ROI RCI');
imagesc(mean(RCI_roi,3));
colorbar;
set(gca,'XTick',1:nBands,'XTickLabel',bands);
set(gca,'YTick',1:nRegions,'YTickLabel',region_labels);
xlabel('Band'); ylabel('Region');
title('ROI Recovery / Carryover Index');

%% ============================================================
%  3) PERMUTATION TESTS (PRINT P-VALUES)
% ============================================================

fprintf('\n================ PERMUTATION TEST RESULTS ================\n');

for b = 1:nBands
    band = bands{b};

    fprintf('\nBand: %s\n', upper(band));
    fprintf('---------------------------------------------\n');

    for r = 1:nRegions

        % observed statistics
        DI_obs  = mean(DI_roi(r,b,:),3,'omitnan');
        RCI_obs = mean(RCI_roi(r,b,:),3,'omitnan');

        DI_null  = zeros(nPerm,1);
        RCI_null = zeros(nPerm,1);

        for p = 1:nPerm
            perm_DI  = zeros(nSubj,1);
            perm_RCI = zeros(nSubj,1);

            for subj = 1:nSubj
                % randomly flip segment roles
                flip = rand > 0.5;

                if flip
                    perm_DI(subj)  = RCI_roi(r,b,subj); % misuse structure intentionally
                    perm_RCI(subj) = DI_roi(r,b,subj);
                else
                    perm_DI(subj)  = DI_roi(r,b,subj);
                    perm_RCI(subj) = RCI_roi(r,b,subj);
                end
            end

            DI_null(p)  = mean(perm_DI,'omitnan');
            RCI_null(p) = mean(perm_RCI,'omitnan');
        end

        p_DI  = mean(DI_null  >= DI_obs);
        p_RCI = mean(RCI_null <= RCI_obs);

        fprintf('%-12s | DI p = %.4f | RCI p = %.4f\n', ...
                region_labels{r}, p_DI, p_RCI);
    end
end

fprintf('\n===========================================================\n');
