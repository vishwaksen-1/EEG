function plot_crosscorr_results_visual(results, bias_results)
% plot_crosscorr_results_visual - Side-by-side plot of sub-conditions
% Includes central cropping for bias data.

    outName = fieldnames(results);
    outName = outName{1}; 
    
    subFields = fieldnames(results.(outName));
    subFields = subFields(contains(subFields, 'stim') | contains(subFields, 'seg'));
    subFields = subFields(~contains(subFields, 'raw'));
    
    sampleField = subFields{1};
    if isfield(bias_results.(outName).(sampleField), 'regionLabels')
        chNames = bias_results.(outName).(sampleField).regionLabels;
    elseif isfield(results.(outName), 'channels')
        chNames = results.(outName).channels;
    else
        nChTemp = size(results.(outName).(sampleField).corr.mean, 1);
        chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nChTemp, 'UniformOutput', false);
    end
    
    nCh = numel(chNames);
    lags = results.(outName).(sampleField).corr.lags;

    fprintf('\n=== Visualizing: %s ===\n', outName);
    
    numPlots = numel(subFields);

    for i = 1:nCh
        figure('Color','w', 'Position', [100 100 600 250*numPlots]);
        
        for s = 1:numPlots
            fName = subFields{s};
            
            % --- Extract Data ---
            mu_c = squeeze(results.(outName).(fName).corr.mean(i,:,:));
            sd_c = squeeze(results.(outName).(fName).corr.std(i,:,:));
            
            if isfield(bias_results, outName) && isfield(bias_results.(outName), fName)
                mu_b_full = squeeze(bias_results.(outName).(fName).mean(i,:,:));
                sd_b_full = squeeze(bias_results.(outName).(fName).std(i,:,:));
                
                % --- Central Crop Bias ---
                nLagsC = size(mu_c, 2);
                nLagsB = size(mu_b_full, 2);
                
                if nLagsB > nLagsC
                    diff = nLagsB - nLagsC;
                    startIdx = floor(diff / 2) + 1;
                    indices = startIdx : (startIdx + nLagsC - 1);
                    mu_b = mu_b_full(:, indices);
                    sd_b = sd_b_full(:, indices);
                else
                    mu_b = mu_b_full;
                    sd_b = sd_b_full;
                end

                plotData = apply_bias_mask(mu_c, sd_c, mu_b, sd_b);
            else
                warning('Bias missing for %s. Applying only zero-crossing mask.', fName);
                plotData = apply_zero_mask(mu_c, sd_c);
            end

            plotData(i,:) = NaN;

            subplot(numPlots, 1, s);
            imagesc(lags, 1:nCh, plotData);
            set(gca, 'YDir', 'normal');
            colormap(jet);
            colorbar;
            clim([-1 1]);
            title(sprintf('%s (Masked=0)', fName), 'Interpreter', 'none');
            xlabel('Lag (s)');
            ylabel('Channel');
            yticks(1:nCh);
            yticklabels(chNames);
        end

        sgtitle(sprintf('%s — Reference: %s', outName, chNames{i}), 'Interpreter','none');
        fprintf('  Showing %s — press any key for next...\n', chNames{i});
        pause;
    end
    close all;
    fprintf('\n✅ Finished plotting visual comparison.\n');
end

function maskedData = apply_bias_mask(mu_c, sd_c, mu_b, sd_b)
    ci_c_low = mu_c - 1.96 * sd_c;
    ci_c_high = mu_c + 1.96 * sd_c;
    ci_b_low = mu_b - 1.96 * sd_b;
    ci_b_high = mu_b + 1.96 * sd_b;

    mask_zero = (ci_c_low <= 0) & (ci_c_high >= 0);
    mask_overlap = (ci_c_low <= ci_b_high) & (ci_c_high >= ci_b_low);
    
    maskedData = mu_c;
    maskedData(mask_zero | mask_overlap) = 0;
end

function maskedData = apply_zero_mask(mu_c, sd_c)
    ci_c_low = mu_c - 1.96 * sd_c;
    ci_c_high = mu_c + 1.96 * sd_c;
    mask_zero = (ci_c_low <= 0) & (ci_c_high >= 0);
    maskedData = mu_c;
    maskedData(mask_zero) = 0;
end