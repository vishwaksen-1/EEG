function integral_struct = compute_MI_integrals(results)
% compute_MI_integrals - Calculate integrated MI strength (Median, CI-masked)
%
% Usage:
%   out = compute_MI_integrals(results)
%
% Logic:
%   1. Extracts 50 bootstraps.
%   2. Computes Median (Signal) and 2.5/97.5 Percentiles (CI).
%   3. Masks pixels where CI crosses zero (Lower <= 0 & Upper >= 0).
%   4. Sums the valid values over all lags (Integral).
%   5. Generates a heatmap figure for each stim/seg.

    integral_struct = struct();
    outNames = fieldnames(results); 

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        % Get stim/seg names
        subFields = fieldnames(results.(outName));
        dataFields = subFields(contains(subFields, 'stim') | contains(subFields, 'seg'));
        dataFields = dataFields(~contains(dataFields, 'raw'));
        
        % Check for labels
        if isfield(results.(outName), 'regionLabels')
            regLabels = results.(outName).regionLabels;
        elseif isfield(results.(outName), 'region_labels')
             regLabels = results.(outName).region_labels;
        else
            % Attempt to guess size from first data field
             tempDat = results.(outName).(dataFields{1}).vals;
             nReg = size(tempDat, 2);
             regLabels = arrayfun(@(x) sprintf('Reg%d', x), 1:nReg, 'UniformOutput', false);
        end
        nReg = length(regLabels);

        for s = 1:numel(dataFields)
            fName = dataFields{s};
            
            % --- 1. Extract Data ---
            % vals: [50 x nReg x nReg x nLags]
            boot_vals = results.(outName).(fName).vals;
            
            % --- 2. Statistics ---
            mi_median = squeeze(median(boot_vals, 1));
            ci_low    = squeeze(prctile(boot_vals, 2.5, 1));
            ci_high   = squeeze(prctile(boot_vals, 97.5, 1));
            
            % --- 3. Masking (Zero Crossing) ---
            % Mask if 0 is inside the CI range
            mask = (ci_low <= 0) & (ci_high >= 0);
            
            valid_mi = mi_median;
            valid_mi(mask) = 0; % Zero out non-significant
            
            % --- 4. Integral ---
            % Sum over lags (dim 3)
            int_MI = sum(valid_mi, 3, 'omitnan');
            
            % Zero out diagonal (Auto-MI integral is huge, suppresses contrast)
            int_MI(logical(eye(nReg))) = 0;

            % --- 5. Store ---
            integral_struct.(outName).(fName).full_integral = int_MI;
            
            % --- 6. Plot Heatmap ---
            figure('Name', sprintf('%s - %s Integral', outName, fName), 'Color', 'w');
            imagesc(int_MI);
            clim([0 800]);  % for audio
            % clim([0 1400]); % for visual
            colormap(jet);
            colorbar;
            
            title(sprintf('%s: %s\nIntegrated Mutual Information (Significant)', outName, fName), 'Interpreter', 'none');
            xlabel('Target Region');
            ylabel('Source Region');
            
            xticks(1:nReg); xticklabels(regLabels); xtickangle(45);
            yticks(1:nReg); yticklabels(regLabels);
            
            axis square;
            grid on;
            
            fprintf('Computed integral: %s - %s\n', outName, fName);
        end
    end
    fprintf('✅ Finished computing MI integrals.\n');
end