function plot_autocorr_results_V_with_bias(results, bias_results)
% plot_autocorr_results_V_with_bias - Visual dataset plotting with Bias
%
%   Plots symmetric channel pairs.
%   Targets fields containing 'subTrialNorm'.
%   **Includes fix to center-crop bias data to match signal length.**
%
% Usage:
%   plot_autocorr_results_V_with_bias(results, bias_results)

    outNames = fieldnames(results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        % Look for generic subTrialNorm fields
        fields = fieldnames(results.(outName));
        stimNames = fields(contains(fields, 'Norm'));

        fprintf('\n=== Dataset: %s ===\n', outName);

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            
            sigStruct = results.(outName).(stimName).corr;
            
            if isfield(bias_results.(outName), stimName)
                biasStruct = bias_results.(outName).(stimName);
            else
                warning('Bias missing for %s', stimName); 
                continue;
            end

            % --- FIX: Center-Crop Bias to match Signal length ---
            nSig = length(sigStruct.lags);
            nBias = size(biasStruct.mean, 3);
            if nBias > nSig
                diff = nBias - nSig;
                startIdx = floor(diff / 2) + 1;
                cropIdx = startIdx : (startIdx + nSig - 1);
                biasStruct.mean = biasStruct.mean(:, :, cropIdx);
                biasStruct.std  = biasStruct.std(:, :, cropIdx);
            end
            % ----------------------------------------------------

            lags = sigStruct.lags;
            nCh = size(sigStruct.mean, 1);
            % pairCount = floor(nCh / 2);
            
            % Channel names
            if isfield(biasStruct, 'regionLabels')
                chNames = biasStruct.regionLabels;
            else
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end

            % Positive Lags
            posIdx = lags >= 0;
            lags = lags(posIdx);

            fprintf('  > Stimulus: %s\n', stimName);

            for i = 1:2:nCh
                ch1 = i;
                ch2 = i + 1;

                figure('Color', 'w', 'Position', [100, 100, 1000, 400]);

                subplot(1, 2, 1);
                plot_overlay(sigStruct, biasStruct, ch1, lags, posIdx, chNames{ch1}, 'b', [0.7 0.85 1]);

                subplot(1, 2, 2);
                plot_overlay(sigStruct, biasStruct, ch2, lags, posIdx, chNames{ch2}, 'r', [1 0.8 0.8]);

                sgtitle(sprintf('%s — %s\nPair: %s & %s', ...
                    outName, stimName, chNames{ch1}, chNames{ch2}), ...
                    'Interpreter', 'none');

                fprintf('    Showing %s & %s — press any key...\n', chNames{ch1}, chNames{ch2});
                pause;
            end
            close all;
        end
    end
end

function plot_overlay(sig, bias, chIdx, lags, posIdx, label, lineCol, faceCol)
    sMean = squeeze(sig.mean(chIdx, chIdx, posIdx));
    sStd  = squeeze(sig.std(chIdx, chIdx, posIdx));
    sUpper = sMean + 1.96 * sStd;
    sLower = sMean - 1.96 * sStd;

    bMean = squeeze(bias.mean(chIdx, chIdx, posIdx));
    bStd  = squeeze(bias.std(chIdx, chIdx, posIdx));
    bUpper = bMean + 1.96 * bStd;
    bLower = bMean - 1.96 * bStd;

    hold on;
    % Bias
    fill([lags fliplr(lags)], [bUpper' fliplr(bLower')], ...
         [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, bMean, 'k', 'LineWidth', 1.5);

    % Signal
    fill([lags fliplr(lags)], [sUpper' fliplr(sLower')], ...
         faceCol, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, sMean, 'Color', lineCol, 'LineWidth', 2);

    % Significance
    isSig = (sLower > bUpper) | (sUpper < bLower);
    if any(isSig)
        yMax = max([sUpper; bUpper]);
        plot(lags(isSig), repmat(yMax*1.05, sum(isSig), 1), '.', 'Color', [0.2 0.7 0.2]);
    end

    yline(0, '--k');
    xlabel('Lag (s)'); title(label, 'Interpreter', 'none'); grid on; xlim([0, max(lags)]);
    hold off;
end