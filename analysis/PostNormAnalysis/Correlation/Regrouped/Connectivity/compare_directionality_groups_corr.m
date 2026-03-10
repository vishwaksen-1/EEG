function compare_directionality_groups_corr(active_res, passive_res, visual_res)
% compare_directionality_groups_corr - Compare Directionality (Correlation)
%
% Usage:
%   compare_directionality_groups_corr(active_res, passive_res, []) 
%   compare_directionality_groups_corr([], [], visual_res)
%
% Logic:
%   1. Uses Monte Carlo simulation based on Mean and Std of Correlation
%      to generate virtual distributions for Directionality Index.
%   2. Uses ABSOLUTE Correlation strength to determine flow magnitude.
%   3. Compares conditions (Active-Passive, Per-Aper) using these distributions.

    % --- 1. Active vs Passive ---
    if ~isempty(active_res) && ~isempty(passive_res)
        fprintf('\n=== Comparing Active vs Passive Directionality (Corr) ===\n');
        
        % Compute D structs
        D_act = compute_D_struct_corr(active_res);
        D_pas = compute_D_struct_corr(passive_res);
        
        outNames = fieldnames(D_act);
        for o = 1:numel(outNames)
            outName = outNames{o};
            fNames = fieldnames(D_act.(outName));
            
            for f = 1:numel(fNames)
                fName = fNames{f};
                if ~isfield(D_pas.(outName), fName), continue; end
                
                % Extract Simulated Distributions
                boot_A = D_act.(outName).(fName).boot;
                boot_P = D_pas.(outName).(fName).boot;
                labels = D_act.(outName).(fName).labels;
                
                % Compute Difference
                Diff_boot = boot_A - boot_P;
                
                % Stats & Plot
                plot_diff_matrix(Diff_boot, labels, ...
                    sprintf('%s: %s (Act - Pas) [Corr]', outName, fName));
            end
        end
        
        % --- 2. Periodic vs Aperiodic ---
        fprintf('\n=== Comparing Periodic vs Aperiodic Directionality (Corr) ===\n');
        process_per_aper(D_act, 'Active');
        process_per_aper(D_pas, 'Passive');
    end
    
    % --- 3. Visual Segments ---
    if ~isempty(visual_res)
        fprintf('\n=== Comparing Visual Segments Directionality (Corr) ===\n');
        D_vis = compute_D_struct_corr(visual_res);
        outName = fieldnames(D_vis); outName = outName{1};
        
        % Visual structure check
        if isfield(D_vis.(outName), 'seg1')
             labels = D_vis.(outName).seg1.labels;
             pairs = {{'seg1','seg2'}, {'seg2','seg3'}, {'seg1','seg3'}};
             
             for p = 1:numel(pairs)
                s1 = pairs{p}{1};
                s2 = pairs{p}{2};
                
                if isfield(D_vis.(outName), s1) && isfield(D_vis.(outName), s2)
                    boot1 = D_vis.(outName).(s1).boot;
                    boot2 = D_vis.(outName).(s2).boot;
                    
                    Diff_boot = boot1 - boot2;
                    plot_diff_matrix(Diff_boot, labels, ...
                        sprintf('Visual: %s - %s [Corr]', s1, s2));
                end
             end
        else
            warning('Visual segments seg1/seg2/seg3 not found.');
        end
    end
end

% ================= HELPER FUNCTIONS =================

function plot_diff_matrix(Diff_boot, labels, titleStr)
    nReg = length(labels);
    
    % Stats
    med_diff = squeeze(median(Diff_boot, 1, 'omitnan'));
    lo_diff  = squeeze(prctile(Diff_boot, 2.5, 1));
    hi_diff  = squeeze(prctile(Diff_boot, 97.5, 1));
    
    % Mask (Sig if 0 is not in CI)
    mask_sig = (lo_diff > 0) | (hi_diff < 0);
    valid_diff = med_diff;
    valid_diff(~mask_sig) = 0;
    valid_diff(logical(eye(nReg))) = 0;
    
    figure('Color', 'w', 'Name', titleStr);
    imagesc(valid_diff);
    colormap(bluewhitered(256));
    colorbar;
    clim([-0.5 0.5]);
    
    title(sprintf('%s\n(Sig Difference Only)', titleStr), 'Interpreter', 'none');
    xlabel('Target'); ylabel('Source');
    xticks(1:nReg); xticklabels(labels); xtickangle(45);
    yticks(1:nReg); yticklabels(labels);
    axis square; grid on;
end

function process_per_aper(D_struct, condName)
    outNames = fieldnames(D_struct);
    pairs = {{'stim1','stim2'}, {'stim3','stim4'}};
    
    for o = 1:numel(outNames)
        outName = outNames{o};
        fNames = fieldnames(D_struct.(outName));
        
        for p = 1:numel(pairs)
            tagPer = pairs{p}{1};
            tagAper = pairs{p}{2};
            
            idxPer = find(contains(fNames, tagPer), 1);
            idxAper = find(contains(fNames, tagAper), 1);
            
            if ~isempty(idxPer) && ~isempty(idxAper)
                namePer = fNames{idxPer};
                nameAper = fNames{idxAper};
                
                bootPer = D_struct.(outName).(namePer).boot;
                bootAper = D_struct.(outName).(nameAper).boot;
                labels = D_struct.(outName).(namePer).labels;
                
                Diff_boot = bootPer - bootAper;
                plot_diff_matrix(Diff_boot, labels, ...
                    sprintf('%s %s: Per(%s) - Aper(%s) [Corr]', condName, outName, tagPer, tagAper));
            end
        end
    end
end

function D_struct = compute_D_struct_corr(results)
    % Generates distributions from Mean/Std
    nSim = 500; 
    D_struct = struct();
    outNames = fieldnames(results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        subFields = fieldnames(results.(outName));
        dataFields = subFields(contains(subFields, 'stim') | contains(subFields, 'seg'));
        dataFields = dataFields(~contains(dataFields, 'raw'));
        
        % Try to find labels
        if isfield(results.(outName), 'regionLabels')
             regLabels = results.(outName).regionLabels;
        elseif isfield(results.(outName), 'region_labels')
             regLabels = results.(outName).region_labels;
        else
             % Fallback
             f1 = dataFields{1};
             if isfield(results.(outName).(f1), 'corr')
                temp = results.(outName).(f1).corr.mean;
             else
                temp = results.(outName).(f1).mean;
             end
             nReg = size(temp, 1);
             regLabels = arrayfun(@(x) sprintf('Reg%d', x), 1:nReg, 'UniformOutput', false);
        end

        for s = 1:numel(dataFields)
            fName = dataFields{s};
            
            % Handle data path
            if isfield(results.(outName).(fName), 'corr')
                baseStruct = results.(outName).(fName).corr;
            else
                baseStruct = results.(outName).(fName);
            end
            
            mu = baseStruct.mean;   
            sd = baseStruct.std;
            lags = baseStruct.lags;
            
            [nReg, ~, nLags] = size(mu);
            
            % --- Sim from Mean/Std ---
            noise = randn(nReg, nReg, nLags, nSim);
            sim_vals = mu + sd .* noise;
            
            % Abs correlation strength for directionality
            abs_vals = abs(sim_vals);
            
            [~, zeroIdx] = min(abs(lags));
            
            sum_fwd = sum(abs_vals(:, :, zeroIdx+1:end, :), 3, 'omitnan');
            sum_bwd = sum(abs_vals(:, :, 1:zeroIdx-1, :), 3, 'omitnan');
            
            eps_val = 1e-12;
            D_sim = (sum_fwd - sum_bwd) ./ (sum_fwd + sum_bwd + eps_val);
            
            % [nSim x nReg x nReg]
            D_sim = permute(squeeze(D_sim), [3, 1, 2]);
            
            D_struct.(outName).(fName).boot = D_sim;
            D_struct.(outName).(fName).labels = regLabels;
        end
    end
end

function cmap = bluewhitered(m)
    if nargin < 1, m = size(get(gcf,'colormap'),1); end
    bottom = [0 0 1]; 
    middle = [1 1 1];
    top = [1 0 0];
    x = [0, 0.5, 1]; % Fixed 3 points
    cmap = interp1(x, [bottom; middle; top], linspace(0, 1, m));
end