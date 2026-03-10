function plot_autocorr_periodic_vs_aperiodic(results, baseline_results)
% plot_autocorr_periodic_vs_aperiodic_with_baseline - Plot periodic (odd stims)
%   vs aperiodic (even stims) autocorrelation results with pre- and during-
%   experiment baselines.
%
%   Each figure shows 4 subplots:
%       (2,2,1) Periodic — Channel A
%       (2,2,2) Periodic — Channel A'
%       (2,2,3) Aperiodic — Channel A
%       (2,2,4) Aperiodic — Channel A'
%
%   Adds:
%       - Only positive lags (0 to τ)
%       - Overlays preExp (full ~1.8s) and duringExp (~0.5s) baselines
%       - Computes first zero-crossing (with CI) for lateralization insight
%
%   Inputs:
%       results          : autocorrelation structs (like active/passive combined)
%       baseline_results : contains .preExp_baseline and .duringExp_baseline
%
%   Example:
%       plot_autocorr_periodic_vs_aperiodic_with_baseline(active_results, activeBaseline_results)

    outNames = {'Out12', 'Out34'}; % based on your struct convention

    for o = 1:numel(outNames)
        outName = outNames{o};

        if ~isfield(results, outName)
            warning('Missing field "%s" in results.', outName);
            continue;
        end

        stimNames = fieldnames(results.(outName));
        stimNames = stimNames(contains(stimNames, 'stim') & ~contains(stimNames, 'raw'));
        chNames = results.(outName).channels;

        % Identify periodic (odd) and aperiodic (even) stims
        periodicStims   = stimNames(contains(stimNames, {'stim1','stim3'}));
        aperiodicStims  = stimNames(contains(stimNames, {'stim2','stim4'}));

        if isempty(periodicStims) || isempty(aperiodicStims)
            warning('Missing stim pairs (periodic/aperiodic) in %s.', outName);
            continue;
        end

        % Extract example to get lags
        acorrExample = results.(outName).(periodicStims{1}).acorr;
        lags = acorrExample.lags;
        nCh = size(acorrExample.mean,1);
        pairCount = floor(nCh/2);
        posIdx = lags >= 0;
        lags = lags(posIdx);

        fprintf('\n=== %s ===\n', outName);

        for i = 1:pairCount
            ch1 = i;
            ch2 = nCh - i + 1;

            figure;

            % ===== PERIODIC =====
            stimName = periodicStims{1};
            acorr = results.(outName).(stimName).acorr;
            plot_acorr_subplot(acorr, lags, posIdx, ch1, chNames{ch1}, ...
                'b', [0.7 0.85 1], 2,2,1, 'Periodic');
            overlay_baselines(ch1, baseline_results, stimName);

            plot_acorr_subplot(acorr, lags, posIdx, ch2, chNames{ch2}, ...
                'r', [1 0.8 0.8], 2,2,2, 'Periodic');
            overlay_baselines(ch2, baseline_results, stimName);

            % ===== APERIODIC =====
            stimName = aperiodicStims{1};
            acorr = results.(outName).(stimName).acorr;
            plot_acorr_subplot(acorr, lags, posIdx, ch1, chNames{ch1}, ...
                'b', [0.8 0.9 1], 2,2,3, 'Aperiodic');
            overlay_baselines(ch1, baseline_results, stimName);

            plot_acorr_subplot(acorr, lags, posIdx, ch2, chNames{ch2}, ...
                'r', [1 0.85 0.85], 2,2,4, 'Aperiodic');
            overlay_baselines(ch2, baseline_results, stimName);

            % ---- Super title ----
            sgtitle(sprintf('%s — Periodic vs Aperiodic\nChannels: %s & %s', ...
                outName, chNames{ch1}, chNames{ch2}), 'Interpreter','none');

            % ---- Zero-cross info ----
            fprintf('\n--- Zero-crossing (for lateralization) ---\n');
            stimName = periodicStims{1};
            acorr = results.(outName).(stimName).acorr;
            compute_zero_cross(acorr, lags, posIdx, ch1, chNames{ch1}, 'Periodic');
            compute_zero_cross(acorr, lags, posIdx, ch2, chNames{ch2}, 'Periodic');

            stimName = aperiodicStims{1};
            acorr = results.(outName).(stimName).acorr;
            compute_zero_cross(acorr, lags, posIdx, ch1, chNames{ch1}, 'Aperiodic');
            compute_zero_cross(acorr, lags, posIdx, ch2, chNames{ch2}, 'Aperiodic');

            fprintf('\n    Showing %s & %s — press any key for next...\n', ...
                    chNames{ch1}, chNames{ch2});
            pause;
        end
        close all;
    end
end

%% ===== Overlay baselines (full-length, not truncated) =====
function overlay_baselines(chIdx, baseline_results, stimName)
    hold on;

    % --- Pre-experiment baseline ---
    pre = baseline_results.preExp_baseline.acorr;
    % plot_baseline_curve(pre, chIdx, '--', [0.4 0.4 0.4], 'PreExp');

    % --- During-experiment baseline (stim-specific) ---
    stimField = sprintf('stim%s_baseline', regexp(stimName,'\d+','match','once'));
    if isfield(baseline_results.duringExp_baseline, stimField)
        dur = baseline_results.duringExp_baseline.(stimField).acorr;
        plot_baseline_curve(dur, chIdx, ':', [0.5 0.5 0.5], 'DuringExp');
    else
        warning('No duringExp baseline for %s.', stimField);
    end
end

%% ===== Plot baseline curve (same as before) =====
function plot_baseline_curve(acorrStruct, chIdx, lineStyle, color, labelStr)
    lagsBase = acorrStruct.lags;
    meanVals = squeeze(acorrStruct.mean(chIdx,:));
    stdVals  = squeeze(acorrStruct.std(chIdx,:));
    CI = 1.96 * stdVals;

    posIdx = lagsBase >= 0;
    lagsBase = lagsBase(posIdx);
    meanVals = meanVals(posIdx);
    CI = CI(posIdx);

    fill([lagsBase fliplr(lagsBase)], ...
         [meanVals+CI fliplr(meanVals-CI)], ...
         color, 'EdgeColor','none', 'FaceAlpha',0.15);
    plot(lagsBase, meanVals, lineStyle, 'Color', color, 'LineWidth', 1.2, 'DisplayName', labelStr);
end

%% ===== Plot autocorrelation =====
function plot_acorr_subplot(acorr, lags, posIdx, chIdx, chName, lineColor, fillColor, nRows, nCols, spIndex, label)
    meanVals = squeeze(acorr.mean(chIdx, :));
    stdVals  = squeeze(acorr.std(chIdx, :));
    CI = 1.96 * stdVals;

    meanVals = meanVals(posIdx);
    CI = CI(posIdx);

    subplot(nRows, nCols, spIndex);
    hold on;
    fill([lags fliplr(lags)], [meanVals+CI fliplr(meanVals-CI)], ...
         fillColor, 'EdgeColor','none', 'FaceAlpha',0.4);
    plot(lags, meanVals, lineColor, 'LineWidth', 2);
    yline(0, '--k');
    hold off;
    xlabel('Lag (s)');
    ylabel('Autocorrelation');
    title(sprintf('%s - %s', label, chName), 'Interpreter','none');
    grid on;
    xlim([0, max(lags)]);
end

%% ===== Compute zero-crossing (same as before) =====
function compute_zero_cross(acorr, lags, posIdx, chIdx, chName, condName)
    meanVals = squeeze(acorr.mean(chIdx, :));
    stdVals  = squeeze(acorr.std(chIdx, :));
    CI = 1.96 * stdVals;

    meanVals = meanVals(posIdx);
    CI = CI(posIdx);

    if meanVals(1) > 0
        testVals = meanVals - CI;
    else
        testVals = meanVals + CI;
    end

    crossIdx = find(diff(sign(testVals)) ~= 0, 1, 'first');
    if ~isempty(crossIdx)
        x1 = lags(crossIdx); x2 = lags(crossIdx+1);
        y1 = testVals(crossIdx); y2 = testVals(crossIdx+1);
        xCross = x1 - y1 * (x2 - x1) / (y2 - y1);
        fprintf('%s | %s: first zero-cross at %.4f s\n', condName, chName, xCross);
    else
        fprintf('%s | %s: no zero-crossing found (within 0–max lag)\n', condName, chName);
    end
end
