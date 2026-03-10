function [BiasStruct] = MI_EstimateBias(signal, maxLagSec, k, nBias)
% MI_EstimateBias_Bare - Optimized for speed
    
    if nargin < 3, k = 3; end
    if nargin < 4, nBias = 10; end

    Fs = 256; 
    maxLagSamples = round(maxLagSec * Fs);
    lags = -maxLagSamples:maxLagSamples;
    nLags = length(lags);
    
    % Grand Average
    validSubjects = squeeze(all(all(~isnan(signal), 2), 3));
    avgData = squeeze(mean(signal(validSubjects, :, :), 1)); 
    [nCh, nSamples] = size(avgData);
    
    MI_bias_vals = zeros(nBias, nCh, nCh, nLags);
    
    fprintf('=== Bias Calc (Bare Metal) ===\n');
    tTotal = tic;

    for b = 1:nBias
        if mod(b, 10) == 0, fprintf('Bias %d/%d\n', b, nBias); end
        
        % Generate shuffled data (Vectorized shuffle is hard, loop is fine)
        DataA = zeros(nCh, nSamples);
        DataB = zeros(nCh, nSamples);
        for c = 1:nCh
            DataA(c, :) = avgData(c, randperm(nSamples));
            DataB(c, :) = avgData(c, randperm(nSamples));
        end
        
        % Loop Upper Triangle
        for i = 1:nCh
            X = DataA(i, :)';
            for j = i:nCh
                Y = DataB(j, :)';
                
                [mi_vals, ~] = MIcorr(X, Y, k, maxLagSamples);
                
                MI_bias_vals(b, i, j, :) = mi_vals;
                if i ~= j
                    MI_bias_vals(b, j, i, :) = flip(mi_vals);
                end
            end
        end
    end
    
    BiasStruct.mean = squeeze(mean(MI_bias_vals, 1, 'omitnan'));
    BiasStruct.vals = MI_bias_vals;
    BiasStruct.lags = lags;
    
    fprintf('✅ Bias Done: %.2fs\n', toc(tTotal));
end