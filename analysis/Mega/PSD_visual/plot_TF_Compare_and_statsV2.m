%% ============================================================
%  Plot TF_Compare + ROI collapse + permutation statistics
%  Assumes TF_Compare already exists in workspace
%  UPDATED: Includes RMS Normalization (1/sqrt(N)) for bin sizes
% ============================================================
clc; close all;

% Check if data is loaded, otherwise try to load
if ~exist('TF_Compare','var')
    if exist('TF_compareSpectrograms.mat', 'file')
        load TF_compareSpectrograms.mat
    else
        warning('TF_Compare variable not found. Please load your data.');
    end
end

%% ---------------- CONFIG ----------------
bands = {'delta_spectrogram','theta_spectrogram','alpha_spectrogram','beta_spectrogram','gamma_spectrogram'};

% !!! IMPORTANT: Update these to match your actual frequency bin counts !!!
% Example assumptions: 
% Delta (1-4Hz)=4bins, Theta(4-8Hz)=5bins, Alpha(8-13Hz)=6bins, 
% Beta(13-30Hz)=18bins, Gamma(30-80Hz)=51bins.
bin_counts = [4, 5, 6, 18, 51]; 

channels_labels = {'AF3','F7','F3','FC5','T7','P7','O1','O2', ...
                   'P8','T8','FC6','F4','F8','AF4'};

% helper for channel indices
idx = @(x) find(ismember(channels_labels, x));

% ROI definitions
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
eps_val   = 1e-12;
nPerm     = 1000;

%% ============================================================
%  1) BAND x CHANNEL HEATMAPS (RMS CORRECTED)
% ============================================================
DI_mat  = zeros(nChannels, nBands);
RCI_mat = zeros(nChannels, nBands);

for b = 1:nBands
    band = bands{b};
    Nf   = bin_counts(b); % Get bin count for this band
    
    % Normalization factor: 1 / sqrt(N_frequency_bins)
    norm_factor = 1 / sqrt(Nf);
    
    for c = 1:nChannels
        chName = ['ch_' channels_labels{c}];
        
        % Check if fields exist to avoid crash
        if isfield(TF_Compare.(band), chName)
            % Apply RMS correction to DI
            raw_DI = TF_Compare.(band).(chName).DI;
            DI_mat(c,b) = raw_DI * norm_factor; 
            
            % RCI is a ratio (D13/D12). The norm_factor cancels out, 
            % so we can use the raw RCI directly.
            RCI_mat(c,b) = TF_Compare.(band).(chName).RCI; 
        end
    end
end

% figure('Name','');
figure;
imagesc(DI_mat);
colorbar;
clim([0 2]);
set(gca,'XTick',1:nBands,'XTickLabel',bands);
set(gca,'YTick',1:nChannels,'YTickLabel',channels_labels);
xlabel('Band'); ylabel('Channel');
title('DI Heatmap (RMS Normalized): RMS Deviance Index (S2 vs S1)');

% figure('Name','');
figure;
imagesc(RCI_mat);
colorbar;
clim([0 2]);
set(gca,'XTick',1:nBands,'XTickLabel',bands);
set(gca,'YTick',1:nChannels,'YTickLabel',channels_labels);
xlabel('Band'); ylabel('Channel');
title('RCI Heatmap: Recovery / Carryover Index (S3 vs S1 relative to S2)');

%% ============================================================
%  2) ROI COLLAPSE (RMS CORRECTED)
% ============================================================
% infer number of subjects from first available channel
example = TF_Compare.alpha_spectrogram.(['ch_' channels_labels{1}]).D12;
nSubj = numel(example);

DI_roi  = zeros(nRegions, nBands, nSubj);
RCI_roi = zeros(nRegions, nBands, nSubj);

for b = 1:nBands
    band = bands{b};
    Nf   = bin_counts(b);
    norm_factor = 1 / sqrt(Nf);
    
    for r = 1:nRegions
        chIdx = groups{r};
        for subj = 1:nSubj
            D12_vals = [];
            D13_vals = [];
            
            for c = chIdx
                chName = ['ch_' channels_labels{c}];
                
                % Retrieve raw distances
                raw_d12 = TF_Compare.(band).(chName).D12(subj);
                raw_d13 = TF_Compare.(band).(chName).D13(subj);
                
                % Apply Correction
                D12_vals(end+1) = raw_d12 * norm_factor; %#ok<SAGROW>
                D13_vals(end+1) = raw_d13 * norm_factor; %#ok<SAGROW>
            end
            
            % Average across channels in ROI
            % Note: DI is D12
            mean_D12 = mean(D12_vals, 'omitnan');
            mean_D13 = mean(D13_vals, 'omitnan');
            
            DI_roi(r,b,subj)  = mean_D12;
            
            % RCI = D13 / D12. 
            % Since both were scaled by norm_factor, it cancels out here too.
            RCI_roi(r,b,subj) = mean_D13 / (mean_D12 + eps_val);
        end
    end
end

% figure('Name','');
figure;
imagesc(mean(DI_roi,3));
colorbar;
clim([0 2]);
set(gca,'XTick',1:nBands,'XTickLabel',bands);
set(gca,'YTick',1:nRegions,'YTickLabel',region_labels);
xlabel('Band'); ylabel('Region');
title('ROI Deviance Index (RMS Corrected)');

% figure('Name','ROI RCI');
figure;
imagesc(mean(RCI_roi,3));
colorbar;
clim([0 2]);
set(gca,'XTick',1:nBands,'XTickLabel',bands);
set(gca,'YTick',1:nRegions,'YTickLabel',region_labels);
xlabel('Band'); ylabel('Region');
title('ROI Recovery / Carryover Index');

%% ============================================================
%  3) PERMUTATION TESTS (PRINT P-VALUES)
% ============================================================
fprintf('\n================ PERMUTATION TEST RESULTS ================\n');
fprintf('NOTE: DI values are now RMS normalized (comparable across bands).\n');
fprintf('RCI values are ratios and remain unitless.\n');

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
                % Note: This test assumes DI and RCI are exchangeable under Null.
                % Ensure this makes sense for your specific hypothesis.
                flip = rand > 0.5;
                if flip
                    perm_DI(subj)  = RCI_roi(r,b,subj); 
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