function plot_MI_diff_PeriodicAperiodic(results)
% plot_MI_diff_PeriodicAperiodic - Periodic vs Aperiodic Modulation Index
%
% Usage:
%   plot_MI_diff_PeriodicAperiodic(active_res) % or passive_res
%
% Logic:
%   1. Identifies Pairs: Stim1(Per) vs Stim2(Aper), Stim3(Per) vs Stim4(Aper).
%   2. Computes Modulation Index per bootstrap.
%   3. Plots Heatmaps and Area Matrices.

    outNames = fieldnames(results);
    
    % Define Pairs based on instructions
    % Pair 1: stim1 vs stim2
    % Pair 2: stim3 vs stim4
    pairs = { {'stim1', 'stim2'}, {'stim3', 'stim4'} };
    % Note: Actual field names might be 'stim1_subTrialNorm' etc. 
    % We will search for 'stim1' inside the field name.

    for o = 1:numel(outNames)
        outName = outNames{o};
        subFields = fieldnames(results.(outName));
        
        % Get Labels
        if isfield(results.(outName), 'regionLabels')
            regLabels = results.(outName).regionLabels;
        elseif isfield(results.(outName), 'region_labels')
             regLabels = results.(outName).region_labels;
        else
             % Extract from first available
             f1 = subFields{find(contains(subFields, 'stim'), 1)};
             tempDat = results.(outName).(f1).vals;
             nReg = size(tempDat, 2);
             regLabels = arrayfun(@(x) sprintf('Reg%d', x), 1:nReg, 'UniformOutput', false);
        end
        nReg = length(regLabels);

        for p = 1:length(pairs)
            pTags = pairs{p};
            tagPer = pTags{1};
            tagAper = pTags{2};
            
            % Find full field names
            fPer = subFields(contains(subFields, tagPer));
            fAper = subFields(contains(subFields, tagAper));
            
            if isempty(fPer) || isempty(fAper)
                continue; % Skip if this pair doesn't exist in this Out struct
            end
            
            namePer = fPer{1};
            nameAper = fAper{1};
            
            % --- Extract ---
            vals_Per = results.(outName).(namePer).vals;
            vals_Aper = results.(outName).(nameAper).vals;
            
            lagsRaw = results.(outName).(namePer).lags;
            if numel(lagsRaw) > size(vals_Per, 4)
                lags = squeeze(lagsRaw(1,1,1,:));
            else
                lags = lagsRaw;
            end
            
            % --- Compute Modulation Index ---
            % (Per - Aper) ./ (Per + Aper)
            eps_val = 1e-12;
            mod_idx_boot = (vals_Per - vals_Aper) ./ (vals_Per + vals_Aper + eps_val);
            
            % --- Statistics ---
            med_diff = squeeze(median(mod_idx_boot, 1, 'omitnan'));
            lo_diff  = squeeze(prctile(mod_idx_boot, 2.5, 1));
            hi_diff  = squeeze(prctile(mod_idx_boot, 97.5, 1));
            
            % --- Masking ---
            mask_sig = (lo_diff > 0) | (hi_diff < 0);
            
            valid_diff = med_diff;
            valid_diff(~mask_sig) = 0; 
            
            pairName = sprintf('%s vs %s', tagPer, tagAper);
            
            % --- Plot 1: Lag Heatmaps ---
            for i = 1:nReg
                figure('Color','w', 'Position', [100 100 600 400]);
                
                mu_c = squeeze(valid_diff(i,:,:));
                mu_c(i,:) = NaN; 

                imagesc(lags, 1:nReg, mu_c);
                set(gca,'YDir','normal');
                colormap(jet); colorbar; clim([-1 1]);
                
                title(sprintf('%s: %s\nModulation Index (Per-Aper)/(Per+Aper)\nRef: %s (Sig Only)', ...
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
            
            title(sprintf('%s: %s\nTotal Modulation Strength (Periodic vs Aperiodic)', outName, pairName), 'Interpreter', 'none');
            xlabel('Target Region'); ylabel('Source Region');
            xticks(1:nReg); xticklabels(regLabels); xtickangle(45);
            yticks(1:nReg); yticklabels(regLabels);
            axis square; grid on;
        end
    end
end