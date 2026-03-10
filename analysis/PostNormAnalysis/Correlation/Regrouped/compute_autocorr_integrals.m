function auto_struct = compute_autocorr_integrals(results, bias_results)
% compute_autocorr_integrals - Calculate integrated strength for 
% AUTOCORRELATIONS (diagonal elements) against bias with CI error bars.
%
% Usage:
%   out = compute_autocorr_integrals(results, bias_results)
%
% Logic:
%   1. Matches bias length to active (central crop).
%   2. Masks if CI crosses zero OR CI overlaps with Bias CI.
%   3. Sums valid values over all lags (Integral).
%   4. Sums variances of valid values to propagate error.
%   5. Extracts the DIAGONAL (autocorrelation).
%   6. Plots a bar chart of the Autocorrelation Integrals with CI error bars.

    auto_struct = struct();
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
            mu_A = resS.mean; 
            sd_A = resS.std;
            
            if isfield(bias_results.(outName), stimName)
                biasS = bias_results.(outName).(stimName);
                % biasS = bias_results.(outName).(stimName).bias;
                mu_Bias_Full = biasS.mean;
                sd_Bias_Full = biasS.std;
                
                % Get Channel Names
                if isfield(biasS, 'regionLabels')
                    chNames = biasS.regionLabels;
                elseif isfield(results.(outName), 'channels')
                    chNames = results.(outName).channels;
                else
                    nCh = size(mu_A, 1);
                    chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
                end
                % chNames = biasS.params.regions;
            else
                continue;
            end
            
            nCh = size(mu_A, 1);
            nLagsA = size(mu_A, 3);
            
            % --- 2. Prep Data: Bias to Active Match ---
            [mu_Bias_A, sd_Bias_A] = crop_center(mu_Bias_Full, sd_Bias_Full, nLagsA);
            
            % --- 3. CALC: Full Integral & Error Propagation ---
            mask_Full = get_exclusion_mask(mu_A, sd_A, mu_Bias_A, sd_Bias_A); 
            
            val_Full = mu_A;
            val_Full(mask_Full) = 0; % Zero out invalid overlaps/non-significant
            
            int_Full = sum(val_Full, 3, 'omitnan');
            
            % Propagate error: sqrt(sum(variance)) for the valid data points
            var_Full = sd_A.^2;
            var_Full(mask_Full) = 0; % Do not add variance for masked points
            sd_int_Full = sqrt(sum(var_Full, 3, 'omitnan'));
            
            % --- 4. EXTRACT DIAGONAL (Autocorrelation) ---
            auto_int = diag(int_Full);
            auto_sd  = diag(sd_int_Full);
            auto_ci  = 1.96 * auto_sd; % 95% Confidence Interval for the integral
            
            auto_struct.(outName).(stimName).autocorr_integral = auto_int;
            auto_struct.(outName).(stimName).autocorr_ci = auto_ci; % Save the CI to the struct
            
            % --- 5. Plot Bar Chart ---
            figure('Name', sprintf('%s - %s Autocorrelation', outName, stimName), 'Color', 'w');
            
            hold on;
            % Plot the bars
            bar(1:nCh, auto_int, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k');
            
            % Plot the error bars (CI)
            errorbar(1:nCh, auto_int, auto_ci, 'k', 'LineStyle', 'none', ...
                     'LineWidth', 1.5, 'CapSize', 8);
            hold off;
            
            title(sprintf('%s: %s\nIntegrated Autocorrelation ([Passive-Active] vs Bias)', outName, stimName), 'Interpreter', 'none');
            ylabel('Integrated Valid Correlation');
            
            xticks(1:nCh); 
            xticklabels(chNames); 
            xtickangle(45);
            grid on;
            ylim([0 350]);
            fprintf('Computed autocorr integral for: %s - %s\n', outName, stimName);
        end
    end
    fprintf('✅ Finished computing autocorrelation integrals.\n');
end

% ================= HELPER FUNCTIONS =================

function [mu_out, sd_out] = crop_center(mu_in, sd_in, targetLen)
    currLen = size(mu_in, 3);
    if currLen > targetLen
        diff = currLen - targetLen;
        startIdx = floor(diff / 2) + 1;
        indices = startIdx : (startIdx + targetLen - 1);
        mu_out = mu_in(:, :, indices);
        sd_out = sd_in(:, :, indices);
    elseif currLen < targetLen
        mu_out = mu_in;
        sd_out = sd_in;
    else
        mu_out = mu_in;
        sd_out = sd_in;
    end
end

function mask = get_exclusion_mask(mu_main, sd_main, mu_ref, sd_ref)
    ci_m_lo = mu_main - 1.96 * sd_main;
    ci_m_hi = mu_main + 1.96 * sd_main;
    
    ci_r_lo = mu_ref - 1.96 * sd_ref;
    ci_r_hi = mu_ref + 1.96 * sd_ref;
    
    mask_zero = (ci_m_lo <= 0) & (ci_m_hi >= 0);
    mask_overlap = (ci_m_lo <= ci_r_hi) & (ci_m_hi >= ci_r_lo);
    
    mask = mask_zero | mask_overlap;
end