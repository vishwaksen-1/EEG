function plot_crosscorr_results_ap(active_res, passive_res, active_bias, passive_bias, ...
                                   active_base, passive_base, ~, ~, ~)
% plot_crosscorr_results_ap - Active vs Passive with Bias Masking
%
% Inputs:
%   active_res, passive_res       : Main results
%   active_bias, passive_bias     : Main bias results
%   active_base, passive_base     : Baseline results (New 'stim_X' structure)
%   (~ args ignored)
%
% Logic:
%   - Plots Active vs Passive.
%   - Maps stims to new baseline structure (stim_1...stim_4).
%   - Reuses Main Bias for Baseline masking (center-cropped).

    outNames = fieldnames(active_res);

    for o = 1:numel(outNames)
        outName = outNames{o};
        stimNames = fieldnames(active_res.(outName));
        stimNames = stimNames(contains(stimNames,'stim') | contains(stimNames,'seg'));
        stimNames = stimNames(~contains(stimNames,'raw'));

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            
            % --- Map to Baseline Fields ---
            % Out12: stim1->stim_1, stim2->stim_2
            % Out34: stim1->stim_3, stim2->stim_4
            bStimName = '';
            if contains(outName, '12')
                if contains(stimName, 'stim1'), bStimName = 'stim_1';
                elseif contains(stimName, 'stim2'), bStimName = 'stim_2'; end
            elseif contains(outName, '34')
                if contains(stimName, 'stim1'), bStimName = 'stim_3';
                elseif contains(stimName, 'stim2'), bStimName = 'stim_4'; end
            end

            % --- Data Gathering ---
            % Main
            datA = active_res.(outName).(stimName);
            biaA = active_bias.(outName).(stimName);
            datP = passive_res.(outName).(stimName);
            biaP = passive_bias.(outName).(stimName);
            
            % Baseline (if mapping exists)
            hasBase = ~isempty(bStimName) && isfield(active_base, bStimName) && isfield(passive_base, bStimName);
            if hasBase
                datBaseA = active_base.(bStimName);
                datBaseP = passive_base.(bStimName);
                % REUSE Main Bias for Baseline
                biaBaseA = biaA; 
                biaBaseP = biaP;
            end

            % Channels
            if isfield(biaA, 'regionLabels')
                chNames = biaA.regionLabels;
            elseif isfield(biaA, 'region labels')
                chNames = biaA.('region labels');
            else
                nCh = size(datA.corr.mean,1);
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end
            nCh = numel(chNames);
            lags = datA.corr.lags;

            % --- Plotting ---
            for i = 1:nCh
                figure('Color','w');

                subplot(2,2,1);
                plot_masked(datA, biaA, i, lags, nCh, chNames, 'Active Main');

                subplot(2,2,2);
                plot_masked(datP, biaP, i, lags, nCh, chNames, 'Passive Main');

                if hasBase
                    subplot(2,2,3);
                    plot_masked(datBaseA, biaBaseA, i, lags, nCh, chNames, 'Active Base');

                    subplot(2,2,4);
                    plot_masked(datBaseP, biaBaseP, i, lags, nCh, chNames, 'Passive Base');
                end

                sgtitle(sprintf('%s — %s\nRef: %s', outName, stimName, chNames{i}), 'Interpreter','none');
                fprintf('Showing %s... press key.\n', chNames{i});
                pause;
            end
            close all;
        end
    end
end

function plot_masked(resS, biaS, refIdx, fullLags, nCh, chNames, titleStr)
    if isfield(resS, 'corr'), resS = resS.corr; end
    
    mu_c = squeeze(resS.mean(refIdx,:,:));
    sd_c = squeeze(resS.std(refIdx,:,:));
    mu_b = squeeze(biaS.mean(refIdx,:,:));
    sd_b = squeeze(biaS.std(refIdx,:,:));

    % --- Central Crop Bias ---
    nLagsC = size(mu_c, 2);
    nLagsB = size(mu_b, 2);
    
    if nLagsB > nLagsC
        diff = nLagsB - nLagsC;
        startIdx = floor(diff / 2) + 1;
        indices = startIdx : (startIdx + nLagsC - 1);
        mu_b = mu_b(:, indices);
        sd_b = sd_b(:, indices);
    end

    % Dual Masking
    ci_c_lo = mu_c - 1.96*sd_c; ci_c_hi = mu_c + 1.96*sd_c;
    ci_b_lo = mu_b - 1.96*sd_b; ci_b_hi = mu_b + 1.96*sd_b;

    mask = (ci_c_lo <= 0 & ci_c_hi >= 0) | ...
           (ci_c_lo <= ci_b_hi & ci_c_hi >= ci_b_lo);

    data = mu_c;
    data(mask) = 0;
    data(refIdx,:) = NaN;

    currLags = resS.lags;
    if numel(currLags) ~= numel(fullLags)
        padLeft = sum(fullLags < min(currLags));
        padRight = sum(fullLags > max(currLags));
        data = [nan(size(data,1), padLeft), data, nan(size(data,1), padRight)];
    end

    imagesc(fullLags, 1:nCh, data);
    set(gca,'YDir','normal');
    colormap(jet); colorbar; clim([-1 1]);
    title(titleStr);
    yticks(1:nCh); yticklabels(chNames);
end