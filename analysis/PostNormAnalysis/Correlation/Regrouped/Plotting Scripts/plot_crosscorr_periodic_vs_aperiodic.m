function plot_crosscorr_periodic_vs_aperiodic(results, bias_results, baseline_results, ~, ~)
% plot_crosscorr_periodic_vs_aperiodic - Compare Periodic vs Aperiodic
%
% Inputs:
%   results          : Main results struct (Out12/Out34 -> stimX -> corr)
%   bias_results     : Bias results struct (Out12/Out34 -> stimX -> mean/std)
%   baseline_results : Baseline struct (stim_1/stim_2... -> corr)
%                      Structure:
%                        baseline_results.stim_1.corr... (matches Out12 stim1)
%                        baseline_results.stim_2.corr... (matches Out12 stim2)
%                        baseline_results.stim_3.corr... (matches Out34 stim1)
%                        baseline_results.stim_4.corr... (matches Out34 stim2)
%   (4th and 5th args ignored per new instructions)
%
% Logic:
%   - Plots Periodic vs Aperiodic for Out12 and Out34.
%   - Adds Baseline plots using specific mapping.
%   - Uses main 'bias_results' to mask baseline data (center-cropped).

    outNames = {'Out12', 'Out34'};
    
    for o = 1:numel(outNames)
        outName = outNames{o};
        if ~isfield(results, outName), continue; end

        % --- Identify Periodic vs Aperiodic Stims ---
        fNames = fieldnames(results.(outName));
        fNames = fNames(contains(fNames, 'stim'));
        
        perStr = fNames(contains(fNames, 'stim1') | contains(fNames, 'stim3'));
        aperStr = fNames(contains(fNames, 'stim2') | contains(fNames, 'stim4'));
        
        if isempty(perStr) || isempty(aperStr)
            warning('Could not pair periodic/aperiodic in %s', outName);
            continue;
        end
        
        sPer = perStr{1};   % e.g., stim1_subTrialNorm
        sAper = aperStr{1}; % e.g., stim2_subTrialNorm

        % --- Map to Baseline Fields ---
        % Mapping Rule:
        % Out12: Per -> stim_1, Aper -> stim_2
        % Out34: Per -> stim_3, Aper -> stim_4
        if contains(outName, '12')
            bPerName = 'stim_1';
            bAperName = 'stim_2';
        elseif contains(outName, '34')
            bPerName = 'stim_3';
            bAperName = 'stim_4';
        else
            bPerName = ''; bAperName = '';
        end

        % --- Channel Names (from Bias if available) ---
        if isfield(bias_results.(outName).(sPer), 'regionLabels')
            chNames = bias_results.(outName).(sPer).regionLabels;
        elseif isfield(bias_results.(outName).(sPer), 'region labels')
            chNames = bias_results.(outName).(sPer).('region labels');
        else
            nCh = size(results.(outName).(sPer).corr.mean, 1);
            chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
        end
        
        nCh = numel(chNames);
        lags = results.(outName).(sPer).corr.lags;

        fprintf('\n=== %s: %s (Per) vs %s (Aper) ===\n', outName, sPer, sAper);

        for i = 1:nCh
            figure('Color','w');

            % 1. Periodic Main
            %    (Data: results...sPer, Bias: bias...sPer)
            subplot(2,2,1);
            do_plot(results.(outName).(sPer), bias_results.(outName).(sPer), i, lags, nCh, chNames, 'Periodic');

            % 2. Aperiodic Main
            %    (Data: results...sAper, Bias: bias...sAper)
            subplot(2,2,2);
            do_plot(results.(outName).(sAper), bias_results.(outName).(sAper), i, lags, nCh, chNames, 'Aperiodic');

            % 3. Periodic Baseline
            %    (Data: baseline.stim_X, Bias: bias...sPer (reused))
            if ~isempty(bPerName) && isfield(baseline_results, bPerName)
                 bRes = baseline_results.(bPerName);
                 % REUSE the main bias for the baseline
                 bBias = bias_results.(outName).(sPer); 
                 subplot(2,2,3);
                 do_plot(bRes, bBias, i, lags, nCh, chNames, 'Periodic Base');
            end

            % 4. Aperiodic Baseline
            %    (Data: baseline.stim_Y, Bias: bias...sAper (reused))
            if ~isempty(bAperName) && isfield(baseline_results, bAperName)
                 bRes = baseline_results.(bAperName);
                 % REUSE the main bias for the baseline
                 bBias = bias_results.(outName).(sAper);
                 subplot(2,2,4);
                 do_plot(bRes, bBias, i, lags, nCh, chNames, 'Aperiodic Base');
            end

            sgtitle(sprintf('%s — Per vs Aper\nRef: %s', outName, chNames{i}), 'Interpreter','none');
            pause;
        end
        close all;
    end
end

function do_plot(resStruct, biasStruct, refIdx, fullLags, nCh, chNames, titleStr)
    if isfield(resStruct, 'corr'), resStruct = resStruct.corr; end
    
    mu_c = squeeze(resStruct.mean(refIdx,:,:));
    sd_c = squeeze(resStruct.std(refIdx,:,:));
    
    % Bias might be in a struct or just passed as is? 
    % The main loop passes bias_results.(outName).(sPer), which has .mean and .std fields
    mu_b = squeeze(biasStruct.mean(refIdx,:,:));
    sd_b = squeeze(biasStruct.std(refIdx,:,:));

    % --- Central Crop Bias to match Data ---
    nLagsC = size(mu_c, 2);
    nLagsB = size(mu_b, 2);
    
    if nLagsB > nLagsC
        diff = nLagsB - nLagsC;
        startIdx = floor(diff / 2) + 1;
        indices = startIdx : (startIdx + nLagsC - 1);
        mu_b = mu_b(:, indices);
        sd_b = sd_b(:, indices);
    end

    % Apply Masking
    ci_c_lo = mu_c - 1.96*sd_c; ci_c_hi = mu_c + 1.96*sd_c;
    ci_b_lo = mu_b - 1.96*sd_b; ci_b_hi = mu_b + 1.96*sd_b;
    
    mask = (ci_c_lo <= 0 & ci_c_hi >= 0) | ...
           (ci_c_lo <= ci_b_hi & ci_c_hi >= ci_b_lo);
           
    data = mu_c;
    data(mask) = 0;
    data(refIdx, :) = NaN;

    % Pad if correlation lags are smaller than full display range
    % (Useful if baseline is shorter than main experiment lags)
    currLags = resStruct.lags;
    if numel(currLags) ~= numel(fullLags)
        padLeft = sum(fullLags < min(currLags));
        padRight = sum(fullLags > max(currLags));
        data = [nan(size(data,1), padLeft), data, nan(size(data,1), padRight)];
    end

    imagesc(fullLags, 1:nCh, data);
    set(gca, 'YDir', 'normal');
    colormap(jet); colorbar; clim([-1 1]);
    title(titleStr);
    yticks(1:nCh); yticklabels(chNames);
end