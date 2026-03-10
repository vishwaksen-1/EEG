function plot_autocorr_periodic_vs_aperiodic_with_bias(results, bias_results)
% plot_autocorr_periodic_vs_aperiodic_with_bias
%
%   Layout:
%     Periodic Ch1  | Periodic Ch2
%     Aperiodic Ch1 | Aperiodic Ch2
%
%   **Includes fix to center-crop bias data to match signal length.**

    outNames = fieldnames(results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        fields = fieldnames(results.(outName));
        stimNames = fields(contains(fields, 'subTrialNorm'));
        
        % Identify periodic (odd) and aperiodic (even) stims
        pStims = stimNames(~cellfun(@isempty, regexp(stimNames, 'stim[13]')));
        aStims = stimNames(~cellfun(@isempty, regexp(stimNames, 'stim[24]')));

        if isempty(pStims) || isempty(aStims)
            continue; 
        end
        
        % Use first pair found for plotting
        pStim = pStims{1};
        aStim = aStims{1};
        
        % --- Data ---
        sigP = results.(outName).(pStim).corr;
        biasP = bias_results.(outName).(pStim);
        
        sigA = results.(outName).(aStim).corr;
        biasA = bias_results.(outName).(aStim);
        
        % --- FIX: Crop Biases ---
        nSig = length(sigP.lags);
        
        if size(biasP.mean,3) > nSig
            diff = size(biasP.mean,3) - nSig; sI = floor(diff/2)+1; cI = sI:(sI+nSig-1);
            biasP.mean = biasP.mean(:,:,cI); biasP.std = biasP.std(:,:,cI);
        end
        
        if size(biasA.mean,3) > nSig
            diff = size(biasA.mean,3) - nSig; sI = floor(diff/2)+1; cI = sI:(sI+nSig-1);
            biasA.mean = biasA.mean(:,:,cI); biasA.std = biasA.std(:,:,cI);
        end
        % ------------------------
        
        lags = sigP.lags;
        posIdx = lags >= 0;
        lags = lags(posIdx);
        
        nCh = size(sigP.mean,1);
        % pairCount = floor(nCh/2);
        
        if isfield(biasP, 'regionLabels'), chNames = biasP.regionLabels; 
        else, chNames = arrayfun(@(x) sprintf('Ch%d',x), 1:nCh, 'UniformOutput',false); end

        fprintf('\n=== %s: %s vs %s ===\n', outName, pStim, aStim);

        for i = 1:2:nCh
            
            ch1 = i; ch2 = i + 1;
            
            figure('Color', 'w', 'Position', [100, 100, 1000, 700]);
            
            % --- Periodic ---
            subplot(2,2,1);
            plot_overlay(sigP, biasP, ch1, lags, posIdx, ...
                sprintf('Periodic (%s) - %s', pStim, chNames{ch1}), 'b', [0.7 0.85 1]);
            
            subplot(2,2,2);
            plot_overlay(sigP, biasP, ch2, lags, posIdx, ...
                sprintf('Periodic (%s) - %s', pStim, chNames{ch2}), 'r', [1 0.8 0.8]);
                
            % --- Aperiodic ---
            subplot(2,2,3);
            plot_overlay(sigA, biasA, ch1, lags, posIdx, ...
                sprintf('Aperiodic (%s) - %s', aStim, chNames{ch1}), 'b', [0.8 0.9 1]);
            
            subplot(2,2,4);
            plot_overlay(sigA, biasA, ch2, lags, posIdx, ...
                sprintf('Aperiodic (%s) - %s', aStim, chNames{ch2}), 'r', [1 0.85 0.85]);
            
            sgtitle(sprintf('%s — Periodic vs Aperiodic\nChannels: %s & %s', ...
                outName, chNames{ch1}, chNames{ch2}), 'Interpreter','none');
            pause;
        end
        close all;
    end
end

function plot_overlay(sig, bias, chIdx, lags, posIdx, label, lineCol, faceCol)
    sMean = squeeze(sig.mean(chIdx, chIdx, posIdx));
    sStd  = squeeze(sig.std(chIdx, chIdx, posIdx));
    sUpper = sMean + 1.96 * sStd; sLower = sMean - 1.96 * sStd;

    bMean = squeeze(bias.mean(chIdx, chIdx, posIdx));
    bStd  = squeeze(bias.std(chIdx, chIdx, posIdx));
    bUpper = bMean + 1.96 * bStd; bLower = bMean - 1.96 * bStd;

    hold on;
    fill([lags fliplr(lags)], [bUpper' fliplr(bLower')], [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, bMean, 'k', 'LineWidth', 1.5);
    fill([lags fliplr(lags)], [sUpper' fliplr(sLower')], faceCol, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, sMean, 'Color', lineCol, 'LineWidth', 2);
    
    isSig = (sLower > bUpper) | (sUpper < bLower);
    if any(isSig)
        yMax = max([sUpper; bUpper]);
        plot(lags(isSig), repmat(yMax*1.05, sum(isSig), 1), '.', 'Color', [0.2 0.7 0.2]);
    end
    yline(0, '--k'); xlabel('Lag (s)'); title(label, 'Interpreter', 'none'); grid on; xlim([0, max(lags)]);
    hold off;
end