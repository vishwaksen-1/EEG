function plot_autocorr_results_visual(results)
% plot_autocorr_results_visual - Plot seg1–seg3 autocorrelations for each normalization type.
%
%   Layout: 3 rows (seg1–seg3) × 2 columns (symmetric channels)
%
% Adds:
%   - Only positive lags (0 → τ)
%   - Zero-crossing (CI-based) computation per hemisphere/segment
%
% Usage:
%   plot_autocorr_results_visual(results)

    outName = fieldnames(results);
    outName = outName{1}; % only one 'Out' field
    segFields = fieldnames(results.(outName));
    segFields = segFields(~contains(segFields, 'raw') & ~contains(segFields, 'channels'));

    % Extract normalization types (e.g., subNorm, zNorm)
    normTypes = regexprep(segFields, '^seg[1-3]_?', '');
    normTypes = unique(normTypes(~cellfun(@isempty, normTypes)));

    chNames = results.(outName).channels;
    acorrExample = results.(outName).(segFields{1}).acorr;
    lags = acorrExample.lags;
    nCh = size(acorrExample.mean,1);
    pairCount = floor(nCh/2);

    % Keep only non-negative lags
    posIdx = lags >= 0;
    lags = lags(posIdx);

    for n = 1:numel(normTypes)
        nType = normTypes{n};
        if isempty(nType), continue; end
        fprintf('\n=== Normalization: %s ===\n', nType);

        for i = 1:pairCount
            ch1 = i;
            ch2 = nCh - i + 1;

            figure;

            for s = 1:3
                segName = sprintf('seg%d_%s', s, nType);
                if ~isfield(results.(outName), segName), continue; end
                acorr = results.(outName).(segName).acorr;

                % ---- Channel A ----
                plot_acorr_subplot(acorr, lags, posIdx, ch1, chNames{ch1}, ...
                    'b', [0.7 0.85 1], 3,2,2*(s-1)+1, sprintf('Seg %d', s));

                % ---- Channel A' ----
                plot_acorr_subplot(acorr, lags, posIdx, ch2, chNames{ch2}, ...
                    'r', [1 0.8 0.8], 3,2,2*(s-1)+2, sprintf('Seg %d', s));

                % ---- Zero-crossing info ----
                fprintf('\n--- Zero-crossing (Seg %d | %s) ---\n', s, nType);
                compute_zero_cross(acorr, lags, posIdx, ch1, chNames{ch1}, sprintf('Seg%d_%s', s, nType));
                compute_zero_cross(acorr, lags, posIdx, ch2, chNames{ch2}, sprintf('Seg%d_%s', s, nType));
            end

            sgtitle(sprintf('Normalization: %s\nChannels: %s & %s', ...
                nType, chNames{ch1}, chNames{ch2}), 'Interpreter','none');

            fprintf('\n  Showing %s & %s — press any key for next...\n', ...
                    chNames{ch1}, chNames{ch2});
            pause;
        end
        close all;
    end
end

% ===== Helper function for plotting =====
function plot_acorr_subplot(acorr, lags, posIdx, chIdx, chName, lineColor, fillColor, nRows, nCols, spIndex, label)
    meanVals = squeeze(acorr.mean(chIdx,:));
    stdVals  = squeeze(acorr.std(chIdx,:));
    CI = 1.96 * stdVals;

    % Select only positive lag portion
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

% ===== Helper for zero-cross computation =====
function compute_zero_cross(acorr, lags, posIdx, chIdx, chName, condName)
    meanVals = squeeze(acorr.mean(chIdx, :));
    stdVals  = squeeze(acorr.std(chIdx, :));
    CI = 1.96 * stdVals;

    meanVals = meanVals(posIdx);
    CI = CI(posIdx);

    % Decide which boundary to test based on sign at lag=0
    if meanVals(1) > 0
        testVals = meanVals - CI; % look for crossing below zero
    else
        testVals = meanVals + CI; % look for crossing above zero
    end

    % Find first zero-cross
    crossIdx = find(diff(sign(testVals)) ~= 0, 1, 'first');
    if ~isempty(crossIdx)
        % Linear interpolation for precise crossing
        x1 = lags(crossIdx); x2 = lags(crossIdx+1);
        y1 = testVals(crossIdx); y2 = testVals(crossIdx+1);
        xCross = x1 - y1 * (x2 - x1) / (y2 - y1);
        fprintf('%s | %s: first zero-cross at %.4f s\n', condName, chName, xCross);
    else
        fprintf('%s | %s: no zero-crossing found (within 0–max lag)\n', condName, chName);
    end
end
