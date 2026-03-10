function plot_autocorr_periodic_ap_with_bias(actRes, pasRes, actBias, pasBias)
% plot_autocorr_periodic_ap_with_bias
%
% Layout:
%   Periodic Active   | Periodic Passive
%   Aperiodic Active  | Aperiodic Passive
%
% **Includes fix to center-crop bias data to match signal length.**

    outNames = fieldnames(actRes);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        fA = fieldnames(actRes.(outName));
        pStims = fA(~cellfun(@isempty, regexp(fA, 'stim[13].*subTrialNorm')));
        aStims = fA(~cellfun(@isempty, regexp(fA, 'stim[24].*subTrialNorm')));
        
        if isempty(pStims) || isempty(aStims), continue; end
        pStim = pStims{1}; 
        aStim = aStims{1};

        % Get One Example for dims
        sigEx = actRes.(outName).(pStim).corr;
        lags = sigEx.lags;
        posIdx = lags >= 0;
        lags = lags(posIdx);
        nCh = size(sigEx.mean,1);
        
        % --- Crop Data Helper ---
        % We need to crop 4 bias datasets: Act-P, Pas-P, Act-A, Pas-A
        bActP = crop_bias(actBias.(outName).(pStim), sigEx);
        bPasP = crop_bias(pasBias.(outName).(pStim), sigEx);
        bActA = crop_bias(actBias.(outName).(aStim), sigEx);
        bPasA = crop_bias(pasBias.(outName).(aStim), sigEx);
        
        if isfield(actBias.(outName).(pStim), 'regionLabels')
            chNames = actBias.(outName).(pStim).regionLabels;
        else
            chNames = arrayfun(@(x) sprintf('Ch%d',x), 1:nCh, 'UniformOutput',false);
        end

        fprintf('\n=== %s ===\n', outName);
        
        for ch = 1:nCh
            figure('Color','w','Position',[100,100,1000,700]);
            
            % 1. Periodic Active
            plot_sub(actRes.(outName).(pStim).corr, bActP, ...
                     ch, lags, posIdx, 2,2,1, 'Periodic Active', 'b', [0.7 0.85 1]);
                     
            % 2. Periodic Passive
            plot_sub(pasRes.(outName).(pStim).corr, bPasP, ...
                     ch, lags, posIdx, 2,2,2, 'Periodic Passive', 'r', [1 0.8 0.8]);
                     
            % 3. Aperiodic Active
            plot_sub(actRes.(outName).(aStim).corr, bActA, ...
                     ch, lags, posIdx, 2,2,3, 'Aperiodic Active', 'b', [0.8 0.9 1]);
                     
            % 4. Aperiodic Passive
            plot_sub(pasRes.(outName).(aStim).corr, bPasA, ...
                     ch, lags, posIdx, 2,2,4, 'Aperiodic Passive', 'r', [1 0.85 0.85]);
            
            sgtitle(sprintf('%s — %s', outName, chNames{ch}), 'Interpreter','none');
            pause;
        end
        close all;
    end
end

function biasStruct = crop_bias(biasStruct, sigStruct)
    nSig = length(sigStruct.lags);
    nBias = size(biasStruct.mean, 3);
    if nBias > nSig
        diff = nBias - nSig;
        startIdx = floor(diff/2) + 1;
        cropIdx = startIdx : (startIdx + nSig - 1);
        biasStruct.mean = biasStruct.mean(:, :, cropIdx);
        biasStruct.std  = biasStruct.std(:, :, cropIdx);
    end
end

function plot_sub(sig, bias, chIdx, lags, posIdx, nr, nc, idx, label, lc, fc)
    subplot(nr, nc, idx);
    
    sMean = squeeze(sig.mean(chIdx, chIdx, posIdx));
    sStd  = squeeze(sig.std(chIdx, chIdx, posIdx));
    sU = sMean + 1.96*sStd; sL = sMean - 1.96*sStd;
    
    bMean = squeeze(bias.mean(chIdx, chIdx, posIdx));
    bStd  = squeeze(bias.std(chIdx, chIdx, posIdx));
    bU = bMean + 1.96*bStd; bL = bMean - 1.96*bStd;
    
    hold on;
    fill([lags fliplr(lags)], [bU' fliplr(bL')], [0.8 0.8 0.8], 'EdgeColor','none','FaceAlpha',0.5);
    plot(lags, bMean, 'k', 'LineWidth', 1.5);
    fill([lags fliplr(lags)], [sU' fliplr(sL')], fc, 'EdgeColor','none','FaceAlpha',0.5);
    plot(lags, sMean, 'Color', lc, 'LineWidth', 2);
    
    isSig = (sL > bU) | (sU < bL);
    if any(isSig)
        yMax = max([sU; bU]);
        plot(lags(isSig), repmat(yMax*1.05, sum(isSig), 1), '.', 'Color', [0.2 0.7 0.2]);
    end
    yline(0, '--k'); title(label); grid on; xlim([0, max(lags)]);
    hold off;
end