function [MI_Boot, bootIndices] = MI_Calculate(signal, maxLagSec, k, nBoot)
% MI_Calculate - Serial Optimized MI Calculation with Progress Bars
%
% Optimizations:
%   1. SERIAL execution: Allows knnsearch to use all CPU cores natively.
%   2. UPPER TRIANGLE Only: Computes (i<=j) and mirrors (i>j).
%      Reduces workload by ~50%.
%   3. Progress Bars: Visual feedback for Bootstraps and Channel Pairs.
%   4. Returns bootIndices to ensure Bias calculation uses identical samples.
%
% Inputs:
%   signal : [subjects x channels x samples]
%   nBoot  : Number of bootstraps (default 20)
%
% Outputs:
%   MI_Boot     : Struct containing .vals (Raw MI) and .lags
%   bootIndices : [nBoot x nSubjects] matrix of subject indices used

    if nargin < 3 || isempty(k), k = 3; end
    if nargin < 4 || isempty(nBoot), nBoot = 20; end
    
    Fs = 256; 
    maxLagSamples = round(maxLagSec * Fs);
    lags = -maxLagSamples:maxLagSamples;
    nLags = length(lags);
    
    % Clean NaNs
    validSubjects = squeeze(all(all(~isnan(signal), 2), 3));
    signal = signal(validSubjects, :, :);
    [nSubjects, nCh, ~] = size(signal);
    
    % Total number of pairs to compute per bootstrap (Upper Triangle)
    % Sum of 1 to nCh = nCh*(nCh+1)/2
    totalPairs = nCh * (nCh + 1) / 2;
    
    MI_raw = zeros(nBoot, nCh, nCh, nLags);
    bootIndices = zeros(nBoot, nSubjects); % Store indices here
    
    fprintf('=== Starting MI Calculation (Serial, Optimized) ===\n');
    fprintf('Config: %d Bootstraps, %d Channels\n', nBoot, nCh);
    
    % Initialize Progress Bar (2 Levels)
    progressbar('Bootstrap Progress', 'Channel Pair Progress');
    
    tTotal = tic;
    
    for b = 1:nBoot
        tBoot = tic;
        fprintf('Bootstrap %d/%d... ', b, nBoot);
        
        % Reset inner progress bar for this bootstrap
        progressbar([], 0);
        pairCounter = 0;
        
        % 1. Bootstrap Resampling
        % We sample nSubjects with replacement
        idx = randsample(nSubjects, nSubjects, true);
        bootIndices(b, :) = idx; % Save the indices
        
        % Compute average signal for this bootstrap
        bootData = squeeze(mean(signal(idx, :, :), 1)); 
        
        % 2. Serial Loop over Upper Triangle
        % We iterate i and j normally. 
        for i = 1:nCh
            % Extract X once per row
            X = bootData(i, :)';
            
            for j = i:nCh
                Y = bootData(j, :)';
                
                % Compute MI
                % (We inline the lag loop logic slightly for speed/clarity)
                mi_vals = compute_lagged_mi_serial(X, Y, k, maxLagSamples, nLags);
                
                % Store (Upper Triangle)
                MI_raw(b, i, j, :) = mi_vals;
                
                % Store (Lower Triangle - Symmetry)
                if i ~= j
                    % MI(Y, X, lag) = MI(X, Y, -lag)
                    MI_raw(b, j, i, :) = flip(mi_vals);
                end
                
                % Update Inner Progress Bar
                pairCounter = pairCounter + 1;
                progressbar([], pairCounter / totalPairs);
            end
        end
        
        % Update Outer Progress Bar
        progressbar(b / nBoot, []);
        
        fprintf('Done in %.2fs\n', toc(tBoot));
    end
    
    % Close Progress Bar
    progressbar(1);
    
    MI_Boot.vals = MI_raw;
    MI_Boot.lags = lags;
    MI_Boot.params.k = k;
    MI_Boot.params.nBoot = nBoot;
    
    fprintf('✅ Total Time: %.2fs\n', toc(tTotal));
end

function MI_vals = compute_lagged_mi_serial(X, Y, k, maxLag, nLags)
    MI_vals = nan(1, nLags);
    lags = -maxLag:maxLag;
    
    for idx = 1:nLags
        lag = lags(idx);
        if lag > 0
            Xs = X(1:end-lag); Ys = Y(1+lag:end);
        elseif lag < 0
            Xs = X(1-lag:end); Ys = Y(1:end+lag);
        else
            Xs = X; Ys = Y;
        end
        
        if length(Xs) >= k + 5
            % This call uses multithreading internally
            MI_vals(idx) = MI_KNN_cont_cont(Xs, Ys, k);
        end
    end
end