function diff_struct = compare_crosscorr_diff(res1, bias1, res2, bias2, label1, label2)
% compare_crosscorr_diff - Compare the integrated difference between two datasets.
%
% Usage:
%   out = compare_crosscorr_diff(results1, bias_results1, results2, bias_results2, 'Active', 'Passive')
%
% Logic:
%   1. Calculates lag-wise difference: mu_diff = mu1 - mu2
%   2. Propagates standard error: sd_diff = sqrt(sd1^2 + sd2^2)
%   3. Calculates bias difference: mu_b_diff = mu_b1 - mu_b2
%   4. Masks mu_diff if its CI crosses zero OR overlaps with the bias difference CI.
%   5. Integrates the significant differences over all lags.
%   6. Plots heatmaps of the valid differences.

    if nargin < 5
        label1 = 'Condition 1';
        label2 = 'Condition 2';
    end

    diff_struct = struct();
    outNames = fieldnames(res1);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        if ~isfield(res2, outName) || ~isfield(bias1, outName) || ~isfield(bias2, outName)
            warning('Missing matching data for %s. Skipping.', outName);
            continue;
        end

        stimNames = fieldnames(res1.(outName));
        stimNames = stimNames(contains(stimNames, 'stim') | contains(stimNames, 'seg'));
        stimNames = stimNames(~contains(stimNames, 'raw'));

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            
            if ~isfield(res2.(outName), stimName)
                continue;
            end

            % --- 1. Extract Data ---
            mu1 = res1.(outName).(stimName).corr.mean;
            sd1 = res1.(outName).(stimName).corr.std;
            
            mu2 = res2.(outName).(stimName).corr.mean;
            sd2 = res2.(outName).(stimName).corr.std;

            mu_b1_full = bias1.(outName).(stimName).mean;
            sd_b1_full = bias1.(outName).(stimName).std;
            
            mu_b2_full = bias2.(outName).(stimName).mean;
            sd_b2_full = bias2.(outName).(stimName).std;

            % --- 2. Match Lengths ---
            nLags = min(size(mu1, 3), size(mu2, 3));
            [mu1, sd1] = crop_center(mu1, sd1, nLags);
            [mu2, sd2] = crop_center(mu2, sd2, nLags);
            
            [mu_b1, sd_b1] = crop_center(mu_b1_full, sd_b1_full, nLags);
            [mu_b2, sd_b2] = crop_center(mu_b2_full, sd_b2_full, nLags);

            % --- 3. Compute Differences & Propagate Error ---
            % Assumes independence between condition 1 and condition 2
            mu_diff = mu1 - mu2;
            sd_diff = sqrt(sd1.^2 + sd2.^2);
            
            mu_b_diff = mu_b1 - mu_b2;
            sd_b_diff = sqrt(sd_b1.^2 + sd_b2.^2);

            % --- 4. Apply Masks to the Difference ---
            % Mask out where the difference CI crosses 0 or overlaps with bias diff CI
            mask_diff = get_exclusion_mask(mu_diff, sd_diff, mu_b_diff, sd_b_diff);
            
            val_diff = mu_diff;
            val_diff(mask_diff) = 0; % Zero out invalid differences

            % --- 5. Integrate ---
            int_diff = sum(val_diff, 3, 'omitnan');
            
            % Zero out self-correlation difference (diagonal)
            nCh = size(int_diff, 1);
            int_diff(logical(eye(nCh))) = 0;

            % --- 6. Store and Plot ---
            diff_struct.(outName).(stimName).diff_integral = int_diff;
            
            % Get Channel Names
            if isfield(bias1.(outName).(stimName), 'regionLabels')
                chNames = bias1.(outName).(stimName).regionLabels;
            elseif isfield(res1.(outName), 'channels')
                chNames = res1.(outName).channels;
            else
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end

            figure('Name', sprintf('%s - %s Difference', outName, stimName), 'Color', 'w');
            imagesc(int_diff);
            
            % Jet colormap and fixed [-17 17] scale matching v3
            colormap(jet); 
            colorbar;
            clim([-17 17]); 
            
            title(sprintf('%s: %s\nIntegrated Diff (%s - %s)', outName, stimName, label1, label2), 'Interpreter', 'none');
            xlabel('Target Channel');
            ylabel('Source/Ref Channel');
            
            xticks(1:nCh); xticklabels(chNames); xtickangle(45);
            yticks(1:nCh); yticklabels(chNames);
            
            axis square;
            grid on;
            
            fprintf('Computed and plotted difference for: %s - %s\n', outName, stimName);
        end
    end
    fprintf('✅ Finished computing integrated differences.\n');
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
    
    % 1. Zero Crossing Logic for the Difference
    mask_zero = (ci_m_lo <= 0) & (ci_m_hi >= 0);
    
    % 2. Overlap Logic (Diff vs Bias Diff)
    mask_overlap = (ci_m_lo <= ci_r_hi) & (ci_m_hi >= ci_r_lo);
    
    mask = mask_zero | mask_overlap;
end