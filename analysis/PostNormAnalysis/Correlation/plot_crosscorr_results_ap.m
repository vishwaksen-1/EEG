function plot_crosscorr_results_ap(active_results, passive_results, ...
                                   activeBaseline_results, passiveBaseline_results, baselineType)
% plot_crosscorr_results_ap - Compare Active vs Passive cross-correlations
%   with CI masking and optional baselines.
%
% Inputs:
%   active_results          : main active cross-corr struct
%   passive_results         : main passive cross-corr struct
%   activeBaseline_results  : baseline active cross-corr struct
%   passiveBaseline_results : baseline passive cross-corr struct
%   baselineType            : 0=duringExp (default), 1=preExp
%
% Each figure shows 4 subplots per reference channel:
%   (1,2,1) Active main
%   (1,2,2) Passive main
%   (2,2,3) Active baseline (optional)
%   (2,2,4) Passive baseline (optional)

    if nargin < 5, baselineType = 0; end
    baseStr = ternary(baselineType == 1, 'preExp_baseline', 'duringExp_baseline');

    outNames = fieldnames(active_results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        stimNames = fieldnames(active_results.(outName));
        stimNames = stimNames(contains(stimNames,'stim') | contains(stimNames,'seg'));
        stimNames = stimNames(~contains(stimNames,'raw'));
        fprintf('\n=== Dataset: %s ===\n', outName);

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            fprintf('  > Stimulus: %s\n', stimName);

            % --- Extract main cross-corr structs ---
            ccorrA = active_results.(outName).(stimName).corr;
            ccorrP = passive_results.(outName).(stimName).corr;
            lags   = ccorrA.lags;
            nCh    = size(ccorrA.mean,1);

            % --- Channel names ---
            if isfield(active_results.(outName),'channels')
                chNames = active_results.(outName).channels;
            else
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end

            % --- Extract baselines (if available) ---
            hasActiveBaseline = true;
            hasPassiveBaseline = true;
            bStim = append('stim', num2str(s), '_baseline');
            if baselineType == 0
                baseA = activeBaseline_results.(baseStr).(bStim).corr;
                baseP = passiveBaseline_results.(baseStr).(bStim).corr;
            else
                baseA = activeBaseline_results.(baseStr).corr;
                baseP = passiveBaseline_results.(baseStr).corr;
            end

            % --- Loop through reference channels ---
            for i = 1:nCh
                figure('Color','w');

                % ===== ACTIVE main =====
                subplot(2,2,1);
                plot_crosscorr_heat(ccorrA, lags, nCh, chNames, i, 'Active', lags);

                % ===== PASSIVE main =====
                subplot(2,2,2);
                plot_crosscorr_heat(ccorrP, lags, nCh, chNames, i, 'Passive', lags);

                % ===== ACTIVE baseline =====
                if hasActiveBaseline
                    subplot(2,2,3);
                    plot_crosscorr_heat(baseA, baseA.lags, nCh, chNames, i, ...
                        sprintf('Active baseline (%s)', baseStr), lags);
                end

                % ===== PASSIVE baseline =====
                if hasPassiveBaseline
                    subplot(2,2,4);
                    plot_crosscorr_heat(baseP, baseP.lags, nCh, chNames, i, ...
                        sprintf('Passive baseline (%s)', baseStr), lags);
                end

                sgtitle(sprintf('%s — %s\nCrosscorr: %s vs all channels', ...
                    outName, stimName, chNames{i}), 'Interpreter','none');

                fprintf('    Showing %s vs all — press any key for next...\n', chNames{i});
                pause;
            end
            close all;
        end
    end

    fprintf('\n✅ Finished plotting all Active vs Passive cross-correlations with baselines.\n');
end


% ===== Helper: CI-masked heatmap with padded lag range =====
function plot_crosscorr_heat(ccorr, lags, nCh, chNames, refIdx, titleStr, fullLagRange)
    meanVals = squeeze(ccorr.mean(refIdx,:,:));
    stdVals  = squeeze(ccorr.std(refIdx,:,:));
    CI = 1.96 * stdVals;

    % Mask where CI crosses zero
    mask = (meanVals - CI <= 0) & (meanVals + CI >= 0);
    meanVals(mask) = NaN;
    meanVals(refIdx,:) = NaN;

    % Pad to match full lag range
    if numel(lags) < numel(fullLagRange)
        padLeft  = sum(fullLagRange < min(lags));
        padRight = sum(fullLagRange > max(lags));
        meanVals = [nan(size(meanVals,1), padLeft), meanVals, nan(size(meanVals,1), padRight)];
    end

    imagesc(fullLagRange, 1:nCh, meanVals);
    set(gca,'YDir','normal');
    colormap(jet);
    colorbar;
    clim([-1 1]);
    xlabel('Lag (s)');
    ylabel('Channel');
    yticks(1:nCh);
    yticklabels(chNames);
    title(sprintf('%s — %s vs all', titleStr, chNames{refIdx}),'Interpreter','none');
    xlim([min(fullLagRange) max(fullLagRange)]);

    % --- Mark valid baseline range for visual clarity ---
    if contains(lower(titleStr),'baseline')
        hold on;
        xline(-0.5,'--w','LineWidth',1.2);
        xline(0.5,'--w','LineWidth',1.2);
        hold off;
    end
end


% ===== Small inline ternary helper =====
function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
end
