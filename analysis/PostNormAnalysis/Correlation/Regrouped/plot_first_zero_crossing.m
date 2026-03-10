function zc_struct = plot_first_zero_crossing(results, bias_results)
% plot_first_zero_crossing - Find the first lag where the cross-correlation
% confidence interval contains zero OR overlaps with the bias CI, 
% moving outwards from lag 0.
%
% Usage:
%   zc_struct = plot_first_zero_crossing(results, bias_results)
%
% Generates an n x n heatmap for positive lags (>0) and negative lags (<0).
% Missing crossings (remains valid across all lags) are plotted as gray cells.

    zc_struct = struct();
    outNames = fieldnames(results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        if ~isfield(bias_results, outName)
            warning('Bias missing for %s. Skipping.', outName);
            continue;
        end

        stimNames = fieldnames(results.(outName));
        stimNames = stimNames(contains(stimNames, 'stim') | contains(stimNames, 'seg'));
        stimNames = stimNames(~contains(stimNames, 'raw'));

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            
            % --- 1. Extract Data ---
            resS = results.(outName).(stimName).corr;
            mu = resS.mean; 
            std_val = resS.std;
            lags = resS.lags;
            
            if isfield(bias_results.(outName), stimName)
                biasS = bias_results.(outName).(stimName);
                mu_Bias_Full = biasS.mean;
                sd_Bias_Full = biasS.std;
                
                % Get Channel Names (prefer Bias labels)
                if isfield(biasS, 'regionLabels')
                    chNames = biasS.regionLabels;
                elseif isfield(results.(outName), 'channels')
                    chNames = results.(outName).channels;
                else
                    nCh = size(mu, 1);
                    chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
                end
            else
                warning('Bias data missing for %s inside %s.', stimName, outName);
                continue;
            end
            
            nCh = size(mu, 1);
            nLagsA = size(mu, 3);
            
            % --- 2. Prep Data: Bias to Active Match ---
            [mu_Bias, sd_Bias] = crop_center(mu_Bias_Full, sd_Bias_Full, nLagsA);
            
            % --- 3. Calculate CI Zero-Crossing OR Bias-Overlap Mask ---
            % 1 if interval contains 0 OR overlaps with bias
            is_invalid = get_exclusion_mask(mu, std_val, mu_Bias, sd_Bias);
            
            % --- 4. Partition Lags (moving away from 0) ---
            % Positive Lags (Ascending: 0.01, 0.02, ...)
            idx_pos = find(lags > 0);
            [~, sort_pos] = sort(lags(idx_pos), 'ascend');
            idx_pos = idx_pos(sort_pos);
            
            % Negative Lags (Descending absolute value: -0.01, -0.02, ...)
            idx_neg = find(lags < 0);
            [~, sort_neg] = sort(lags(idx_neg), 'descend');
            idx_neg = idx_neg(sort_neg);
            
            ZC_pos = nan(nCh, nCh);
            ZC_neg = nan(nCh, nCh);
            
            % --- 5. Find First Invalid Crossing ---
            for i = 1:nCh
                for j = 1:nCh
                    % Positive search
                    invalid_arr_pos = squeeze(is_invalid(i, j, idx_pos));
                    first_pos = find(invalid_arr_pos, 1, 'first');
                    if ~isempty(first_pos)
                        ZC_pos(i,j) = lags(idx_pos(first_pos));
                    end
                    
                    % Negative search
                    invalid_arr_neg = squeeze(is_invalid(i, j, idx_neg));
                    first_neg = find(invalid_arr_neg, 1, 'first');
                    if ~isempty(first_neg)
                        ZC_neg(i,j) = abs(lags(idx_neg(first_neg))); % <--- Changed to absolute distance
                    end
                end
            end
            
            % Store in output struct
            zc_struct.(outName).(stimName).first_zc_pos = ZC_pos;
            zc_struct.(outName).(stimName).first_zc_neg = ZC_neg;
            
            % --- 6. Plotting ---
            figure('Name', sprintf('%s - %s Zero/Bias Crossings', outName, stimName), ...
                   'Color', 'w', 'Position', [100, 100, 1000, 450]);
               
            % Subplot 1: Positive Lags
            subplot(1, 2, 1);
            h1 = imagesc(ZC_pos);
            set(h1, 'AlphaData', ~isnan(ZC_pos)); % Make NaNs transparent
            set(gca, 'Color', [0.8 0.8 0.8]);     % Gray background for NaNs
            colormap(gca, parula);
            colorbar;
            clim([0 0.15])
            title(sprintf('First Invalid Crossing (Lag > 0)\n%s: %s', outName, stimName), 'Interpreter', 'none');
            xlabel('Target Channel'); ylabel('Source/Ref Channel');
            xticks(1:nCh); xticklabels(chNames); xtickangle(45);
            yticks(1:nCh); yticklabels(chNames);
            axis square; grid on;
            
            % Subplot 2: Negative Lags
            subplot(1, 2, 2);
            h2 = imagesc(ZC_neg);
            set(h2, 'AlphaData', ~isnan(ZC_neg)); 
            set(gca, 'Color', [0.8 0.8 0.8]);
            colormap(gca, parula); % <--- Removed flipud since values are now distances > 0
            colorbar;
            clim([0 0.15])
            title(sprintf('First Invalid Crossing Distance (Lag < 0)\n%s: %s', outName, stimName), 'Interpreter', 'none');
            xlabel('Target Channel'); ylabel('Source/Ref Channel');
            xticks(1:nCh); xticklabels(chNames); xtickangle(45);
            yticks(1:nCh); yticklabels(chNames);
            axis square; grid on;
            
            fprintf('Computed first invalid crossings (Zero or Bias) for: %s - %s\n', outName, stimName);
        end
    end
    fprintf('✅ Finished plotting all first crossings.\n');
end

% ================= HELPER FUNCTIONS =================

function [mu_out, sd_out] = crop_center(mu_in, sd_in, targetLen)
    % Crops input (dim 3) to match targetLen at the center
    currLen = size(mu_in, 3);
    if currLen > targetLen
        diff = currLen - targetLen;
        startIdx = floor(diff / 2) + 1;
        indices = startIdx : (startIdx + targetLen - 1);
        mu_out = mu_in(:, :, indices);
        sd_out = sd_in(:, :, indices);
    elseif currLen < targetLen
        warning('Input length (%d) < Target (%d). Returning original.', currLen, targetLen);
        mu_out = mu_in;
        sd_out = sd_in;
    else
        mu_out = mu_in;
        sd_out = sd_in;
    end
end

function mask = get_exclusion_mask(mu_main, sd_main, mu_ref, sd_ref)
    % Returns true if Main crosses zero OR Main overlaps Ref
    
    ci_m_lo = mu_main - 1.96 * sd_main;
    ci_m_hi = mu_main + 1.96 * sd_main;
    
    ci_r_lo = mu_ref - 1.96 * sd_ref;
    ci_r_hi = mu_ref + 1.96 * sd_ref;
    
    % 1. Zero Crossing Logic
    mask_zero = (ci_m_lo <= 0) & (ci_m_hi >= 0);
    
    % 2. Overlap Logic
    mask_overlap = (ci_m_lo <= ci_r_hi) & (ci_m_hi >= ci_r_lo);
    
    mask = mask_zero | mask_overlap;
end