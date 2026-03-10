function normOut = normalizeStimPerSubject(stimData, datasetName)
% normalizeStimPerSubject - Thorough per-subject & global baseline normalization
%
% Usage:
%   normOut = normalizeStimPerSubject(stim12, 'stim12');
%
% Outputs in normOut:
%   .channels                      : 1x14 cell of channel labels
%   .stim1_raw                     : [numSubjects x numChannels x numTime]
%   .stim1_subNorm                 : [numSubjects x numChannels x numTime]
%   .stim1_subTrialNorm            : [numSubjects x numChannels x numTime]
%   (Similarly for Stim 2)
%
% Notes:
%  - Input dims: time x channel x stim x trials x subjects
%  - Baseline normalization is done per subject
%
% Author: adapted for your requirements

    if nargin < 2
        datasetName = 'EEGData';
    end

    %% --- Channel names ---
    channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2', ...
                'P8','T8','FC6','F4','F8','AF4'};

    %% --- Field name detection ---
    if isfield(stimData, 'full_trial')
        wholeField = 'full_trial';
    else
        error('stimData must contain field ''full_trial'' or ''full_trial''.');
    end
    if ~isfield(stimData, 'baseline')
        error('stimData must contain field ''baseline''.');
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
    stim1_raw = NaN(numSubjects, numCh, numTime);
    stim2_raw = NaN(numSubjects, numCh, numTime);
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
            bl_mean_trials = mean(bl_trials, 3, 'omitnan');   % time x ch

            % permute to ch x time
            ws_ch_time = permute(ws_mean_trials, [2,1]);
            bl_ch_time = permute(bl_mean_trials, [2,1]);

            % Store raw
            if stimIdx == 1
                stim1_raw(subjIdx, :, :) = ws_ch_time;
            else
                stim2_raw(subjIdx, :, :) = ws_ch_time;
            end

            %% --- Per-subject baseline RMS normalization (already existing) ---
            bl_rms_sub = rms(bl_ch_time, 2, 'omitnan');   % ch x 1
            norm_sub = ws_ch_time ./ bl_rms_sub;          % ch x time

            %% --- NEW: Per-trial baseline - its 900 m s normalization ---
            trialwise_rms = zeros(numCh, numTrials);
            for trialIdx = 1:numTrials
                trial_data = ws_trials(:, :, trialIdx);      % time x ch
                baseline_win = trial_data(1:baselineSamples, :);  % baseline part
                trialwise_rms(:, trialIdx) = rms(baseline_win, 1, 'omitnan')'; % ch x 1
            end
            % average RMS of trialwise baselines (per channel)
            baseline_rms_avg = mean(trialwise_rms, 2, 'omitnan');  % ch x 1

            % normalize averaged waveform by trialwise baseline RMS
            norm_subTrial = ws_ch_time ./ baseline_rms_avg;

            %% --- Save ---
            if stimIdx == 1
                stim1_subNorm(subjIdx, :, :) = norm_sub;
                stim1_subTrialNorm(subjIdx, :, :) = norm_subTrial;
            else
                stim2_subNorm(subjIdx, :, :) = norm_sub;
                stim2_subTrialNorm(subjIdx, :, :) = norm_subTrial;
            end
        end
    end

    %% --- Package output ---
    normOut = struct();
    normOut.channels = channels;
    normOut.stim1_raw = stim1_raw;
    normOut.stim1_subNorm = stim1_subNorm;
    normOut.stim1_subTrialNorm = stim1_subTrialNorm;
    normOut.stim2_raw = stim2_raw;
    normOut.stim2_subNorm = stim2_subNorm;
    normOut.stim2_subTrialNorm = stim2_subTrialNorm;

    %% --- Save ---
    saveFilename = sprintf('%s_normalized_output.mat', datasetName);
    save(saveFilename, 'normOut', '-v7.3');
    fprintf('✅ Normalization complete. Results saved to: %s\n', saveFilename);

end
