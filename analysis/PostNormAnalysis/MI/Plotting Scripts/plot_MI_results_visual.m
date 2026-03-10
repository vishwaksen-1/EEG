function plot_MI_results_visual(results)
% plot_MI_results_visual - Side-by-side (stacked) plot of visual segments
%
% Usage:
%   plot_MI_results_visual(results)

    outName = fieldnames(results);
    outName = outName{1}; 
    
    subFields = fieldnames(results.(outName));
    dataFields = subFields(contains(subFields, 'seg') | contains(subFields, 'stim'));
    dataFields = dataFields(~contains(dataFields, 'raw'));
    
    % Labels
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
    
    % Lags (Assume same for all segs)
    lagsRaw = results.(outName).(dataFields{1}).lags;
    if numel(lagsRaw) > size(results.(outName).(dataFields{1}).vals, 4)
        lags = squeeze(lagsRaw(1,1,1,:));
    else
        lags = lagsRaw;
    end

    fprintf('\n=== Visualizing: %s ===\n', outName);
    
    numPlots = numel(dataFields);

    for i = 1:nReg
        figure('Color','w', 'Position', [100 100 600 250*numPlots]);
        
        for s = 1:numPlots
            fName = dataFields{s};
            
            % --- Extract & Stats ---
            boot_vals = results.(outName).(fName).vals;
            
            mi_med = squeeze(median(boot_vals, 1));
            ci_lo  = squeeze(prctile(boot_vals, 2.5, 1));
            ci_hi  = squeeze(prctile(boot_vals, 97.5, 1));
            
            % --- Masking ---
            mu_c = squeeze(mi_med(i,:,:));
            l_c  = squeeze(ci_lo(i,:,:));
            h_c  = squeeze(ci_hi(i,:,:));
            
            mask = (l_c <= 0) & (h_c >= 0);
            
            plotData = mu_c;
            plotData(mask) = 0;
            plotData(i,:) = NaN; % Hide Auto-MI

            subplot(numPlots, 1, s);
            imagesc(lags, 1:nReg, plotData);
            set(gca, 'YDir', 'normal');
            colormap(jet);
            colorbar;
            
            title(sprintf('%s (Non-Sig=0)', fName), 'Interpreter', 'none');
            xlabel('Lag (s)');
            ylabel('Region');
            yticks(1:nReg);
            yticklabels(regLabels);
        end

        sgtitle(sprintf('%s — Reference: %s', outName, regLabels{i}), 'Interpreter','none');
        fprintf('  Showing %s — press any key for next...\n', regLabels{i});
        pause;
    end
    close all;
    fprintf('\n✅ Finished plotting visual comparison.\n');
end