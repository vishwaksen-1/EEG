function plot_MI_results(results)
% plot_MI_results - Display Mutual Information with CI masking
%
% Usage:
%   plot_MI_results(results)
%
% Inputs:
%   results : Struct with [50 x 8 x 8 x Lags] boot vals
%
% Logic:
%   1. Compute Median and 95% CI.
%   2. Mask values where CI includes 0.
%   3. Plot Lag vs Target Region for each Reference Region.

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
        
        fprintf('\n=== Dataset: %s ===\n', outName);

        for s = 1:numel(dataFields)
            fName = dataFields{s};
            
            % Extract
            boot_vals = results.(outName).(fName).vals; % [50 x nReg x nReg x nLags]
            
            % Handle Lags
            % Lags might be [1 x nLags] or [50 x ...]. 
            % Usually structure has lags same size as vals, or just a vector.
            % We need a vector for imagesc.
            lagsRaw = results.(outName).(fName).lags;
            if numel(lagsRaw) > size(boot_vals, 4)
                % It's likely the full matrix repeated. Extract one vector.
                % Assuming lags are identical across bootstraps
                % If lags is [50 x 8 x 8 x 923], take (1,1,1,:)
                lags = squeeze(lagsRaw(1,1,1,:)); 
            else
                lags = lagsRaw;
            end
            
            % Statistics
            mi_median = squeeze(median(boot_vals, 1));   % [nReg x nReg x nLags]
            ci_low    = squeeze(prctile(boot_vals, 2.5, 1));
            ci_high   = squeeze(prctile(boot_vals, 97.5, 1));
            
            % Plot per Reference Region
            for i = 1:nReg
                figure('Color','w');
                
                % Extract Ref i vs All
                mu_c = squeeze(mi_median(i,:,:)); 
                low_c = squeeze(ci_low(i,:,:));
                high_c = squeeze(ci_high(i,:,:));

                % Masking
                mask_zero = (low_c <= 0) & (high_c >= 0);
                
                plotData = mu_c;
                plotData(mask_zero) = 0;
                plotData(i,:) = NaN; % Nan out auto-MI for visibility scaling

                imagesc(lags, 1:nReg, plotData);
                set(gca, 'YDir', 'normal');
                colormap(jet);
                colorbar;
                
                % Auto-scale color but symmetric or 0-based if possible
                % MI is strictly pos (mostly), so 0 to Max is good.
                clim('auto'); 

                title(sprintf('%s — %s\nMI: %s vs all (Non-Sig=0)', ...
                      outName, fName, regLabels{i}), 'Interpreter', 'none');
                xlabel('Lag (s)');
                ylabel('Region');
                yticks(1:nReg);
                yticklabels(regLabels);

                fprintf('    Showing %s vs all — press any key...\n', regLabels{i});
                pause;
            end
            close all;
        end
    end
    fprintf('\n✅ Finished plotting MI results.\n');
end