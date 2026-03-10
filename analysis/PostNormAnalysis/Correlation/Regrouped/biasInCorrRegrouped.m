%% bootstrap_corr_bias_struct_FAST_CORRECTED_RegionWise.m
% Fast bootstrap estimation of bias in autocorrelation and cross-correlation
% (REGION-Wise Edition)
%
% Modifications:
% 1. Calculates bias for every channel pair.
% 2. Aggregates channel pairs into REGIONS (8x8) before storing.
% 3. 500 Bootstraps.
% 4. Saves Mean and Std of Region-wise bias.

% clear; clc;

% ============================
% PARAMETERS
% ============================
N_BOOTSTRAP = 500;
saveFile   = 'bias_corr_results_pass-act_regionwise.mat';

% ============================
% LOAD DATA
% ============================
% Assuming 'passnorm' is in your workspace
% if ~exist('passnorm', 'var')
%     error('Variable "passnorm" not found in workspace.');
% end
datanorm = pass_actNorm; 

outFields  = fieldnames(datanorm);
stimFields = fieldnames(datanorm.Out12);['' ...
    '' ...
    '    ']
% stimFields = stimFields(contains(stimFields, 'Trial'));
results = struct();

% ============================
% REGION DEFINITIONS
% ============================
% Channel order: 
% 1:AF3, 2:F7, 3:F3, 4:FC5, 5:T7, 6:P7, 7:O1, 
% 8:O2, 9:P8, 10:T8, 11:FC6, 12:F4, 13:F8, 14:AF4

% Map labels to indices manually based on the fixed order above
% L_Frontal: 'AF3'(1), 'F3'(3), 'FC5'(4) -> [1, 3, 4]
% R_Frontal: 'FC6'(11), 'F4'(12), 'AF4'(14) -> [11, 12, 14]
% L_Temporal: 'T7'(5) -> [5]
% R_Temporal: 'T8'(10) -> [10]
% L_Parietal: 'P7'(6) -> [6]
% R_Parietal: 'P8'(9) -> [9]
% L_Occipital: 'O1'(7) -> [7]
% R_Occipital: 'O2'(8) -> [8]
% Note: 'F7'(2) and 'F8'(13) were missing from your snippet group? 
% I will assume they are excluded or should be added to Frontal? 
% Based on your snippet "left_frontal = idx({'AF3','F3','FC5'});", F7 is ignored.
% I will strictly follow your snippet.

regions = {};
regions{1} = [1, 3, 4];    % L_Frontal
regions{2} = [11, 12, 14]; % R_Frontal
regions{3} = [5];          % L_Temporal
regions{4} = [10];         % R_Temporal
regions{5} = [6];          % L_Parietal
regions{6} = [9];          % R_Parietal
regions{7} = [7];          % L_Occipital
regions{8} = [8];          % R_Occipital

regionLabels = {'L_Frontal','R_Frontal','L_Temporal','R_Temporal', ...
                'L_Parietal','R_Parietal','L_Occipital','R_Occipital'};
nReg = length(regions);

% Initialize Progress Bar
progressbar('Outcome', 'Stimulus', 'Bootstrap');

% ============================
% MAIN LOOP
% ============================
for outIdx = 1:numel(outFields)
    outName = outFields{outIdx};
    
    for stimIdx = 1:numel(stimFields)
        stimName = stimFields{stimIdx};
        
        data = datanorm.(outName).(stimName);   % trials × channels × time
        [nTrials, nCh, nTime] = size(data);
        
        % Validate channel count
        if nCh ~= 14
            warning('Expected 14 channels, found %d. Indices might be wrong.', nCh);
        end
        
        % --- lag axis ---
        nLag = 2*nTime - 1;
        lags = -(nTime-1):(nTime-1);
        
        % --- FFT parameters ---
        nFFT = 2^nextpow2(nLag); 
        
        % --- Storage for Region-wise Bias ---
        % [500 x 8 x 8 x Lags] is much smaller (~500MB), totally fine.
        RegionCorrBoot = zeros(N_BOOTSTRAP, nReg, nReg, nLag);

        % ============================
        % BOOTSTRAP LOOP
        % ============================
        parfor b = 1:N_BOOTSTRAP
            
            % 1. Time Shuffling
            shuffled = zeros(nTrials, nCh, nTime);
            for tr = 1:nTrials
                for c = 1:nCh
                     shuffled(tr, c, :) = data(tr, c, randperm(nTime));
                end
            end
            
            % 2. Trial Average & Normalize
            X = squeeze(mean(shuffled, 1));    % [nCh x nTime]
            X = zscore(X, 0, 2);               % Normalize per channel
            
            % 3. FFT
            FX = fft(X, nFFT, 2);
            
            % 4. Compute All Channel Pairs FIRST
            % We need to compute all pairs to average them into regions
            % We can optimize: Only compute required pairs? 
            % Since we need almost all, computing all is cleaner.
            
            % Matrix of Channel Cross-Correlations for this bootstrap
            % [nCh x nCh x nLag]
            chan_cc_matrix = zeros(nCh, nCh, nLag);
            
            % Pre-calculate indices to crop the correlation
            center = floor(nFFT/2) + 1;
            idx_start = center - (nTime-1);
            idx_end   = center + (nTime-1);

            for i = 1:nCh
                for j = i:nCh % Upper Triangle
                    Pxy = FX(i, :) .* conj(FX(j, :));
                    raw_cc = real(ifft(Pxy, nFFT));
                    full_cc = fftshift(raw_cc);
                    
                    if length(full_cc) > nLag
                         cc_trimmed = full_cc(idx_start:idx_end);
                    else
                         cc_trimmed = full_cc;
                    end
                    cc_norm = cc_trimmed / nTime;
                    
                    chan_cc_matrix(i, j, :) = cc_norm;
                    if i ~= j
                        chan_cc_matrix(j, i, :) = flip(cc_norm);
                    end
                end
            end
            
            % 5. Aggregate into Regions
            % Loop over 8x8 regions
            reg_slice = zeros(nReg, nReg, nLag);
            for r1 = 1:nReg
                idx1 = regions{r1};
                for r2 = 1:nReg
                    idx2 = regions{r2};
                    
                    % Extract sub-matrix of correlations
                    % Dimensions: [numel(idx1) x numel(idx2) x nLag]
                    subMat = chan_cc_matrix(idx1, idx2, :);
                    
                    % Mean across all pairs in this region block
                    % mean(mean(..., 1), 2) collapses the first two dims
                    avgCurve = squeeze(mean(mean(subMat, 1), 2));
                    
                    reg_slice(r1, r2, :) = avgCurve;
                end
            end
            
            RegionCorrBoot(b, :, :, :) = reg_slice;
            
            if mod(b, 50) == 0, fprintf('.'); end
        end
        fprintf('\n');

        % ============================
        % SUMMARY STATISTICS
        % ============================
        biasMean = squeeze(mean(RegionCorrBoot, 1));      % [nReg x nReg x nLag]
        biasStd  = squeeze(std(RegionCorrBoot, 0, 1));    % [nReg x nReg x nLag]
        
        resStruct = struct();
        resStruct.lags = lags;
        resStruct.mean = biasMean;
        resStruct.std  = biasStd;
        resStruct.regionLabels = regionLabels;
        
        results.(outName).(stimName) = resStruct;
        
        RegionCorrBoot = []; % clear RAM
        
        progressbar([], [], 1); 
        progressbar([], (stimIdx + (outIdx-1)*numel(stimFields)) / (numel(outFields)*numel(stimFields)));
    end
    progressbar(outIdx/numel(outFields));
end

progressbar(1);

% ============================
% SAVE
% ============================
save(saveFile, 'results', '-v7.3');
fprintf('Saved REGION-wise summary statistics to %s\n', saveFile);