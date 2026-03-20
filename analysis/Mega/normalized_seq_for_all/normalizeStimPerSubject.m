function normOut = normalizeStimPerSubject(stimData, datasetName, full)
% normalizeStimPerSubject - Thorough per-subject & global baseline normalization
%
% Outputs in normOut:
%   .channels                      : 1x14 cell of channel labels
%   .stim1_zscore                  : [numSubjects x numChannels x numTime]
%   .stim1_subNorm                 : [numSubjects x numChannels x numTime]
%   .stim1_subTrialNorm            : [numSubjects x numChannels x numTime]
%   (Similarly for Stim 2)
%
% Notes:
%  - Input dims: time x channel x stim x trials x subjects
%  - Baseline normalization is done per subject using the isolated baseline field

    if nargin < 2
        datasetName = 'EEGData';
    end

    %% --- Channel names ---
    % Grab from struct if available, otherwise use default
    channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2', ...
                'P8','T8','FC6','F4','F8','AF4'};

    %% --- Field name detection ---
    if full == 1
        wholeField = 'full_trial';
    else
        wholeField = 'whole_stim';
    end

    %% --- Sizes ---
    sample_whole = stimData.(wholeField);
    numTime     = size(sample_whole, 1);
    numCh       = size(sample_whole, 2);
    numStims    = size(sample_whole, 3);      % typically 2
    numTrials   = size(sample_whole, 4);
    numSubjects = size(sample_whole, 5);

    if numCh ~= length(channels)
        warning('Channel count mismatch. Adjusting label length.');
        channels = channels(1:min(numCh,length(channels)));
    end

    %% --- Pre-allocate storage ---
    stim1_zscore = NaN(numSubjects, numCh, numTime);
    stim2_zscore = NaN(numSubjects, numCh, numTime);
    stim1_subNorm = NaN(numSubjects, numCh, numTime);
    stim2_subNorm = NaN(numSubjects, numCh, numTime);
    stim1_subTrialNorm = NaN(numSubjects, numCh, numTime);
    stim2_subTrialNorm = NaN(numSubjects, numCh, numTime);

    %% --- Parameters ---
    fs = 256;  % sampling rate
    baselineSamples = round(0.9 * fs);  % 900 ms baseline

    %% --- Compute per-subject measures ---
    for stimIdx = 1:numStims
        for subjIdx = 1:numSubjects
            % Extract subject data for this stim: time x channel x trials
            ws_trials = squeeze(stimData.(wholeField)(:, :, stimIdx, :, subjIdx));
            bl_trials = squeeze(stimData.baseline(:, :, stimIdx, :, subjIdx));

            % Average across trials
            ws_mean_trials = mean(ws_trials, 3, 'omitnan');   % time x ch
            bl_mean_trials = mean(bl_trials, 3, 'omitnan');   % time(baseline) x ch

            % permute to ch x time
            ws_ch_time = permute(ws_mean_trials, [2,1]);
            bl_ch_time = permute(bl_mean_trials, [2,1]);

            %% --- 1. NEW: Z-Score Normalization ---
            % (raw - mean(baseline)) / std(baseline)
            % Calculated per channel over the trial-averaged baseline time window
            bl_mean_sub = mean(bl_ch_time, 2, 'omitnan');     % ch x 1
            bl_std_sub  = std(bl_ch_time, 0, 2, 'omitnan');   % ch x 1

            % Avoid division by zero if std is perfectly 0 (rare in EEG, but safe)
            bl_std_sub(bl_std_sub == 0) = eps;

            norm_zscore = (ws_ch_time - bl_mean_sub) ./ bl_std_sub; % ch x time

            %% --- 2. Per-subject baseline RMS normalization ---
            % Normalizes each subject individually with their own baseline RMS
            bl_rms_sub = rms(bl_ch_time, 2, 'omitnan');   % ch x 1
            bl_rms_sub(bl_rms_sub == 0) = eps;            % Safety check
            norm_sub = ws_ch_time ./ bl_rms_sub;          % ch x time

            %% --- 3. Per-trial baseline normalization ---
            trialwise_rms = zeros(numCh, numTrials);
            for trialIdx = 1:numTrials
                % Use the first 900ms of the full trial for this normalization
                trial_data = ws_trials(:, :, trialIdx);           % time x ch
                baseline_win = trial_data(1:baselineSamples, :);  % baseline part
                trialwise_rms(:, trialIdx) = rms(baseline_win, 1, 'omitnan')'; % ch x 1
            end

            % Average RMS of trialwise baselines (per channel)
            baseline_rms_avg = mean(trialwise_rms, 2, 'omitnan');  % ch x 1
            baseline_rms_avg(baseline_rms_avg == 0) = eps;         % Safety check

            % Normalize averaged waveform by average of trialwise baseline RMS
            norm_subTrial = ws_ch_time ./ baseline_rms_avg;

            %% --- Save to arrays ---
            if stimIdx == 1
                stim1_zscore(subjIdx, :, :) = norm_zscore;
                stim1_subNorm(subjIdx, :, :) = norm_sub;
                stim1_subTrialNorm(subjIdx, :, :) = norm_subTrial;
            else
                stim2_zscore(subjIdx, :, :) = norm_zscore;
                stim2_subNorm(subjIdx, :, :) = norm_sub;
                stim2_subTrialNorm(subjIdx, :, :) = norm_subTrial;
            end
        end
    end

    %% --- Package output ---
    normOut = struct();
    normOut.channels = channels;
    normOut.stim1_zscore = stim1_zscore;
    normOut.stim1_subNorm = stim1_subNorm;
    normOut.stim1_subTrialNorm = stim1_subTrialNorm;
    normOut.stim2_zscore = stim2_zscore;
    normOut.stim2_subNorm = stim2_subNorm;
    normOut.stim2_subTrialNorm = stim2_subTrialNorm;

    fprintf('✅ Normalization complete.\n');
end
