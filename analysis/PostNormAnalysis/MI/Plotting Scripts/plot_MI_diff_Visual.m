function plot_MI_diff_Visual(results)
% plot_MI_diff_Visual - Visual Segments Modulation Index
%
% Usage:
%   plot_MI_diff_Visual(visual_res)
%
% Logic:
%   1. Defines Pairs: (seg1, seg2), (seg2, seg3), (seg1, seg3).
%   2. Computes Modulation Index per bootstrap.
%   3. Plots Heatmaps and Area Matrices.

    outNames = fieldnames(results);
    outName = outNames{1}; % Usually just one 'Out' for visual
    
    subFields = fieldnames(results.(outName));
    dataFields = subFields(contains(subFields, 'seg'));
    
    % Labels
    if isfield(results.(outName), 'regionLabels')
        regLabels = results.(outName).regionLabels;
    elseif isfield(results.(outName), 'region_labels')
         regLabels = results.(outName).region_labels;
    else
         f1 = dataFields{1};
         tempDat = results.(outName).(f1).vals;
         nReg = size(tempDat, 2);
         regLabels = arrayfun(@(x) sprintf('Reg%d', x), 1:nReg, 'UniformOutput', false);
    end
    nReg = length(regLabels);
    
    % Define Pairs
    pairs = { {'seg1', 'seg2'}, {'seg2', 'seg3'}, {'seg1', 'seg3'} };
    
    for p = 1:length(pairs)
        pTags = pairs{p};
        tagA = pTags{1};
        tagB = pTags{2};
        
        fA = dataFields(contains(dataFields, tagA));
        fB = dataFields(contains(dataFields, tagB));
        
        if isempty(fA) || isempty(fB), continue; end
        
        nameA = fA{1};
        nameB = fB{1};
        
        % --- Extract ---
        vals_A = results.(outName).(nameA).vals;
        vals_B = results.(outName).(nameB).vals;
        
        lagsRaw = results.(outName).(nameA).lags;
        if numel(lagsRaw) > size(vals_A, 4)
            lags = squeeze(lagsRaw(1,1,1,:));
        else
            lags = lagsRaw;
        end
        
        % --- Compute Modulation Index ---
        % (A - B) ./ (A + B)
        eps_val = 1e-12;
        mod_idx_boot = (vals_A - vals_B) ./ (vals_A + vals_B + eps_val);
        
        % --- Statistics ---
        med_diff = squeeze(median(mod_idx_boot, 1, 'omitnan'));
        lo_diff  = squeeze(prctile(mod_idx_boot, 2.5, 1));
        hi_diff  = squeeze(prctile(mod_idx_boot, 97.5, 1));
        
        % --- Masking ---
        mask_sig = (lo_diff > 0) | (hi_diff < 0);
        
        valid_diff = med_diff;
        valid_diff(~mask_sig) = 0; 
        
        pairName = sprintf('%s vs %s', tagA, tagB);
        
        % --- Plot 1: Lag Heatmaps ---
        for i = 1:nReg
            figure('Color','w', 'Position', [100 100 600 400]);
            
            mu_c = squeeze(valid_diff(i,:,:));
            mu_c(i,:) = NaN; 

            imagesc(lags, 1:nReg, mu_c);
            set(gca,'YDir','normal');
            colormap(jet); colorbar; clim([-1 1]);
            
            title(sprintf('%s: %s\nModulation Index (A-B)/(A+B)\nRef: %s (Sig Only)', ...
                outName, pairName, regLabels{i}), 'Interpreter', 'none');
            xlabel('Lag (s)'); ylabel('Target Region');
            yticks(1:nReg); yticklabels(regLabels);
            
            fprintf('  Showing %s for %s... press key.\n', pairName, regLabels{i});
            pause;
            close(gcf);
        end
        
        % --- Plot 2: Area Plotter ---
        integral_mat = sum(valid_diff, 3, 'omitnan');
        integral_mat(logical(eye(nReg))) = 0;
        
        figure('Name', sprintf('%s - %s Integral', outName, pairName), 'Color', 'w');
        imagesc(integral_mat);
        colormap(jet); colorbar; clim('auto');
        
        title(sprintf('%s: %s\nTotal Modulation Strength', outName, pairName), 'Interpreter', 'none');
        xlabel('Target Region'); ylabel('Source Region');
        xticks(1:nReg); xticklabels(regLabels); xtickangle(45);
        yticks(1:nReg); yticklabels(regLabels);
        axis square; grid on;
    end
end