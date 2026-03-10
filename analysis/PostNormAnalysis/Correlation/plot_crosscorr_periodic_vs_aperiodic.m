function plot_crosscorr_periodic_vs_aperiodic(results, baseline_results, normType, baselineType)
% results           : main stim cross-corr (struct with Out12/Out34)
% baseline_results  : baseline cross-corr (separate struct, same layout)
% normType          : 0=subTrialNorm, 1=subNorm
% baselineType      : 0=duringExp, 1=preExp

% plot_crosscorr_periodic_vs_aperiodic - Compare Periodic vs Aperiodic
%   cross-correlation results (with CI masking), including baseline.
%
%   Each figure shows 4 subplots:
%       (2,2,1) Periodic  — Crosscorr (ref vs all)
%       (2,2,2) Aperiodic — Crosscorr (ref vs all)
%       (2,2,3) Periodic baseline  (duringExp or preExp)
%       (2,2,4) Aperiodic baseline (duringExp or preExp)
%
%   baselineType:
%       0 or omitted → duringExp baseline
%       1             → preExp baseline

    if nargin < 3
        baselineType = 0; % default = duringExp
    end

    outNames = {'Out12', 'Out34'};
    sting = 'subTrialNorm';
    if normType == 1
        sting = 'subNorm';
    end

    baseStr = ternary(baselineType == 1, 'preExp_baseline', 'duringExp_baseline');

    for o = 1:numel(outNames)
        outName = outNames{o};
        if ~isfield(results, outName)
            warning('Missing field "%s" in results.', outName);
            continue;
        end

        stimNames = fieldnames(results.(outName));
        stimNames = stimNames(contains(stimNames,'stim') & ~contains(stimNames,'raw') & contains(stimNames, sting));

        periodicStims   = stimNames(contains(stimNames, 'stim1') | contains(stimNames, 'stim3'));
        aperiodicStims  = stimNames(contains(stimNames, 'stim2') | contains(stimNames, 'stim4'));

        if isempty(periodicStims) || isempty(aperiodicStims)
            warning('Missing stim pairs (periodic/aperiodic) in %s.', outName);
            continue;
        end

        stimPeriodic  = periodicStims{1};
        if contains(stimPeriodic, 'stim1')
            u = 'stim1';
        else
            u = 'stim3';
        end
        baselineStimPeriodic = append(u, '_baseline');
        stimAperiodic = aperiodicStims{1};
        if contains(stimAperiodic, 'stim2')
            u = 'stim2';
        else
            u = 'stim4';
        end
        baselinetStimAperiodic = append(u, '_baseline');
        hasBaseline = 1;
        ccorrPer  = results.(outName).(stimPeriodic).corr;
        ccorrAper = results.(outName).(stimAperiodic).corr;

        lags = ccorrPer.lags;
        nCh = size(ccorrPer.mean, 1);
        if baselineType == 0
            basePer  = baseline_results.(baseStr).(baselineStimPeriodic).corr;
            baseAper = baseline_results.(baseStr).(baselinetStimAperiodic).corr;

        else
            basePer = baseline_results.(baseStr).corr;
            baseAper = baseline_results.(baseStr).corr;
        end

        if isfield(results.(outName), 'channels')
            chNames = results.(outName).channels;
        else
            chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
        end

        fprintf('\n=== %s ===\n', outName);

        % Loop through reference channels
        for i = 1:nCh
            figure('Color','w');

            % ==== PERIODIC ====
            subplot(2,2,1);
            plot_crosscorr_heat(ccorrPer, lags, nCh, chNames, i, 'Periodic', lags);

            % ==== APERIODIC ====
            subplot(2,2,2);
            plot_crosscorr_heat(ccorrAper, lags, nCh, chNames, i, 'Aperiodic', lags);

            % ==== BASELINES (if available) ====
            if hasBaseline
                subplot(2,2,3);
                plot_crosscorr_heat(basePer, basePer.lags, nCh, chNames, i, ...
                    sprintf('Periodic baseline (%s)', baseStr), lags);

                subplot(2,2,4);
                plot_crosscorr_heat(baseAper, baseAper.lags, nCh, chNames, i, ...
                    sprintf('Aperiodic baseline (%s)', baseStr), lags);
            end

            sgtitle(sprintf('%s — Periodic vs Aperiodic (%s)\nCrosscorr: %s vs all channels', ...
                outName, baseStr, chNames{i}), 'Interpreter','none');

            fprintf('    Showing %s vs all — press any key for next...\n', chNames{i});
            pause;
        end
        close all;
    end

    fprintf('\n✅ Finished plotting crosscorr (with %s baselines).\n', baseStr);
end


% ===== Helper: CI-masked heatmap with padded lag range =====
function plot_crosscorr_heat(ccorr, lags, nCh, chNames, refIdx, titleStr, fullLagRange)
    meanVals = squeeze(ccorr.mean(refIdx,:,:));
    stdVals  = squeeze(ccorr.std(refIdx,:,:));
    CI = 1.96 * stdVals;

    % Mask where CI crosses zero
    mask = (meanVals - CI <= 0) & (meanVals + CI >= 0);
    meanVals(mask) = NaN;
    meanVals(refIdx,:) = NaN;

    % === Pad to full lag range ===
    if numel(lags) < numel(fullLagRange)
        padLeft  = sum(fullLagRange < min(lags));
        padRight = sum(fullLagRange > max(lags));
        meanVals = [nan(size(meanVals,1), padLeft), meanVals, nan(size(meanVals,1), padRight)];
    end

    imagesc(fullLagRange, 1:nCh, meanVals);
    set(gca, 'YDir', 'normal');
    colormap(jet);
    colorbar;
    clim([-1 1]);
    xlabel('Lag (s)');
    ylabel('Channel');
    yticks(1:nCh);
    yticklabels(chNames);
    title(sprintf('%s — %s vs all', titleStr, chNames{refIdx}), 'Interpreter','none');
    xlim([min(fullLagRange) max(fullLagRange)]);

    % === Mark valid baseline range visually ===
    if contains(lower(titleStr), 'baseline')
        hold on;
        xline(-0.5, '--w', 'LineWidth', 1.2);
        xline(0.5, '--w', 'LineWidth', 1.2);
        hold off;
    end
end


% ===== Small inline ternary helper =====
function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
end
