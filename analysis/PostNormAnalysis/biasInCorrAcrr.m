%% bootstrap_corr_bias_struct_FAST_CORRECTED_ChanWise.m
% Fast bootstrap estimation of bias in autocorrelation and cross-correlation
% (Channel-Wise Edition)
%
% Modifications:
% 1. Calculates bias for every channel pair (nCh x nCh).
% 2. 500 Bootstraps.
% 3. Saves ONLY Mean and Std (as a function of lag) to save disk space.

% clear; clc;

% ============================
% PARAMETERS
% ============================
N_BOOTSTRAP = 500;
saveFile   = 'bootstrap_corr_results_datanorm_chanwise.mat';

% ============================
% LOAD DATA
% ============================
% Assuming 'passnorm' is in your workspace
if ~exist('datanorm', 'var')
    error('Variable "datanorm" not found in workspace.');
end
% datanorm = datanorm; 

outFields  = fieldnames(datanorm);
stimFields = {'seg1_subNorm','seg2_subNorm', 'seg3_subNorm'};
results = struct();

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
        
        % --- lag axis (same as xcorr) ---
        nLag = 2*nTime - 1;
        lags = -(nTime-1):(nTime-1);
        
        % --- FFT parameters ---
        nFFT = 2^nextpow2(nLag); 
        
        % --- Temporary Storage ---
        % We still need to hold the bootstrap iterations in memory to calculate 
        % STD, but we won't save this huge matrix to disk.
        try
            CorrBoot = zeros(N_BOOTSTRAP, nCh, nCh, nLag);
        catch
            error('Memory allocation failed. Try reducing N_BOOTSTRAP.');
        end

        % ============================
        % BOOTSTRAP LOOP
        % ============================
        parfor b = 1:N_BOOTSTRAP
            
            % 1. Time Shuffling
            shuffled = zeros(nTrials, nCh, nTime);
            for tr = 1:nTrials
                % Shuffle each channel independently
                for c = 1:nCh
                     shuffled(tr, c, :) = data(tr, c, randperm(nTime));
                end
            end
            
            % 2. Trial Average & Normalize
            X = squeeze(mean(shuffled, 1));    % [nCh x nTime]
            X = zscore(X, 0, 2);               % Normalize per channel
            
            % 3. FFT
            FX = fft(X, nFFT, 2);
            
            % 4. Compute All Pairs
            boot_slice = zeros(nCh, nCh, nLag);
            
            for i = 1:nCh
                for j = i:nCh % Compute Upper Triangle
                    
                    % Cross Power Spectrum & Cross-Correlation
                    Pxy = FX(i, :) .* conj(FX(j, :));
                    raw_cc = real(ifft(Pxy, nFFT));
                    full_cc = fftshift(raw_cc);
                    
                    % Extract center part
                    center = floor(nFFT/2) + 1;
                    idx_start = center - (nTime-1);
                    idx_end   = center + (nTime-1);
                    
                    if length(full_cc) > nLag
                         cc_trimmed = full_cc(idx_start:idx_end);
                    else
                         cc_trimmed = full_cc;
                    end

                    % Normalize
                    cc_norm = cc_trimmed / nTime;
                    
                    boot_slice(i, j, :) = cc_norm;
                    if i ~= j
                        boot_slice(j, i, :) = flip(cc_norm);
                    end
                end
            end
            CorrBoot(b, :, :, :) = boot_slice;
            
            if mod(b, 50) == 0, fprintf('.'); end
        end
        fprintf('\n');

        % ============================
        % SUMMARY STATISTICS (Mean & Std)
        % ============================
        % Calculate statistics across dimension 1 (Bootstraps)
        
        biasMean = squeeze(mean(CorrBoot, 1));      % [nCh x nCh x nLag]
        biasStd  = squeeze(std(CorrBoot, 0, 1));    % [nCh x nCh x nLag]
        
        % Store only the summary stats
        resStruct = struct();
        resStruct.lags = lags;
        resStruct.mean = biasMean;
        resStruct.std  = biasStd;
        
        results.(outName).(stimName) = resStruct;
        
        % Clear the massive matrix to free RAM for next iteration
        CorrBoot = []; 
        
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
fprintf('Saved summary statistics (Mean & Std) to %s\n', saveFile);

% ============================
% PLOTTING (Example for Ch 1-2)
% ============================
% figure;
% plot(lags, squeeze(results.(outFields{1}).(stimFields{1}).meanBias(1,2,:)));
% title('Bias for Ch1-Ch2');

% %% print_bias_thresholds.m
% clear; clc;
% 
% load('bootstrap_corr_results_FAST_CORRECTED.mat','results');
% 
% outFields  = fieldnames(results);
% stimFields = {'stim1_subTrialNorm','stim2_subTrialNorm'};
% 
% fprintf('\n===== BOOTSTRAP CORRELATION BIAS SUMMARY =====\n\n');
% 
% for o = 1:numel(outFields)
%     outName = outFields{o};
%     fprintf('=== %s ===\n', outName);
% 
%     for s = 1:numel(stimFields)
%         stimName = stimFields{s};
%         R = results.(outName).(stimName);
% 
%         % lag index for zero lag
%         zeroIdx = find(R.lags == 0);
% 
%         % ---------------- AUTOCORR ----------------
%         acBias0 = R.auto.bias(zeroIdx);
%         acPeak  = max(abs(R.auto.bias));
% 
%         fprintf('  [%s]\n', stimName);
%         fprintf('    Autocorr bias @ lag 0: %.4f\n', acBias0);
%         fprintf('    Autocorr peak |bias|: %.4f\n', acPeak);
% 
%         for ci = [90 95 99]
%             CI = R.auto.(['CI' num2str(ci)]);
%             fprintf('    Autocorr CI%d: [%.4f  %.4f]\n', ...
%                 ci, CI(1,zeroIdx), CI(2,zeroIdx));
%         end
% 
%         % ---------------- CROSSCORR ----------------
%         ccMean = R.cross.meanBias;
%         ccPeak = max(abs(R.cross.bias));
% 
%         fprintf('    Crosscorr mean bias: %.4f\n', ccMean);
%         fprintf('    Crosscorr peak |bias|: %.4f\n', ccPeak);
% 
%         for ci = [90 95 99]
%             CI = R.cross.(['CI' num2str(ci)]);
%             fprintf('    Crosscorr CI%d @ lag 0: [%.4f  %.4f]\n', ...
%                 ci, CI(1,zeroIdx), CI(2,zeroIdx));
%         end
% 
%         fprintf('\n');
%     end
% end
