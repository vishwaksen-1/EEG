function integral_struct = compute_crosscorr_integrals_v3(results, bias_results)
% compute_crosscorr_integrals_v3 - Calculate integrated strength (Active vs Bias)
%   and plot heatmaps for the 3 stims.
%
% Usage:
%   out = compute_crosscorr_integrals_v3(results, bias_results)
%
% Logic:
%   1. Matches bias length to active (central crop).
%   2. Masks if CI crosses zero OR CI overlaps with Bias CI.
%   3. Sums the valid values over all lags (Integral).
%   4. Generates a heatmap figure for each stim.

    integral_struct = struct();
    outNames = fieldnames(results); % Dynamic field names (e.g., Out12, Out34)

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        % Check if bias exists for this Out field
        if ~isfield(bias_results, outName)
            warning('Bias missing for %s. Skipping.', outName);
            continue;
        end

        % Get stim names
        stimNames = fieldnames(results.(outName));
        stimNames = stimNames(contains(stimNames, 'stim') | contains(stimNames, 'seg'));
        stimNames = stimNames(~contains(stimNames, 'raw'));

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            
            % --- 1. Extract Data ---
            % Active
            resS = results.(outName).(stimName).corr;
            mu_A = resS.mean; 
            sd_A = resS.std;
            lags = resS.lags;
            
            % Bias (Full)
            if isfield(bias_results.(outName), stimName)
                biasS = bias_results.(outName).(stimName);
                mu_Bias_Full = biasS.mean;
                sd_Bias_Full = biasS.std;
                
                % Get Channel Names (prefer Bias labels)
                if isfield(biasS, 'regionLabels')
                    chNames = biasS.regionLabels;
                elseif isfield(biasS, 'region labels')
                    chNames = biasS.('region labels');
                elseif isfield(results.(outName), 'channels')
                    chNames = results.(outName).channels;
                else
                    nCh = size(mu_A, 1);
                    chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
                end
            else
                warning('Bias data missing for %s inside %s.', stimName, outName);
                continue;
            end
            
            [nCh, ~, nLagsA] = size(mu_A);
            
            % --- 2. Prep Data: Bias to Active Match ---
            [mu_Bias_A, sd_Bias_A] = crop_center(mu_Bias_Full, sd_Bias_Full, nLagsA);
            
            % --- 3. CALC: Full Integral (Active vs Bias only) ---
            % Mask: ZeroCrossing OR BiasOverlap
            mask_Full = get_exclusion_mask(mu_A, sd_A, mu_Bias_A, sd_Bias_A); 
            
            val_Full = mu_A;
            val_Full(mask_Full) = 0; % Zero out invalid
            
            % Integral = Sum over lags (dim 3)
            % Multiply by dt (lag step) if physical units are needed, 
            % but 'sum' is standard for "strength".
            int_Full = sum(val_Full, 3, 'omitnan');
            
            % Zero out diagonal (self-correlation integral is usually not interesting)
            int_Full(logical(eye(nCh))) = 0;

            % --- 4. Store ---
            integral_struct.(outName).(stimName).full_integral = int_Full;
            
            % --- 5. Plot Heatmap ---
            figure('Name', sprintf('%s - %s', outName, stimName), 'Color', 'w');
            imagesc(int_Full);
            colormap(jet);
            colorbar;
            
            % Aesthetics
            % clim([-17 17]); % for visual
            % clim([-17 25]); % for audio - passive
            clim([-20 20]); % audio - active
            
            title(sprintf('%s: %s\nIntegrated Cross-Correlation (Active vs Bias)', outName, stimName), 'Interpreter', 'none');
            xlabel('Target Channel');
            ylabel('Source/Ref Channel');
            
            xticks(1:nCh); xticklabels(chNames); xtickangle(45);
            yticks(1:nCh); yticklabels(chNames);
            
            axis square;
            grid on;
            
            fprintf('Computed and plotted: %s - %s\n', outName, stimName);
        end
    end
    fprintf('✅ Finished computing integrals (V3).\n');
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
    
    % CI Main (Mean +/- 1.96 * Std)
    ci_m_lo = mu_main - 1.96 * sd_main;
    ci_m_hi = mu_main + 1.96 * sd_main;
    
    % CI Ref
    ci_r_lo = mu_ref - 1.96 * sd_ref;
    ci_r_hi = mu_ref + 1.96 * sd_ref;
    
    % 1. Zero Crossing Logic
    % If lower bound is <= 0 AND upper bound is >= 0, then 0 is inside the interval.
    % This implies signs are opposite (or one is zero).
    mask_zero = (ci_m_lo <= 0) & (ci_m_hi >= 0);
    
    % 2. Overlap Logic
    % Overlap exists if (Start1 <= End2) and (End1 >= Start2)
    mask_overlap = (ci_m_lo <= ci_r_hi) & (ci_m_hi >= ci_r_lo);
    
    mask = mask_zero | mask_overlap;
end