function plot_autocorr_results_visual_with_bias(results, bias_results)
% plot_autocorr_results_visual_with_bias
%
%   Assumes fields: seg1_*, seg2_*, seg3_*
%   Layout: 3 rows (Seg1, Seg2, Seg3) x 2 cols (Ch Pair)
%   **Includes fix to center-crop bias data to match signal length.**

    outName = fieldnames(results);
    outName = outName{1}; 
    
    % Find normalization types from seg fields
    fields = fieldnames(results.(outName));
    segFields = fields(contains(fields, 'seg'));
    % Extract suffix (e.g., _subTrialNorm)
    suffixes = unique(regexprep(segFields, '^seg[1-3]', ''));
    
    for sIdx = 1:numel(suffixes)
        suffix = suffixes{sIdx}; % e.g. "_subTrialNorm"
        fprintf('\n=== Norm Type: %s ===\n', suffix);
        
        % Check if bias exists for these
        testSeg = ['seg1' suffix];
        if ~isfield(bias_results.(outName), testSeg)
            warning('Bias missing for %s', testSeg); continue;
        end
        
        biasEx = bias_results.(outName).(testSeg);
        sigEx  = results.(outName).(testSeg).corr;
        
        lags = sigEx.lags;
        posIdx = lags >= 0;
        lags = lags(posIdx);
        nCh = size(sigEx.mean, 1);
        % pairCount = floor(nCh/2);
        
        if isfield(biasEx, 'regionLabels'), chNames = biasEx.regionLabels;
        else, chNames = arrayfun(@(x) sprintf('Ch%d',x), 1:nCh, 'UniformOutput',false); end
        
        for i = 1:2:nCh
            ch1 = i; ch2 = i+1;
            figure('Color','w','Position',[50,50,1000,900]);
            
            for segNum = 1:3
                segName = sprintf('seg%d%s', segNum, suffix);
                if ~isfield(results.(outName), segName), continue; end
                
                sig = results.(outName).(segName).corr;
                bias = bias_results.(outName).(segName);
                
                % --- FIX: Crop Bias ---
                nSig = length(sig.lags);
                if size(bias.mean,3) > nSig
                    diff = size(bias.mean,3) - nSig; sI = floor(diff/2)+1; cI = sI:(sI+nSig-1);
                    bias.mean = bias.mean(:,:,cI); bias.std = bias.std(:,:,cI);
                end
                % ----------------------
                
                % Left Col (Ch1)
                subplot(3, 2, (segNum-1)*2 + 1);
                plot_overlay(sig, bias, ch1, lags, posIdx, ...
                    sprintf('Seg %d - %s', segNum, chNames{ch1}), 'b', [0.7 0.85 1]);
                
                % Right Col (Ch2)
                subplot(3, 2, (segNum-1)*2 + 2);
                plot_overlay(sig, bias, ch2, lags, posIdx, ...
                    sprintf('Seg %d - %s', segNum, chNames{ch2}), 'r', [1 0.8 0.8]);
            end
            
            sgtitle(sprintf('%s %s\nChannels: %s & %s', outName, suffix, chNames{ch1}, chNames{ch2}), 'Interpreter','none');
            pause;
        end
        close all;
    end
end

function plot_overlay(sig, bias, chIdx, lags, posIdx, label, lineCol, faceCol)
    sMean = squeeze(sig.mean(chIdx, chIdx, posIdx));
    sStd  = squeeze(sig.std(chIdx, chIdx, posIdx));
    sU = sMean + 1.96*sStd; sL = sMean - 1.96*sStd;

    bMean = squeeze(bias.mean(chIdx, chIdx, posIdx));
    bStd  = squeeze(bias.std(chIdx, chIdx, posIdx));
    bU = bMean + 1.96*bStd; bL = bMean - 1.96*bStd;

    hold on;
    fill([lags fliplr(lags)], [bU' fliplr(bL')], [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, bMean, 'k', 'LineWidth', 1.5);
    fill([lags fliplr(lags)], [sU' fliplr(sL')], faceCol, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(lags, sMean, 'Color', lineCol, 'LineWidth', 2);

    isSig = (sL > bU) | (sU < bL);
    if any(isSig)
        yMax = max([sU; bU]);
        plot(lags(isSig), repmat(yMax*1.05, sum(isSig), 1), '.', 'Color', [0.2 0.7 0.2]);
    end
    yline(0, '--k'); title(label, 'Interpreter', 'none'); grid on; xlim([0, max(lags)]);
    hold off;
end