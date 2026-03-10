function [BiasStruct] = MI_EstimateBias(signal, bootIndices, maxLagSec, k, nBias)
% MI_EstimateBias - Computes Bias matching specific Bootstrap Indices
%
% Usage:
%   BiasStruct = MI_EstimateBias(signal, bootIndices, maxLagSec, k, nBias)
%
% Logic:
%   1. Iterates through each Bootstrap defined in 'bootIndices'.
%   2. Reconstructs the exact trial-averaged signal used in MI_Calculate.
%   3. Runs 'nBias' permutations on this specific signal to estimate the
%      chance-level MI (Bias) for this specific sample entropy.
%   4. Averages the 'nBias' results to get ONE Bias Matrix per Bootstrap.
%
% Inputs:
%   signal      : [subjects x channels x samples]
%   bootIndices : [nBoot x nSubjects] matrix from MI_Calculate
%   maxLagSec   : Maximum lag in seconds
%   k           : KNN parameter (default 3)
%   nBias       : Number of shuffles per bootstrap to estimate mean bias (default 10)
%
% Outputs:
%   BiasStruct.vals : [nBoot x nCh x nCh x nLags] 
%                     Bias matrix matching MI_Calculate output.

    if nargin < 4 || isempty(k), k = 3; end
    if nargin < 5 || isempty(nBias), nBias = 10; end
    
    Fs = 256; 
    maxLagSamples = round(maxLagSec * Fs);
    lags = -maxLagSamples:maxLagSamples;
    nLags = length(lags);
    
    [nSubjects, nCh, ~] = size(signal);
    [nBoot, ~] = size(bootIndices);
    
    % Output container: One Bias Matrix per Bootstrap
    MI_bias_boot = zeros(nBoot, nCh, nCh, nLags);
    
    % Progress Bar Setup
    fprintf('=== Starting Matched Bias Estimation ===\n');
    fprintf('Config: %d Bootstraps, %d Bias Iters/Boot, %d Channels\n', nBoot, nBias, nCh);
    progressbar('Bootstrap Bias Progress', 'Shuffle Iteration');
    
    tTotal = tic;
    
    % Loop over the specific Bootstraps provided
    for b = 1:nBoot
        tBoot = tic;
        fprintf('Bias for Boot %d/%d... ', b, nBoot);
        
        % 1. Reconstruct the EXACT data used in MI_Calculate
        idx = bootIndices(b, :);
        bootData = squeeze(mean(signal(idx, :, :), 1)); 
        [~, nSamples] = size(bootData);
        
        % Temporary accumulator for the nBias iterations
        bias_accumulator = zeros(nCh, nCh, nLags);
        
        % Reset Inner Bar
        progressbar([], 0);
        
        % 2. Run nBias permutations for this specific dataset
        for iter = 1:nBias
            
            % Generate shuffled data
            DataA = zeros(nCh, nSamples);
            DataB = zeros(nCh, nSamples);
            for c = 1:nCh
                DataA(c, :) = bootData(c, randperm(nSamples));
                DataB(c, :) = bootData(c, randperm(nSamples));
            end
            
            % Compute Upper Triangle
            for i = 1:nCh
                X = DataA(i, :)';
                for j = i:nCh
                    Y = DataB(j, :)';
                    
                    % Compute MI
                    [mi_vals, ~] = MIcorr(X, Y, k, maxLagSamples);
                    
                    % Accumulate (Upper)
                    bias_accumulator(i, j, :) = squeeze(bias_accumulator(i, j, :))' + mi_vals;
                    
                    % Accumulate (Lower - Symmetry)
                    if i ~= j
                         bias_accumulator(j, i, :) = squeeze(bias_accumulator(j, i, :))' + flip(mi_vals);
                    end
                end
            end
            
            progressbar([], iter/nBias);
        end
        
        % Average the accumulated bias for this bootstrap
        MI_bias_boot(b, :, :, :) = bias_accumulator / nBias;
        
        progressbar(b/nBoot, []);
        fprintf('Done in %.2fs\n', toc(tBoot));
    end
    
    progressbar(1);
    
    BiasStruct.vals = MI_bias_boot;
    BiasStruct.lags = lags;
    BiasStruct.params.k = k;
    BiasStruct.params.nBias = nBias;
    BiasStruct.params.nBoot = nBoot;
    
    fprintf('✅ Matched Bias Estimation Done: %.2fs\n', toc(tTotal));
end