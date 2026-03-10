function plot_autocorr_results_ap(active_results, passive_results, activeBaseline_results, passiveBaseline_results)
% plot_autocorr_results_ap_with_baseline - Compare Active vs Passive autocorrelations
%   with preExp & duringExp baselines overlaid.
%
%   Each figure shows a 2×2 grid:
%       (2,2,1) Active   — Channel A
%       (2,2,2) Active   — Channel A'
%       (2,2,3) Passive  — Channel A
%       (2,2,4) Passive  — Channel A'
%
%   Inputs:
%       active_results          : struct with active condition autocorr
%       passive_results         : struct with passive condition autocorr
%       activeBaseline_results  : baselines for active condition
%       passiveBaseline_results : baselines for passive condition
%
%   Each subplot overlays:
%       - PreExp baseline (full ±1.8s)
%       - DuringExp baseline (stim-specific ±0.5s)

    outNames = fieldnames(active_results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        stimNames = fieldnames(active_results.(outName));
        stimNames = stimNames(contains(stimNames, 'stim') | contains(stimNames, 'seg'));
        stimNames = stimNames(~contains(stimNames, 'raw'));

        fprintf('\n=== Dataset: %s ===\n', outName);

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            fprintf('  > Stimulus: %s\n', stimName);

            acorrA = active_results.(outName).(stimName).acorr;
            acorrP = passive_results.(outName).(stimName).acorr;
            lags = acorrA.lags;
            nCh = size(acorrA.mean, 1);
            pairCount = floor(nCh / 2);
            chNames = active_results.(outName).channels;

            % Keep only non-negative lags
            posIdx = lags >= 0;
            lags = lags(posIdx);

            for i = 1:pairCount
                ch1 = i;
                ch2 = nCh - i + 1;

                figure;

                % ===== ACTIVE =====
                subplot(2,2,1);
                plot_acorr_subplot(acorrA, lags, posIdx, ch1, chNames{ch1}, ...
                    'b', [0.7 0.85 1], 'Active');
                overlay_baselines(ch1, activeBaseline_results, stimName);
                title(sprintf('Active - %s', chNames{ch1}), 'Interpreter','none');

                subplot(2,2,2);
                plot_acorr_subplot(acorrA, lags, posIdx, ch2, chNames{ch2}, ...
                    'r', [1 0.8 0.8], 'Active');
                overlay_baselines(ch2, activeBaseline_results, stimName);
                title(sprintf('Active - %s', chNames{ch2}), 'Interpreter','none');

                % ===== PASSIVE =====
                subplot(2,2,3);
                plot_acorr_subplot(acorrP, lags, posIdx, ch1, chNames{ch1}, ...
                    'b', [0.8 0.9 1], 'Passive');
                overlay_baselines(ch1, passiveBaseline_results, stimName);
                title(sprintf('Passive - %s', chNames{ch1}), 'Interpreter','none');

                subplot(2,2,4);
                plot_acorr_subplot(acorrP, lags, posIdx, ch2, chNames{ch2}, ...
                    'r', [1 0.85 0.85], 'Passive');
                overlay_baselines(ch2, passiveBaseline_results, stimName);
                title(sprintf('Passive - %s', chNames{ch2}), 'Interpreter','none');

                % ---- Super title ----
                sgtitle(sprintf('%s — %s\nActive vs Passive | Channels: %s & %s', ...
                    outName, stimName, chNames{ch1}, chNames{ch2}), ...
                    'Interpreter','none');

                % ---- Zero-cross info ----
                fprintf('\n--- Zero-crossing (for lateralization) ---\n');
                compute_zero_cross(acorrA, lags, posIdx, ch1, chNames{ch1}, 'Active ');
                compute_zero_cross(acorrA, lags, posIdx, ch2, chNames{ch2}, 'Active ');
                compute_zero_cross(acorrP, lags, posIdx, ch1, chNames{ch1}, 'Passive');
                compute_zero_cross(acorrP, lags, posIdx, ch2, chNames{ch2}, 'Passive');

                fprintf('\n    Showing %s & %s \n— press any key for next...\n', ...
                        chNames{ch1}, chNames{ch2});
                pause;
                close all;
            end
        end
    end
end

%% ===== Overlay both baselines =====
function overlay_baselines(chIdx, baseline_results, stimName)
    hold on;
    % --- PreExp baseline (full) ---
    pre = baseline_results.preExp_baseline.acorr;
    % plot_baseline_curve(pre, chIdx, '--', [0.3 0.3 0.3], 'PreExp');

    % --- DuringExp baseline (stim-specific) ---
    stimNum = regexp(stimName, '\d+', 'match', 'once');
    stimField = sprintf('stim%s_baseline', stimNum);
    if isfield(baseline_results.duringExp_baseline, stimField)
        dur = baseline_results.duringExp_baseline.(stimField).acorr;
        plot_baseline_curve(dur, chIdx, ':', [0.5 0.5 0.5], 'DuringExp');
    else
        warning('No duringExp baseline for %s.', stimField);
    end
end

%% ===== Plot baseline curve =====
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
function plot_acorr_subplot(acorr, lags, posIdx, chIdx, chName, lineColor, fillColor, label)
    meanVals = squeeze(acorr.mean(chIdx, :));
    stdVals  = squeeze(acorr.std(chIdx, :));
    CI = 1.96 * stdVals;

    meanVals = meanVals(posIdx);
    CI = CI(posIdx);

    hold on;
    fill([lags fliplr(lags)], [meanVals+CI fliplr(meanVals-CI)], ...
         fillColor, 'EdgeColor','none', 'FaceAlpha',0.4);
    plot(lags, meanVals, lineColor, 'LineWidth', 2);
    yline(0, '--k');
    xlabel('Lag (s)');
    ylabel('Autocorrelation');
    grid on;
    xlim([0, max(lags)]);
end

%% ===== Compute zero-crossing =====
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
