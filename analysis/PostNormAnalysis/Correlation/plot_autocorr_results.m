function plot_autocorr_results(results)
% plot_autocorr_results - Plot bootstrap mean ±95% CI of autocorrelation
%   for symmetric channel pairs across all stims in the results struct.
%
%   Each channel pair (i, 14-i+1) is plotted as two side-by-side subplots.
%   The figure title (sgtitle) shows the dataset, stimulus, and channel pair.
%
% Usage:
%   plot_autocorr_results(results)
%
% Input:
%   results : output struct from main_corrAcrr.m
%
% Notes:
%   - 95% CI = mean ± 1.96 * std
%   - Pauses after each figure
% ------------------------------------------------------------

    outNames = fieldnames(results);

    for o = 1:numel(outNames)
        outName = outNames{o};
        stimNames = fieldnames(results.(outName));
        stimNames = stimNames(contains(stimNames, 'stim') | contains(stimNames, 'seg'));
        stimNames = stimNames(~contains(stimNames,'raw'));

        fprintf('\n=== Dataset: %s ===\n', outName);

        for s = 1:numel(stimNames)
            stimName = stimNames{s};
            acorr = results.(outName).(stimName).acorr;

            lags = acorr.lags;
            nCh = size(acorr.mean, 1);
            pairCount = floor(nCh / 2);

            % Channel names (if available)
            if isfield(results.(outName), 'channels')
                chNames = results.(outName).channels;
            else
                chNames = arrayfun(@(x) sprintf('Ch%d', x), 1:nCh, 'UniformOutput', false);
            end

            fprintf('  > Stimulus: %s\n', stimName);

            for i = 1:pairCount
                ch1 = i;
                ch2 = nCh - i + 1;

                % Extract mean & std
                mean1 = squeeze(acorr.mean(ch1, :));
                mean2 = squeeze(acorr.mean(ch2, :));
                std1  = squeeze(acorr.std(ch1, :));
                std2  = squeeze(acorr.std(ch2, :));

                % Compute 95% CI
                CI1 = 1.96 * std1;
                CI2 = 1.96 * std2;

                % --- Create figure with subplots ---
                % figure('Name', sprintf('%s - %s | %s & %s', ...
                %         outName, stimName, chNames{ch1}, chNames{ch2}), ...
                %        'NumberTitle', 'off', 'Color', 'w');
                figure;

                % ----- Subplot 1: Channel ch1 -----
                subplot(1, 2, 1);
                hold on;
                fill([lags fliplr(lags)], [mean1 + CI1 fliplr(mean1 - CI1)], ...
                     [0.7 0.85 1], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
                plot(lags, mean1, 'b', 'LineWidth', 2);
                hold off;
                xlabel('Lag (s)');
                ylabel('Autocorrelation');
                title(chNames{ch1}, 'Interpreter', 'none');
                grid on;

                % ----- Subplot 2: Channel ch2 -----
                subplot(1, 2, 2);
                hold on;
                fill([lags fliplr(lags)], [mean2 + CI2 fliplr(mean2 - CI2)], ...
                     [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
                plot(lags, mean2, 'r', 'LineWidth', 2);
                hold off;
                xlabel('Lag (s)');
                ylabel('Autocorrelation');
                title(chNames{ch2}, 'Interpreter', 'none');
                grid on;

                % Super-title
                sgtitle(sprintf('%s — %s\nAutocorrelation Pair: %s & %s', ...
                    outName, stimName, chNames{ch1}, chNames{ch2}), ...
                    'Interpreter', 'none');

                % Pause for inspection
                fprintf('    Showing %s & %s — press any key for next...\n', ...
                        chNames{ch1}, chNames{ch2});
                pause;
                % close; % close figure to keep clean
            end
            close all;
        end
    end

    fprintf('\n✅ Finished plotting all autocorrelations.\n');
end
