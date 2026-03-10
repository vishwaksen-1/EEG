function plot_crosscorr_results_visual(results)
% plot_crosscorr_results_visual - Plot seg1–seg3 cross-correlations for each normalization type.
%
%   Layout: 3 rows (seg1–seg3) × 1 column (same reference channel)
%
% Adds:
%   - CI masking (NaN if 0 ∈ [mean - CI, mean + CI])
%   - Keeps full lag range (crosscorr is asymmetric)
%
% Usage:
%   plot_crosscorr_results_visual(results)

    outName = fieldnames(results);
    outName = outName{1}; % assume single Out field
    segFields = fieldnames(results.(outName));
    segFields = segFields(~contains(segFields, 'raw') & ~contains(segFields, 'channels'));

    % Extract normalization types (e.g., subNorm, zNorm)
    normTypes = regexprep(segFields, '^seg[1-3]_?', '');
    normTypes = unique(normTypes(~cellfun(@isempty, normTypes)));

    chNames = results.(outName).channels;
    ccorrExample = results.(outName).(segFields{1}).corr;
    lags = ccorrExample.lags;
    nCh = size(ccorrExample.mean,1);

    for n = 1:numel(normTypes)
        nType = normTypes{n};
        if isempty(nType), continue; end
        fprintf('\n=== Normalization: %s ===\n', nType);

        for i = 1:nCh
            % figure('Color','w', 'Position', [200 200 800 900]);
            figure;
            for s = 1:3
                segName = sprintf('seg%d_%s', s, nType);
                if ~isfield(results.(outName), segName)
                    warning('Missing %s in results.', segName);
                    continue;
                end

                ccorr = results.(outName).(segName).corr;

                % Extract and CI-mask mean correlation
                meanMat = squeeze(ccorr.mean(i,:,:)); % [nCh × nLags]
                stdMat  = squeeze(ccorr.std(i,:,:));  % [nCh × nLags]
                CI = 1.96 * stdMat;

                % CI masking (mask if CI contains 0)
                mask = (meanMat - CI <= 0) & (meanMat + CI >= 0);
                meanMat(mask) = NaN;

                % Self-channel masking (optional)
                meanMat(i,:) = NaN;

                % Plot
                subplot(3,1,s);
                imagesc(lags, 1:nCh, meanMat);
                set(gca, 'YDir', 'normal');
                colormap(jet);
                colorbar;
                clim([-1 1]);
                title(sprintf('Seg %d — %s', s, nType), 'Interpreter', 'none');
                xlabel('Lag (s)');
                ylabel('Channel');
                yticks(1:nCh);
                yticklabels(chNames);
                grid on;

                fprintf('  Seg %d | %s | %s: plotted with CI masking\n', s, nType, chNames{i});
            end

            sgtitle(sprintf('%s — Crosscorr (%s)\nReference: %s', ...
                outName, nType, chNames{i}), 'Interpreter','none');

            fprintf('\n  Showing %s — press any key for next...\n', chNames{i});
            pause;
        end
        close all;
    end

    fprintf('\n✅ Finished plotting all visual cross-correlations (full-lag, CI-masked).\n');
end
