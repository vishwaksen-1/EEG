function plot_crosscorr_results(results, bias_results)
% plot_crosscorr_results - Display cross-correlation with bias correction
%
% Usage:
%   plot_crosscorr_results(results, bias_results)
%
% Inputs:
%   results      : Main struct (OutXX -> stimXX_subTrialNorm -> corr -> mean/std)
%   bias_results : Bias struct (OutXX -> stimXX_subTrialNorm -> mean/std)
%
% Logic:
%   1. Crops Bias data to match Correlation data length (central crop).
%   2. Masks pixels where CrossCorr CI crosses 0.
%   3. Masks pixels where CrossCorr CI overlaps with Bias CI.
%   4. Masked value = 0.

    outNames = fieldnames(results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        if ~isfield(bias_results, outName)
            warning('Field %s not found in bias_results. Skipping.', outName);
            continue;
        end

        stimNames = fieldnames(results.(outName));
        % stimNames = stimNames(contains(stimNames, 'stim') | contains(stimNames, 'seg'));
        % stimNames = stimNames(~contains(stimNames, 'raw'));
        
        fprintf('\n=== Dataset: %s ===\n', outName);

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            
            if ~isfield(bias_results.(outName), stimName)
                warning('Stimulus %s not found in bias_results.%s. Skipping.', stimName, outName);
                continue;
            end

            % --- Extract Data ---
            resStruct = results.(outName).(stimName).corr;
            meanCorr  = resStruct.mean; % [nCh x nCh x nLags]
            stdCorr   = resStruct.std;
            lags      = resStruct.lags;
            
            biasStruct = bias_results.(outName).(stimName);
            meanBias   = biasStruct.mean; % [nCh x nCh x nBiasLags]
            stdBias    = biasStruct.std;
            
            % --- Fix Bias Length (Central Crop) ---
            nLagsCorr = size(meanCorr, 3);
            nLagsBias = size(meanBias, 3);
            
            if nLagsBias > nLagsCorr
                diff = nLagsBias - nLagsCorr;
                startIdx = floor(diff / 2) + 1;
                indices = startIdx : (startIdx + nLagsCorr - 1);
                
                meanBias = meanBias(:, :, indices);
                stdBias  = stdBias(:, :, indices);
                % fprintf('  (Cropped bias from %d to %d points for %s)\n', nLagsBias, nLagsCorr, stimName);
            elseif nLagsBias < nLagsCorr
                 warning('Bias length (%d) is shorter than Correlation length (%d). Masking may fail.', nLagsBias, nLagsCorr);
            end
            
            % Get Channel Names
            nCh = size(meanCorr, 1);
            if isfield(biasStruct, 'regionLabels')
                chNames = biasStruct.regionLabels;
            elseif isfield(biasStruct, 'region labels')
                chNames = biasStruct.('region labels');
            elseif isfield(results.(outName), 'channels')
                chNames = results.(outName).channels;
            else
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end

            fprintf('  > Stimulus: %s\n', stimName);

            for i = 1:nCh
                figure('Color','w');
                
                mu_c = squeeze(meanCorr(i,:,:)); 
                sd_c = squeeze(stdCorr(i,:,:));
                mu_b = squeeze(meanBias(i,:,:));
                sd_b = squeeze(stdBias(i,:,:));

                plotData = apply_bias_mask(mu_c, sd_c, mu_b, sd_b);
                plotData(i,:) = NaN; 

                imagesc(lags, 1:nCh, plotData);
                set(gca, 'YDir', 'normal');
                colormap(jet);
                colorbar;
                clim([-1 1]); 

                title(sprintf('%s — %s\nCrosscorr: %s vs all (Masked=0)', ...
                      outName, stimName, chNames{i}), 'Interpreter', 'none');
                xlabel('Lag (s)');
                ylabel('Channel');
                yticks(1:nCh);
                yticklabels(chNames);

                fprintf('    Showing %s vs all — press any key for next...\n', chNames{i});
                pause;
            end
            close all;
        end
    end
    fprintf('\n✅ Finished plotting all cross-correlations.\n');
end

function maskedData = apply_bias_mask(mu_c, sd_c, mu_b, sd_b)
    ci_c_low = mu_c - 1.96 * sd_c;
    ci_c_high = mu_c + 1.96 * sd_c;
    
    ci_b_low = mu_b - 1.96 * sd_b;
    ci_b_high = mu_b + 1.96 * sd_b;

    mask_zero = (ci_c_low <= 0) & (ci_c_high >= 0);
    mask_overlap = (ci_c_low <= ci_b_high) & (ci_c_high >= ci_b_low);

    final_mask = mask_zero | mask_overlap;

    maskedData = mu_c;
    maskedData(final_mask) = 0;
end