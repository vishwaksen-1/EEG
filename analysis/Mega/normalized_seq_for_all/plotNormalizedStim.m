function [stim1_norm, stim2_norm] = plotNormalizedStim(stimData, datasetName)
% plotNormalizedStim - Normalizes and plots EEG data for two stim conditions
%                      using RMS baseline normalization per channel.
%
% Usage:
%   [stim1_norm, stim2_norm] = plotNormalizedStim(stim12, 'stim12');
%   [stim1_norm, stim2_norm] = plotNormalizedStim(stim34, 'stim34');
%
% Input:
%   stimData      - Struct with fields:
%                     stimData.baseline(time, channel, stim, trial, subject)
%                     stimData.wholestim(time, channel, stim, trial, subject)
%   datasetName   - String used for figure titles (e.g. 'stim12')
%
% Output:
%   stim1_norm, stim2_norm - Normalized data (channels × time) for each stim

    %% --- Parameters ---
    if nargin < 2
        datasetName = 'EEGData';
    end

    numStims = 2;   % expecting two stim conditions
    numCh = size(stimData.channels, 2);

    % Layout for subplot grid
    nRows = ceil(sqrt(numCh));
    nCols = ceil(numCh / nRows);

    % Initialize outputs
    stim1_norm = [];
    stim2_norm = [];

    %% --- Loop through stim conditions ---
    for stimIdx = 1:numStims
        % --- Extract and average baseline & whole stim ---
        bl = mean(stimData.baseline(:,:,stimIdx,:,:), [4,5]);   % avg over trials, subjects
        ws = mean(stimData.whole_stim(:,:,stimIdx,:,:), [4,5]);  % avg over trials, subjects

        % permute to channels × time
        bl = permute(bl, [2,1]);
        ws = permute(ws, [2,1]);

        % --- Compute RMS-normalized data ---
        normData = ws ./ rms(bl, 2);   % divide each channel by its RMS baseline

        % --- Store normalized data ---
        if stimIdx == 1
            stim1_norm = normData;
        elseif stimIdx == 2
            stim2_norm = normData;
        end

        %% --- Plotting ---
        figure('Name', sprintf('%s - Stim %d (Raw vs RMS Normalized)', datasetName, stimIdx), ...
               'Color','w','Position',[100 100 1200 800]);

        for ch = 1:numCh
            subplot(nRows, nCols, ch);
            plot(ws(ch,:), 'b', 'LineWidth', 1.2); hold on;
            plot(normData(ch,:), 'r', 'LineWidth', 1.2);
            title(sprintf('Ch%d Stim%d', ch, stimIdx));
            xlabel('Time'); ylabel('Amplitude');
            legend({'Raw','RMS-Normalized'}, 'Box','off', 'Location','best');
            grid on;
        end
    end

    disp(['✅ RMS normalization and plotting complete for ', datasetName]);
end
