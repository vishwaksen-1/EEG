function integral_struct = compute_crosscorr_integrals(results, bias_results, baseline_results)
% compute_crosscorr_integrals - Calculate integrated strength of valid correlations.
%
% Usage:
%   out = compute_crosscorr_integrals(results, bias_results, baseline_results)
%
% Outputs per stim:
%   1. full_integral: Active vs Bias (All lags)
%   2. central_active_bias_integral: Active vs Bias (Central 0.5s)
%   3. central_baseline_integral: Baseline vs Bias (Central 0.5s)
%   4. central_active_bias_baseline_integral: Active vs Bias & Baseline (Central 0.5s)
%   5. diff_integral: (2) - (3)
%
% Logic:
%   - Matches bias length to active (central crop).
%   - Matches active/bias length to baseline (central crop) for central comparison.
%   - Computes masks and integrals.
%   - Prints 5 outputs to console.

    integral_struct = struct();
    outNames = {'Out12', 'Out34'};

    for o = 1:numel(outNames)
        outName = outNames{o};
        if ~isfield(results, outName), continue; end

        % Get stim names
        stimNames = fieldnames(results.(outName));
        stimNames = stimNames(contains(stimNames, 'stim') | contains(stimNames, 'seg'));
        stimNames = stimNames(~contains(stimNames, 'raw'));

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            
            % --- 1. Identify Baseline Field ---
            bStimName = '';
            if contains(outName, '12')
                if contains(stimName, 'stim1'), bStimName = 'stim_1';
                elseif contains(stimName, 'stim2'), bStimName = 'stim_2'; end
            elseif contains(outName, '34')
                if contains(stimName, 'stim1'), bStimName = 'stim_3';
                elseif contains(stimName, 'stim2'), bStimName = 'stim_4'; end
            end

            % --- 2. Extract Data ---
            % Active
            resS = results.(outName).(stimName).corr;
            mu_A = resS.mean; % [nCh x nCh x nLags]
            sd_A = resS.std;
            
            % Bias (Full)
            biasS = bias_results.(outName).(stimName);
            mu_Bias_Full = biasS.mean;
            sd_Bias_Full = biasS.std;
            
            % Baseline (if available)
            hasBase = ~isempty(bStimName) && isfield(baseline_results, bStimName);
            if hasBase
                resB = baseline_results.(bStimName).corr;
                mu_Base = resB.mean; % [nCh x nCh x nLagsBase]
                sd_Base = resB.std;
            else
                mu_Base = []; sd_Base = [];
            end
            
            [nCh, ~, nLagsA] = size(mu_A);
            
            % --- 3. Prep Data: Bias to Active Match (Full) ---
            [mu_Bias_A, sd_Bias_A] = crop_center(mu_Bias_Full, sd_Bias_Full, nLagsA);
            
            % --- 4. CALC 1: Full Integral (Active vs Bias only) ---
            mask_Full = get_exclusion_mask(mu_A, sd_A, mu_Bias_A, sd_Bias_A); 
            val_Full = mu_A;
            val_Full(mask_Full) = 0;
            int_Full = sum(val_Full, 3, 'omitnan');
            
            % --- 5. Prep Data: Central Segment Calculations ---
            int_Cent_A_Bias = nan(nCh, nCh);
            int_Cent_B      = nan(nCh, nCh);
            int_Cent_A_All  = nan(nCh, nCh);
            int_Diff        = nan(nCh, nCh);
            
            if hasBase
                nLagsBase = size(mu_Base, 3);
                
                % Crop Active & Bias to match Baseline length
                [mu_A_Cent, sd_A_Cent] = crop_center(mu_A, sd_A, nLagsBase);
                [mu_Bias_Cent, sd_Bias_Cent] = crop_center(mu_Bias_Full, sd_Bias_Full, nLagsBase);
                
                % --- CALC 2: Central Active vs Bias (No Baseline exclusion) ---
                mask_AB = get_exclusion_mask(mu_A_Cent, sd_A_Cent, mu_Bias_Cent, sd_Bias_Cent);
                val_A_Cent_Bias = mu_A_Cent;
                val_A_Cent_Bias(mask_AB) = 0;
                int_Cent_A_Bias = sum(val_A_Cent_Bias, 3, 'omitnan');

                % --- CALC 3: Central Baseline vs Bias ---
                mask_B = get_exclusion_mask(mu_Base, sd_Base, mu_Bias_Cent, sd_Bias_Cent);
                val_B_Cent = mu_Base;
                val_B_Cent(mask_B) = 0;
                int_Cent_B = sum(val_B_Cent, 3, 'omitnan');

                % --- CALC 4: Central Active vs Bias & Baseline ---
                % Combine mask_AB with Baseline Overlap mask
                mask_Base = get_overlap_mask(mu_A_Cent, sd_A_Cent, mu_Base, sd_Base);
                final_mask_A = mask_AB | mask_Base;
                val_A_Cent_All = mu_A_Cent;
                val_A_Cent_All(final_mask_A) = 0;
                int_Cent_A_All = sum(val_A_Cent_All, 3, 'omitnan');

                % --- CALC 5: Difference (2 - 3) ---
                int_Diff = int_Cent_A_Bias - int_Cent_B;
            end
            
            % --- Store ---
            integral_struct.(outName).(stimName).full_integral = int_Full;
            integral_struct.(outName).(stimName).central_active_bias_integral = int_Cent_A_Bias;
            integral_struct.(outName).(stimName).central_baseline_integral = int_Cent_B;
            integral_struct.(outName).(stimName).central_active_bias_baseline_integral = int_Cent_A_All;
            integral_struct.(outName).(stimName).diff_integral = int_Diff;
            
            % --- Print to Console ---
            fprintf('\n==========================================================\n');
            fprintf('Integrals: %s | %s\n', outName, stimName);
            fprintf('==========================================================\n');
            
            fprintf('1. Full Integral (Active vs Bias):\n');
            disp(int_Full);
            
            if hasBase
                fprintf('2. Central Integral (Active vs Bias):\n');
                disp(int_Cent_A_Bias);
                
                fprintf('3. Central Integral (Baseline vs Bias):\n');
                disp(int_Cent_B);
                
                fprintf('4. Central Integral (Active vs Bias & Baseline):\n');
                disp(int_Cent_A_All);
                
                fprintf('5. Difference (2 - 3):\n');
                disp(int_Diff);
            else
                fprintf('2-5. Central Integrals: [Skipped - Baseline Missing]\n');
            end
            fprintf('\n');
        end
    end
    fprintf('✅ Finished computing and printing integrals.\n');
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
    
    % CI Main
    ci_m_lo = mu_main - 1.96 * sd_main;
    ci_m_hi = mu_main + 1.96 * sd_main;
    
    % CI Ref
    ci_r_lo = mu_ref - 1.96 * sd_ref;
    ci_r_hi = mu_ref + 1.96 * sd_ref;
    
    % 1. Zero Crossing
    mask_zero = (ci_m_lo <= 0) & (ci_m_hi >= 0);
    
    % 2. Overlap
    % Overlap exists if (Start1 <= End2) and (End1 >= Start2)
    mask_overlap = (ci_m_lo <= ci_r_hi) & (ci_m_hi >= ci_r_lo);
    
    mask = mask_zero | mask_overlap;
end

function mask = get_overlap_mask(mu_main, sd_main, mu_ref, sd_ref)
    % Returns true ONLY if Main overlaps Ref (Checking difference)
    
    ci_m_lo = mu_main - 1.96 * sd_main;
    ci_m_hi = mu_main + 1.96 * sd_main;
    
    ci_r_lo = mu_ref - 1.96 * sd_ref;
    ci_r_hi = mu_ref + 1.96 * sd_ref;
    
    mask = (ci_m_lo <= ci_r_hi) & (ci_m_hi >= ci_r_lo);
end