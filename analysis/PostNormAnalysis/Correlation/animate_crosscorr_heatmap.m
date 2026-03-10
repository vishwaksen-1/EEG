function animate_crosscorr_heatmap(results, step, pauseDur)
% Animate cross-correlation heatmap with CI-based masking
%
% Masks entries where the 95% confidence interval crosses zero:
%   mean ± 1.96*std contains zero  ->  set to NaN

    if nargin < 2, step = 5; end
    if nargin < 3, pauseDur = 0.2; end

    outNames = fieldnames(results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        stimNames = fieldnames(results.(outName));
        stimNames = stimNames(contains(stimNames,'stim') | contains(stimNames,'seg'));
        stimNames = stimNames(~contains(stimNames,'raw'));

        fprintf('\n=== Dataset: %s ===\n', outName);

        for s = 1:numel(stimNames)
            stimName = stimNames{s};

            ccorr = results.(outName).(stimName).corr;

            corrMean = ccorr.mean;     % [14×14×nLags]
            corrStd  = ccorr.std;      % [14×14×nLags]

            lags = ccorr.lags;
            nLags = numel(lags);
            nCh = size(corrMean,1);

            % --- Compute 95% CI ---
            z = 1.96;
            lowerCI = corrMean - z * corrStd;
            upperCI = corrMean + z * corrStd;

            % Region to mask: CI crosses zero
            maskZeroCI = (lowerCI <= 0) & (upperCI >= 0);

            % Channel labels
            if isfield(results.(outName), 'channels')
                chNames = results.(outName).channels;
            else
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end

            % --- Create figure ---
            figure;
            colormap('jet');

            % consistent color limits
            clims = [min(corrMean(:)), max(corrMean(:))];

            for k = 1:step:nLags

                % ----- MASKING -----
                M = corrMean(:,:,k);

                % Option A (default): mask to NaN
                M(maskZeroCI(:,:,k)) = NaN;

                % Option B: mask to -1 (if you prefer)
                % M(maskZeroCI(:,:,k)) = -1;

                % AlphaData = 1 for good values, 0 for NaN
                alpha = ~isnan(M);

                imagesc(M, 'AlphaData', alpha);

                set(gca, 'XTick', 1:nCh, 'XTickLabel', chNames, ...
                         'YTick', 1:nCh, 'YTickLabel', chNames, ...
                         'XTickLabelRotation', 45);

                cb = colorbar;
                cb.Label.String = 'Cross-correlation';

                clim(clims);
                axis square tight;
                title(sprintf('%s — %s\nCross-Corr (masked) at Lag = %.3f s', ...
                      outName, stimName, lags(k)), 'Interpreter', 'none');

                drawnow;
                pause(pauseDur);
            end

            close;
        end
    end

    fprintf('\n✅ Finished animating masked cross-correlation heatmaps.\n');
end
