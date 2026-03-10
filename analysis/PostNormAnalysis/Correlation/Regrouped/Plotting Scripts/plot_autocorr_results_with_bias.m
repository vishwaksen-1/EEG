function plot_autocorr_results_with_bias(results, bias_results)
% plot_autocorr_results_with_bias - Plot Autocorr vs Bias with Significance
%   One figure per channel pair.
%   Overlays Signal (Color) and Bias (Grey).
%   Mark significant deviations (non-overlapping CIs) with a bar at the top.
%   **Includes fix to center-crop bias data to match signal length.**
%
% Usage:
%   plot_autocorr_results_with_bias(results, bias_results)

    outNames = fieldnames(results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        % Find stimulus fields (e.g., stim1_subTrialNorm)
        fields = fieldnames(results.(outName));
        stimNames = fields(contains(fields, 'subTrialNorm'));

        fprintf('\n=== Dataset: %s ===\n', outName);

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            fprintf('  > Stimulus: %s\n', stimName);

            % --- Extract Data ---
            % Signal structure: results.Out.stim.corr.mean
            if ~isfield(results.(outName).(stimName), 'corr')
                warning('No .corr field found in %s.%s', outName, stimName);
                continue;
            end
            sigStruct = results.(outName).(stimName).corr;
            
            % Bias structure: bias_results.Out.stim.mean
            if ~isfield(bias_results, outName) || ~isfield(bias_results.(outName), stimName)
                warning('Bias data missing for %s.%s', outName, stimName);
                continue;
            end
            biasStruct = bias_results.(outName).(stimName);

            % --- FIX: Center-Crop Bias to match Signal length ---
            nSig = length(sigStruct.lags);
            nBias = size(biasStruct.mean, 3);
            if nBias > nSig
                diff = nBias - nSig;
                startIdx = floor(diff / 2) + 1;
                cropIdx = startIdx : (startIdx + nSig - 1);
                biasStruct.mean = biasStruct.mean(:, :, cropIdx);
                biasStruct.std  = biasStruct.std(:, :, cropIdx);
                % fprintf('    (Cropped bias from %d to %d points)\n', nBias, nSig);
            end
            % ----------------------------------------------------

            lags = sigStruct.lags;
            nCh = size(sigStruct.mean, 1);
            % pairCount = floor(nCh / 2);

            % Get channel names from bias struct
            if isfield(biasStruct, 'region_labels')
                chNames = biasStruct.region_labels;
            elseif isfield(biasStruct, 'regionLabels')
                chNames = biasStruct.regionLabels;
            else
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end

            % Filter positive lags
            posIdx = lags >= 0;
            lags = lags(posIdx);

            for i = 1:2:nCh
                ch1 = i;
                ch2 = i + 1;

                figure('Color', 'w', 'Position', [100, 100, 1000, 400]);

                % ----- Subplot 1: Channel ch1 -----
                subplot(1, 2, 1);
                plot_overlay(sigStruct, biasStruct, ch1, lags, posIdx, ...
                    chNames{ch1}, 'b', [0.7 0.85 1]);

                % ----- Subplot 2: Channel ch2 -----
                subplot(1, 2, 2);
                plot_overlay(sigStruct, biasStruct, ch2, lags, posIdx, ...
                    chNames{ch2}, 'r', [1 0.8 0.8]);

                sgtitle(sprintf('%s — %s\nChannels: %s & %s', ...
                    outName, stimName, chNames{ch1}, chNames{ch2}), 'Interpreter', 'none');

                fprintf('    Showing %s & %s — press any key for next...\n', ...
                        chNames{ch1}, chNames{ch2});
                pause;
            end
            close all;
        end
    end
end

%% ===== Helper: Plot Overlay =====
function plot_overlay(sig, bias, chIdx, lags, posIdx, label, lineCol, faceCol)
    % Extract Signal
    sMean = squeeze(sig.mean(chIdx, chIdx, posIdx));
    sStd  = squeeze(sig.std(chIdx, chIdx, posIdx));
    sUpper = sMean + 1.96 * sStd;
    sLower = sMean - 1.96 * sStd;

    % Extract Bias
    bMean = squeeze(bias.mean(chIdx, chIdx, posIdx));
    bStd  = squeeze(bias.std(chIdx, chIdx, posIdx));
    bUpper = bMean + 1.96 * bStd;
    bLower = bMean - 1.96 * bStd;

    hold on;
    % Plot Bias (Grey)
    fill([lags fliplr(lags)], [bUpper' fliplr(bLower')], ...
         [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, bMean, 'k', 'LineWidth', 1.5);

    % Plot Signal (Color)
    fill([lags fliplr(lags)], [sUpper' fliplr(sLower')], ...
         faceCol, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, sMean, 'Color', lineCol, 'LineWidth', 2);

    % Plot Significance (Non-overlapping CIs)
    % Sig if Signal Lower > Bias Upper  OR  Signal Upper < Bias Lower
    isSig = (sLower > bUpper) | (sUpper < bLower);
    
    if any(isSig)
        yMax = max([sUpper; bUpper]);
        sigY = yMax * 1.05; % Place slightly above plot
        % Plot as points or small bars
        plot(lags(isSig), repmat(sigY, sum(isSig), 1), '.', ...
             'Color', [0.2 0.7 0.2], 'MarkerSize', 6);
    end

    yline(0, '--k');
    xlabel('Lag (s)');
    ylabel('Autocorrelation');
    title(label, 'Interpreter', 'none');
    grid on;
    xlim([0, max(lags)]);
    hold off;
end