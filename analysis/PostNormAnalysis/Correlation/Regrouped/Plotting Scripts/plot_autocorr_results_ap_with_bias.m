function plot_autocorr_results_ap_with_bias(active_results, passive_results, active_bias, passive_bias)
% plot_autocorr_results_ap_with_bias - Compare Active vs Passive with Bias Overlay
%
% Layout (2x2):
%   Active Ch1   | Active Ch2
%   Passive Ch1  | Passive Ch2
%
% **Includes fix to center-crop bias data to match signal length.**

    outNames = fieldnames(active_results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        % Filter stim fields
        fields = fieldnames(active_results.(outName));
        stimNames = fields(contains(fields, 'subTrialNorm'));

        fprintf('\n=== Dataset: %s ===\n', outName);

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            fprintf('  > Stimulus: %s\n', stimName);

            % --- Data Fetching ---
            sigA = active_results.(outName).(stimName).corr;
            sigP = passive_results.(outName).(stimName).corr;
            
            % Check Biases
            if ~isfield(active_bias.(outName), stimName) || ~isfield(passive_bias.(outName), stimName)
                warning('Bias missing for %s', stimName); continue;
            end
            biasA = active_bias.(outName).(stimName);
            biasP = passive_bias.(outName).(stimName);
            
            % --- FIX: Center-Crop Biases to match Signal length ---
            nSig = length(sigA.lags); % Assume A and P have same signal length
            
            % Crop Active Bias
            nBiasA = size(biasA.mean, 3);
            if nBiasA > nSig
                diff = nBiasA - nSig; startIdx = floor(diff/2) + 1; cropIdx = startIdx:(startIdx+nSig-1);
                biasA.mean = biasA.mean(:,:,cropIdx); biasA.std = biasA.std(:,:,cropIdx);
            end
            
            % Crop Passive Bias
            nBiasP = size(biasP.mean, 3);
            if nBiasP > nSig
                diff = nBiasP - nSig; startIdx = floor(diff/2) + 1; cropIdx = startIdx:(startIdx+nSig-1);
                biasP.mean = biasP.mean(:,:,cropIdx); biasP.std = biasP.std(:,:,cropIdx);
            end
            % ------------------------------------------------------
            
            lags = sigA.lags;
            nCh = size(sigA.mean, 1);
            % pairCount = floor(nCh / 2);
            
            % Labels
            if isfield(biasA, 'regionLabels')
                chNames = biasA.regionLabels;
            else
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end

            posIdx = lags >= 0;
            lags = lags(posIdx);

            for i = 1:2:nCh
                ch1 = i;
                ch2 = i+1;

                figure('Color', 'w', 'Position', [100, 100, 1000, 700]);

                % === ACTIVE ROW ===
                subplot(2,2,1);
                plot_overlay(sigA, biasA, ch1, lags, posIdx, ...
                    sprintf('Active - %s', chNames{ch1}), 'b', [0.7 0.85 1]);

                subplot(2,2,2);
                plot_overlay(sigA, biasA, ch2, lags, posIdx, ...
                    sprintf('Active - %s', chNames{ch2}), 'r', [1 0.8 0.8]);

                % === PASSIVE ROW ===
                subplot(2,2,3);
                plot_overlay(sigP, biasP, ch1, lags, posIdx, ...
                    sprintf('Passive - %s', chNames{ch1}), 'b', [0.8 0.9 1]);

                subplot(2,2,4);
                plot_overlay(sigP, biasP, ch2, lags, posIdx, ...
                    sprintf('Passive - %s', chNames{ch2}), 'r', [1 0.85 0.85]);

                sgtitle(sprintf('%s — %s\nActive vs Passive | %s & %s', ...
                    outName, stimName, chNames{ch1}, chNames{ch2}), 'Interpreter','none');

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
    fill([lags fliplr(lags)], [bUpper' fliplr(bLower')], [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, bMean, 'k', 'LineWidth', 1.5);
    % Signal
    fill([lags fliplr(lags)], [sUpper' fliplr(sLower')], faceCol, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, sMean, 'Color', lineCol, 'LineWidth', 2);
    % Sig
    isSig = (sLower > bUpper) | (sUpper < bLower);
    if any(isSig)
        yMax = max([sUpper; bUpper]);
        plot(lags(isSig), repmat(yMax*1.05, sum(isSig), 1), '.', 'Color', [0.2 0.7 0.2]);
    end
    yline(0, '--k'); xlabel('Lag (s)'); title(label, 'Interpreter', 'none'); grid on; xlim([0, max(lags)]);
    hold off;
end