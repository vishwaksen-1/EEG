function dir_struct = compute_MI_directionality(results)
% compute_MI_directionality - Calculate and Plot Directionality Index
% Includes diagnostics for all-zero plots.

    dir_struct = struct();
    outNames = fieldnames(results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        subFields = fieldnames(results.(outName));
        dataFields = subFields(contains(subFields, 'stim') | contains(subFields, 'seg'));
        dataFields = dataFields(~contains(dataFields, 'raw'));
        
        % Get Labels
        if isfield(results.(outName), 'regionLabels')
            regLabels = results.(outName).regionLabels;
        elseif isfield(results.(outName), 'region_labels')
             regLabels = results.(outName).region_labels;
        else
             tempDat = results.(outName).(dataFields{1}).vals;
             nReg = size(tempDat, 2);
             regLabels = arrayfun(@(x) sprintf('Reg%d', x), 1:nReg, 'UniformOutput', false);
        end
        nReg = length(regLabels);

        for s = 1:numel(dataFields)
            fName = dataFields{s};
            
            % --- Extract Data ---
            boot_vals = results.(outName).(fName).vals;
            lagsRaw   = results.(outName).(fName).lags;
            
            if numel(lagsRaw) > size(boot_vals, 4)
                lags = squeeze(lagsRaw(1,1,1,:));
            else
                lags = lagsRaw;
            end
            
            [~, zeroIdx] = min(abs(lags));
            
            % --- Compute Sums ---
            % Forward: Lags > 0
            sum_fwd = sum(boot_vals(:, :, :, zeroIdx+1:end), 4, 'omitnan');
            % Backward: Lags < 0
            sum_bwd = sum(boot_vals(:, :, :, 1:zeroIdx-1), 4, 'omitnan');
            
            eps_val = 1e-12;
            D_boot = (sum_fwd - sum_bwd) ./ (sum_fwd + sum_bwd + eps_val);
            
            % --- Statistics ---
            D_med = squeeze(median(D_boot, 1, 'omitnan'));
            D_lo  = squeeze(prctile(D_boot, 2.5, 1));
            D_hi  = squeeze(prctile(D_boot, 97.5, 1));
            
            % --- Masking ---
            mask_sig = (D_lo > 0) | (D_hi < 0);
            
            valid_D = D_med;
            valid_D(~mask_sig) = 0;
            valid_D(logical(eye(nReg))) = 0; 
            
            % --- Diagnostics ---
            maxD = max(valid_D(:));
            minD = min(valid_D(:));
            fprintf('[%s-%s] D range (sig): %.4f to %.4f. Significant pixels: %d\n', ...
                outName, fName, minD, maxD, sum(mask_sig(:)));

            % --- Store ---
            dir_struct.(outName).(fName).D_median = valid_D;
            dir_struct.(outName).(fName).D_boot = D_boot;
            dir_struct.(outName).(fName).labels = regLabels;
            
            % --- Plotting ---
            figure('Name', sprintf('%s - %s Directionality', outName, fName), 'Color', 'w');
            
            imagesc(valid_D);
            colormap(bluewhitered(256)); 
            colorbar;
            
            % Robust Clim: If data is all 0, use [-1 1] to avoid error
            if maxD == 0 && minD == 0
                clim([-1 1]);
            else
                clim([-0.5 0.5]);
            end
            
            title(sprintf('%s: %s\nDirectionality Index (Sig Only)\nRed: Row->Col | Blue: Col->Row', outName, fName), 'Interpreter', 'none');
            xlabel('Target Region');
            ylabel('Source Region');
            
            xticks(1:nReg); xticklabels(regLabels); xtickangle(45);
            yticks(1:nReg); yticklabels(regLabels);
            axis square; grid on;
        end
    end
end

function cmap = bluewhitered(m)
    if nargin < 1, m = size(get(gcf,'colormap'),1); end
    bottom = [0 0 1]; middle = [1 1 1]; top = [1 0 0];
    x = [0, 0.5, 1];
    cmap = interp1(x, [bottom; middle; top], linspace(0, 1, m));
end