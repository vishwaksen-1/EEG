function compare_MI_integrals_groups(active_res, passive_res, visual_res)
% compare_MI_integrals_groups - Compare integrated MI between conditions
%
% Usage:
%   compare_MI_integrals_groups(active_res, passive_res, []) % Auditory only
%   compare_MI_integrals_groups([], [], visual_res)          % Visual only
%
% Logic:
%   1. For a given condition, masks insignificant lags (CI crosses 0).
%   2. Integrates (sums) the valid lags for EACH of the 50 bootstraps.
%   3. Subtracts the 50 bootstrapped integrals between two conditions.
%   4. Computes Median and 95% CI of the difference.
%   5. Masks the final difference plot if the CI crosses 0.

    % --- 1. Active vs Passive ---
    if ~isempty(active_res) && ~isempty(passive_res)
        fprintf('\n=== Comparing Active vs Passive Integrals ===\n');
        
        outNames = fieldnames(active_res);
        for o = 1:numel(outNames)
            outName = outNames{o};
            fNames = fieldnames(active_res.(outName));
            
            for f = 1:numel(fNames)
                fName = fNames{f};
                if ~isfield(passive_res.(outName), fName)
                    continue; 
                end
                if ~contains(fName, 'stim') && ~contains(fName, 'seg')
                    continue; 
                end
                
                % Get Labels
                labels = get_labels(active_res, outName, fName);
                
                % Compute Bootstrapped Integrals [50 x 8 x 8]
                boot_A = get_boot_integral(active_res.(outName).(fName).vals);
                boot_P = get_boot_integral(passive_res.(outName).(fName).vals);
                
                % Compute Difference Distribution
                Diff_boot = boot_A - boot_P;
                
                % Stats & Plot
                plot_diff_integral(Diff_boot, labels, ...
                    sprintf('%s: %s (Active - Passive) [Integral]', outName, fName));
            end
        end
        
        % --- 2. Periodic vs Aperiodic (Within Active & Passive) ---
        fprintf('\n=== Comparing Periodic vs Aperiodic Integrals ===\n');
        process_per_aper(active_res, 'Active');
        process_per_aper(passive_res, 'Passive');
    end
    
    % --- 3. Visual Segments ---
    if ~isempty(visual_res)
        fprintf('\n=== Comparing Visual Segments Integrals ===\n');
        
        outNames = fieldnames(visual_res); 
        outName = outNames{1};
        subFields = fieldnames(visual_res.(outName));
        dataFields = subFields(contains(subFields, 'seg'));
        
        labels = get_labels(visual_res, outName, dataFields{1});
        pairs = {{'seg1','seg2'}, {'seg2','seg3'}, {'seg1','seg3'}};
        
        for p = 1:numel(pairs)
            s1 = pairs{p}{1};
            s2 = pairs{p}{2};
            
            % Find exact field names matching the segment tag
            f1 = dataFields(contains(dataFields, s1));
            f2 = dataFields(contains(dataFields, s2));
            
            if ~isempty(f1) && ~isempty(f2)
                name1 = f1{1};
                name2 = f2{1};
                
                boot1 = get_boot_integral(visual_res.(outName).(name1).vals);
                boot2 = get_boot_integral(visual_res.(outName).(name2).vals);
                
                Diff_boot = boot1 - boot2;
                plot_diff_integral(Diff_boot, labels, ...
                    sprintf('Visual: %s - %s [Integral]', s1, s2));
            end
        end
    end
end

% ================= HELPER FUNCTIONS =================

function boot_int = get_boot_integral(vals)
    % vals: [50 x nReg x nReg x nLags]
    % 1. Find significant lags per region pair
    ci_lo = squeeze(prctile(vals, 2.5, 1));
    ci_hi = squeeze(prctile(vals, 97.5, 1));
    mask_zero = (ci_lo <= 0) & (ci_hi >= 0);
    
    % 2. Expand mask to apply to all 50 bootstraps
    % Reshape mask to [1 x 8 x 8 x lags]
    mask_4d = reshape(mask_zero, [1, size(mask_zero)]);
    
    % 3. Apply mask (Zero out non-significant lags for ALL bootstraps)
    valid_vals = vals;
    valid_vals(repmat(mask_4d, [size(vals, 1), 1, 1, 1])) = 0;
    
    % 4. Integrate (Sum over lags - dimension 4)
    boot_int = squeeze(sum(valid_vals, 4, 'omitnan')); % Output: [50 x 8 x 8]
end

function plot_diff_integral(Diff_boot, labels, titleStr)
    nReg = length(labels);
    
    % Stats of the Difference
    med_diff = squeeze(median(Diff_boot, 1, 'omitnan'));
    lo_diff  = squeeze(prctile(Diff_boot, 2.5, 1));
    hi_diff  = squeeze(prctile(Diff_boot, 97.5, 1));
    
    % Mask (Sig if 0 is NOT in CI)
    mask_sig = (lo_diff > 0) | (hi_diff < 0);
    
    valid_diff = med_diff;
    valid_diff(~mask_sig) = 0;           % Zero out non-significant differences
    valid_diff(logical(eye(nReg))) = 0;  % Zero out auto-MI (diagonal)
    
    % Plot
    figure('Color', 'w', 'Name', titleStr);
    imagesc(valid_diff);
    colormap(bluewhitered(256));
    colorbar;
    
    % Make color limits symmetric for difference plots
    max_val = max(abs(valid_diff(:)));
    if max_val == 0
        clim([-1 1]); % Fallback if perfectly 0
    else
        clim([-max_val max_val]);
    end
    
    title(sprintf('%s\n(Sig Difference Only)', titleStr), 'Interpreter', 'none');
    xlabel('Target Region'); 
    ylabel('Source Region');
    xticks(1:nReg); xticklabels(labels); xtickangle(45);
    yticks(1:nReg); yticklabels(labels);
    axis square; grid on;
end

function process_per_aper(res_struct, condName)
    outNames = fieldnames(res_struct);
    pairs = {{'stim1','stim2'}, {'stim3','stim4'}};
    
    for o = 1:numel(outNames)
        outName = outNames{o};
        fNames = fieldnames(res_struct.(outName));
        
        for p = 1:numel(pairs)
            tagPer = pairs{p}{1};
            tagAper = pairs{p}{2};
            
            idxPer = find(contains(fNames, tagPer), 1);
            idxAper = find(contains(fNames, tagAper), 1);
            
            if ~isempty(idxPer) && ~isempty(idxAper)
                namePer = fNames{idxPer};
                nameAper = fNames{idxAper};
                
                labels = get_labels(res_struct, outName, namePer);
                
                bootPer = get_boot_integral(res_struct.(outName).(namePer).vals);
                bootAper = get_boot_integral(res_struct.(outName).(nameAper).vals);
                
                Diff_boot = bootPer - bootAper;
                plot_diff_integral(Diff_boot, labels, ...
                    sprintf('%s %s: Per(%s) - Aper(%s) [Integral]', condName, outName, tagPer, tagAper));
            end
        end
    end
end

function labels = get_labels(res_struct, outName, fName)
    if isfield(res_struct.(outName), 'regionLabels')
        labels = res_struct.(outName).regionLabels;
    elseif isfield(res_struct.(outName), 'region_labels')
        labels = res_struct.(outName).region_labels;
    else
        tempDat = res_struct.(outName).(fName).vals;
        nReg = size(tempDat, 2);
        labels = arrayfun(@(x) sprintf('Reg%d', x), 1:nReg, 'UniformOutput', false);
    end
end

function cmap = bluewhitered(m)
    % Diverging Red-White-Blue colormap
    if nargin < 1, m = size(get(gcf,'colormap'),1); end
    bottom = [0 0 1]; 
    middle = [1 1 1];
    top = [1 0 0];
    x = [0, 0.5, 1];
    cmap = interp1(x, [bottom; middle; top], linspace(0, 1, m));
end
