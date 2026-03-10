function plot_MI_diff_ActivePassive(active_res, passive_res)
% plot_MI_diff_ActivePassive - Active vs Passive Modulation Index
%
% Usage:
%   plot_MI_diff_ActivePassive(active_res, passive_res)
%
% Logic:
%   1. Matches stimuli.
%   2. Computes Modulation Index per bootstrap: (A - P) ./ (A + P).
%   3. Masks where CI of the Index includes 0.
%   4. Plots Lag-Time heatmaps.
%   5. Plots Integral Matrix (Sum of significant Modulation Index).

    outNames = fieldnames(active_res);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        subFields = fieldnames(active_res.(outName));
        dataFields = subFields(contains(subFields, 'stim'));
        dataFields = dataFields(~contains(dataFields, 'raw'));
        
        % Labels
        if isfield(active_res.(outName), 'regionLabels')
            regLabels = active_res.(outName).regionLabels;
        elseif isfield(active_res.(outName), 'region_labels')
             regLabels = active_res.(outName).region_labels;
        else
             tempDat = active_res.(outName).(dataFields{1}).vals;
             nReg = size(tempDat, 2);
             regLabels = arrayfun(@(x) sprintf('Reg%d', x), 1:nReg, 'UniformOutput', false);
        end
        nReg = length(regLabels);

        for s = 1:numel(dataFields)
            fName = dataFields{s};
            
            % Check Passive
            if ~isfield(passive_res.(outName), fName)
                warning('Passive missing for %s %s', outName, fName);
                continue;
            end
            
            % --- Extract ---
            vals_A = active_res.(outName).(fName).vals;
            vals_P = passive_res.(outName).(fName).vals;
            
            lagsRaw = active_res.(outName).(fName).lags;
            if numel(lagsRaw) > size(vals_A, 4)
                lags = squeeze(lagsRaw(1,1,1,:));
            else
                lags = lagsRaw;
            end
            
            % --- Compute Modulation Index per Bootstrap ---
            % (A-P)./(A+P). Add epsilon to avoid div by zero
            eps_val = 1e-12;
            mod_idx_boot = (vals_A - vals_P) ./ (vals_A + vals_P + eps_val);
            
            % --- Statistics ---
            med_diff = squeeze(median(mod_idx_boot, 1, 'omitnan'));
            lo_diff  = squeeze(prctile(mod_idx_boot, 2.5, 1));
            hi_diff  = squeeze(prctile(mod_idx_boot, 97.5, 1));
            
            % --- Masking ---
            mask_sig = (lo_diff > 0) | (hi_diff < 0); % Significant if 0 is NOT in interval
            
            valid_diff = med_diff;
            valid_diff(~mask_sig) = 0; 
            
            % --- Plot 1: Lag Heatmaps (Per Ref) ---
            for i = 1:nReg
                figure('Color','w', 'Position', [100 100 600 400]);
                
                mu_c = squeeze(valid_diff(i,:,:));
                mu_c(i,:) = NaN; % Hide Auto

                imagesc(lags, 1:nReg, mu_c);
                set(gca,'YDir','normal');
                colormap(jet); 
                colorbar; 
                clim([-1 1]); % Modulation index is bounded -1 to 1
                
                title(sprintf('%s — %s\nModulation Index (Active-Passive)/(Active+Passive)\nRef: %s (Sig Only)', ...
                    outName, fName, regLabels{i}), 'Interpreter', 'none');
                xlabel('Lag (s)'); ylabel('Target Region');
                yticks(1:nReg); yticklabels(regLabels);
                
                fprintf('  Showing diff for %s... press key.\n', regLabels{i});
                pause;
                close(gcf);
            end
            
            % --- Plot 2: Area Plotter (Integral Matrix) ---
            % Sum of significant modulation index over lags
            integral_mat = sum(valid_diff, 3, 'omitnan');
            integral_mat(logical(eye(nReg))) = 0; % Clear diagonal
            
            figure('Name', sprintf('%s - %s Diff Integral', outName, fName), 'Color', 'w');
            imagesc(integral_mat);
            colormap(jet);
            colorbar;
            clim('auto'); % Scale to data range
            
            title(sprintf('%s: %s\nTotal Modulation Strength (Active vs Passive)', outName, fName), 'Interpreter', 'none');
            xlabel('Target Region'); ylabel('Source Region');
            xticks(1:nReg); xticklabels(regLabels); xtickangle(45);
            yticks(1:nReg); yticklabels(regLabels);
            axis square; grid on;
            
            fprintf('Computed difference integral: %s - %s\n', outName, fName);
        end
    end
end