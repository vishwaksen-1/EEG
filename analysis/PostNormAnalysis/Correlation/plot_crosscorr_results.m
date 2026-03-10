function plot_crosscorr_results(results)
% plot_crosscorr_results - Display cross-correlation mean ±95% CI as imagesc
%   (with CI masking)
%
% Usage:
%   plot_crosscorr_results(results)
%
% Description:
%   For each dataset (Out*), each stimulus (stim*), and each reference
%   channel i, this plots the cross-correlation of i vs. all other channels
%   as a heatmap (imagesc).
%
%   X-axis: Lag (s)
%   Y-axis: Channel index (or name)
%   Color:  Mean correlation coefficient
%
%   Any (mean ± 1.96×std) range that crosses zero is masked as NaN.

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

            lags = ccorr.lags;
            nCh = size(ccorr.mean, 1);

            % Channel names if available
            if isfield(results.(outName), 'channels')
                chNames = results.(outName).channels;
            else
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end

            fprintf('  > Stimulus: %s\n', stimName);

            for i = 1:nCh
                figure('Color','w');
                
                % ===== Compute mean and CI =====
                meanMat = squeeze(ccorr.mean(i,:,:)); % [nCh x nLags]
                stdMat  = squeeze(ccorr.std(i,:,:));  % [nCh x nLags]
                CI = 1.96 * stdMat;

                % ===== CI-based masking =====
                mask = (meanMat - CI <= 0) & (meanMat + CI >= 0);
                meanMat(mask) = NaN;

                % Mask self-correlation if desired
                meanMat(i,:) = NaN;

                % ===== Plot heatmap =====
                imagesc(lags, 1:nCh, meanMat);
                set(gca, 'YDir', 'normal');
                colormap(jet);
                colorbar;
                clim([-1 1]); % correlation range

                title(sprintf('%s — %s\nCrosscorr: %s vs all channels (CI-masked)', ...
                      outName, stimName, chNames{i}), 'Interpreter', 'none');
                xlabel('Lag (s)');
                ylabel('Channel');
                yticks(1:nCh);
                yticklabels(chNames);

                fprintf('    Showing %s vs all (CI-masked) — press any key for next...\n', chNames{i});
                pause;
            end
            close all;
        end
    end

    fprintf('\n✅ Finished plotting all cross-correlations (CI-masked).\n');
end
