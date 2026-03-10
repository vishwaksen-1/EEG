function plot_autocorr_periodic_ap(active_results, passive_results, activeBaseline_results, passiveBaseline_results)
% plot_autocorr_periodic_ap - Compare periodic/aperiodic & active/passive autocorrelations,
%                             overlaying pre- and during-experiment baselines.
%
%   Each figure shows 4 subplots:
%       (2,2,1) Periodic   - Active
%       (2,2,2) Periodic   - Passive
%       (2,2,3) Aperiodic  - Active
%       (2,2,4) Aperiodic  - Passive
%
%   Inputs:
%       active_results, passive_results : main experiment autocorrs
%       activeBaseline_results, passiveBaseline_results : contain preExp & duringExp baselines
%
%   Overlays:
%       - Pre-experiment baseline (1.8 s lag window)
%       - During-experiment baseline (0.5 s lag window, per stim)
%
%   Both plotted as dashed gray lines with faint CI shading.

    outNames = fieldnames(active_results);

    for o = 1:numel(outNames)
        outName = outNames{o};

        if ~isfield(passive_results, outName)
            warning('Missing field "%s" in passive results.', outName);
            continue;
        end

        stimNamesA = fieldnames(active_results.(outName));
        stimNamesA = stimNamesA(contains(stimNamesA, 'stim') & ~contains(stimNamesA, 'raw'));
        stimNamesP = fieldnames(passive_results.(outName));
        stimNamesP = stimNamesP(contains(stimNamesP, 'stim') & ~contains(stimNamesP, 'raw'));

        % Identify periodic (odd) and aperiodic (even) stims
        periodicStimsA   = stimNamesA(contains(stimNamesA, {'stim1','stim3'}));
        aperiodicStimsA  = stimNamesA(contains(stimNamesA, {'stim2','stim4'}));
        periodicStimsP   = stimNamesP(contains(stimNamesP, {'stim1','stim3'}));
        aperiodicStimsP  = stimNamesP(contains(stimNamesP, {'stim2','stim4'}));

        if isempty(periodicStimsA) || isempty(aperiodicStimsA)
            warning('Missing stim pairs (periodic/aperiodic) in active %s.', outName);
            continue;
        end
        if isempty(periodicStimsP) || isempty(aperiodicStimsP)
            warning('Missing stim pairs (periodic/aperiodic) in passive %s.', outName);
            continue;
        end

        % Example autocorr to get lags and channels
        acorrExample = active_results.(outName).(periodicStimsA{1}).acorr;
        lags = acorrExample.lags;
        nCh = size(acorrExample.mean,1);
        chNames = active_results.(outName).channels;

        % Keep only non-negative lags
        posIdx = lags >= 0;
        lags = lags(posIdx);

        fprintf('\n=== %s ===\n', outName);

        for ch1 = 1:nCh
            figure;

            %% ---- 1. Periodic Active ----
            stimName = periodicStimsA{1};
            acorr = active_results.(outName).(stimName).acorr;
            plot_acorr_subplot(acorr, lags, posIdx, ch1, chNames{ch1}, ...
                'b', [0.7 0.85 1], 2,2,1, 'Periodic Active');
            overlay_baselines(ch1, activeBaseline_results, 'active', stimName);

            %% ---- 2. Periodic Passive ----
            stimName = periodicStimsP{1};
            acorr = passive_results.(outName).(stimName).acorr;
            plot_acorr_subplot(acorr, lags, posIdx, ch1, chNames{ch1}, ...
                'r', [1 0.8 0.8], 2,2,2, 'Periodic Passive');
            overlay_baselines(ch1, passiveBaseline_results, 'passive', stimName);

            %% ---- 3. Aperiodic Active ----
            stimName = aperiodicStimsA{1};
            acorr = active_results.(outName).(stimName).acorr;
            plot_acorr_subplot(acorr, lags, posIdx, ch1, chNames{ch1}, ...
                'b', [0.8 0.9 1], 2,2,3, 'Aperiodic Active');
            overlay_baselines(ch1, activeBaseline_results, 'active', stimName);

            %% ---- 4. Aperiodic Passive ----
            stimName = aperiodicStimsP{1};
            acorr = passive_results.(outName).(stimName).acorr;
            plot_acorr_subplot(acorr, lags, posIdx, ch1, chNames{ch1}, ...
                'r', [1 0.85 0.85], 2,2,4, 'Aperiodic Passive');
            overlay_baselines(ch1, passiveBaseline_results, 'passive', stimName);

            sgtitle(sprintf('%s — Ch: %s\nPeriodic/Aperiodic × Active/Passive', ...
                outName, chNames{ch1}), 'Interpreter','none');

            pause;
        end
        close all;
    end
end

%% ===== Overlay baselines (no truncation) =====
function overlay_baselines(chIdx, baseline_results, condType, stimName)
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
        warning('No duringExp baseline for %s (%s).', stimField, condType);
    end
end

%% ===== Plot a baseline curve (full length) =====
function plot_baseline_curve(acorrStruct, chIdx, lineStyle, color, labelStr)
    lagsBase = acorrStruct.lags;
    meanVals = squeeze(acorrStruct.mean(chIdx,:));
    stdVals  = squeeze(acorrStruct.std(chIdx,:));
    CI = 1.96 * stdVals;

    % Keep only positive lags
    posIdx = lagsBase >= 0;
    lagsBase = lagsBase(posIdx);
    meanVals = meanVals(posIdx);
    CI = CI(posIdx);

    % Faint CI fill (full baseline length)
    fill([lagsBase fliplr(lagsBase)], ...
         [meanVals+CI fliplr(meanVals-CI)], ...
         color, 'EdgeColor','none', 'FaceAlpha',0.15);

    plot(lagsBase, meanVals, lineStyle, 'Color', color, 'LineWidth', 1.2, 'DisplayName', labelStr);
end

%% ===== Stimulation autocorr (unchanged) =====
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
    plot(lags, meanVals, lineColor, 'LineWidth', 2, 'DisplayName', label);
    yline(0, '--k');
    hold off;
    xlabel('Lag (s)');
    ylabel('Autocorrelation');
    title(sprintf('%s - %s', label, chName), 'Interpreter','none');
    grid on;
    xlim([0, max(lags)]);
end
