function integral_struct = compute_resting_integrals(results, bias_results)
% compute_resting_integrals - Calculate integrated strength for Resting State.
%   Adapts the logic of compute_crosscorr_integrals_v3 for the specific
%   hierarchy of resting state data:
%       results.(condition).set_1.corr
%       bias_results.(condition).set_1.bias
%
% Usage:
%   integrals = compute_resting_integrals(results, bias_results)
%
% Inputs:
%   results      : Output from computeBootstrappedRegionXCorr
%   bias_results : Output from computeBootstrappedRestingBias

    integral_struct = struct();
    conditions = {'eyesClosed', 'eyesOpen'};

    for i = 1:numel(conditions)
        condName = conditions{i};
        
        % --- 0. Structure Checks ---
        if ~isfield(results, condName)
            warning('Condition %s not found in results. Skipping.', condName);
            continue;
        end
        if ~isfield(bias_results, condName)
            warning('Condition %s not found in bias_results. Skipping.', condName);
            continue;
        end
        
        % Extract "Active" Correlation Data
        % Path: results.(cond).set_1.corr
        if isfield(results.(condName), 'set_1') && isfield(results.(condName).set_1, 'corr')
            resS = results.(condName).set_1.corr;
        else
            warning('Invalid structure for %s active data (expected .set_1.corr).', condName);
            continue;
        end
        
        mu_A = resS.mean; 
        sd_A = resS.std;
        
        % Extract Bias Data
        % Path: bias_results.(cond).set_1.bias
        if isfield(bias_results.(condName), 'bias')
            biasS = bias_results.(condName).bias;
        else
            warning('Invalid structure for %s bias data (expected .set_1.bias).', condName);
            continue;
        end
        
        mu_Bias_Full = biasS.mean;
        sd_Bias_Full = biasS.std;
        
        % Extract Labels (prefer from bias struct if available)
        if isfield(biasS.params, 'regions')
            chNames = biasS.params.regions;
        elseif isfield(resS.params, 'regions')
            chNames = resS.params.regions;
        else
            % Fallback
            chNames = {'L_Frontal','R_Frontal','L_Temporal','R_Temporal',...
                       'L_Parietal','R_Parietal','L_Occipital','R_Occipital'};
        end

        [nCh, ~, nLagsA] = size(mu_A);

        % --- 1. Prep Data: Bias to Active Match ---
        [mu_Bias_A, sd_Bias_A] = crop_center(mu_Bias_Full, sd_Bias_Full, nLagsA);

        % --- 2. CALC: Full Integral (Active vs Bias only) ---
        % Mask: ZeroCrossing OR BiasOverlap
        mask_Full = get_exclusion_mask(mu_A, sd_A, mu_Bias_A, sd_Bias_A); 

        val_Full = mu_A;
        val_Full(mask_Full) = 0; % Zero out invalid points
        
        % Integral = Sum over lags (dim 3)
        int_Full = sum(val_Full, 3, 'omitnan');
        
        % Zero out diagonal (Self-connectivity is usually ignored in this context)
        int_Full(logical(eye(nCh))) = 0;

        % --- 3. Store ---
        integral_struct.(condName).full_integral = int_Full;

        % --- 4. Plot Heatmap ---
        figure('Name', sprintf('RestingState - %s', condName), 'Color', 'w');
        imagesc(int_Full);
        colormap(jet);
        colorbar;

        % Aesthetics (Matching your previous scaling)
        clim([-20 20]); 
        
        title(sprintf('Resting State: %s\nIntegrated Connectivity (Significant vs Bias)', condName), 'Interpreter', 'none');
        xlabel('Target Region');
        ylabel('Source Region');
        
        xticks(1:nCh); xticklabels(chNames); xtickangle(45);
        yticks(1:nCh); yticklabels(chNames);
        
        axis square;
        grid on;
        
        fprintf('Computed and plotted: %s\n', condName);
    end
    fprintf('✅ Finished computing resting state integrals.\n');
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
    
    % CI Ref (Bias)
    ci_r_lo = mu_ref - 1.96 * sd_ref;
    ci_r_hi = mu_ref + 1.96 * sd_ref;
    
    % 1. Zero Crossing Logic
    % If lower bound <= 0 AND upper bound >= 0, then 0 is inside the interval.
    mask_zero = (ci_m_lo <= 0) & (ci_m_hi >= 0);
    
    % 2. Overlap Logic
    % Overlap exists if (Start1 <= End2) and (End1 >= Start2)
    mask_overlap = (ci_m_lo <= ci_r_hi) & (ci_m_hi >= ci_r_lo);
    
    mask = mask_zero | mask_overlap;
end