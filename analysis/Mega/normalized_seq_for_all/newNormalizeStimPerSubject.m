function normOut = newNormalizeStimPerSubject(stimData, datasetName, full)

    if nargin < 2
        datasetName = 'EEGData';
    end

    %% --- Channel names ---
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
    numStims    = size(sample_whole, 3);
    numTrials   = size(sample_whole, 4);
    numSubjects = size(sample_whole, 5);

    if numCh ~= length(channels)
        warning('Channel count mismatch. Adjusting label length.');
        channels = channels(1:min(numCh,length(channels)));
    end

    %% --- Pre-allocate (NOW WITH TRIAL DIMENSION) ---
    stim1_zscore        = NaN(numSubjects, numCh, numTime, numTrials);
    stim2_zscore        = NaN(numSubjects, numCh, numTime, numTrials);
    stim1_subNorm       = NaN(numSubjects, numCh, numTime, numTrials);
    stim2_subNorm       = NaN(numSubjects, numCh, numTime, numTrials);
    stim1_subTrialNorm  = NaN(numSubjects, numCh, numTime, numTrials);
    stim2_subTrialNorm  = NaN(numSubjects, numCh, numTime, numTrials);

    %% --- Parameters ---
    fs = 256;
    baselineSamples = round(0.9 * fs);

    %% --- MAIN LOOP ---
    for stimIdx = 1:numStims
        for subjIdx = 1:numSubjects

            % Extract: time x ch x trials
            ws_trials = squeeze(stimData.(wholeField)(:, :, stimIdx, :, subjIdx));
            bl_trials = squeeze(stimData.baseline(:, :, stimIdx, :, subjIdx));

            for trialIdx = 1:numTrials

                % --- Single trial ---
                ws = ws_trials(:, :, trialIdx); % time x ch
                bl = bl_trials(:, :, trialIdx); % time x ch

                % Convert to ch x time
                ws_ch_time = permute(ws, [2,1]);
                bl_ch_time = permute(bl, [2,1]);

                %% --- 1. Z-score (PER TRIAL BASELINE) ---
                bl_mean = mean(bl_ch_time, 2, 'omitnan'); % ch x 1
                bl_std  = std(bl_ch_time, 0, 2, 'omitnan');

                bl_std(bl_std == 0) = eps;

                norm_z = (ws_ch_time - bl_mean) ./ bl_std;

                %% --- 2. RMS baseline normalization (PER TRIAL) ---
                bl_rms = rms(bl_ch_time, 2, 'omitnan');
                bl_rms(bl_rms == 0) = eps;

                norm_sub = ws_ch_time ./ bl_rms;

                %% --- 3. Trial baseline window normalization ---
                baseline_win = ws(1:baselineSamples, :); % time x ch
                trial_rms = rms(baseline_win, 1, 'omitnan')'; % ch x 1
                trial_rms(trial_rms == 0) = eps;

                norm_subTrial = ws_ch_time ./ trial_rms;

                %% --- STORE ---
                if stimIdx == 1
                    stim1_zscore(subjIdx, :, :, trialIdx)       = norm_z;
                    stim1_subNorm(subjIdx, :, :, trialIdx)      = norm_sub;
                    stim1_subTrialNorm(subjIdx, :, :, trialIdx) = norm_subTrial;
                else
                    stim2_zscore(subjIdx, :, :, trialIdx)       = norm_z;
                    stim2_subNorm(subjIdx, :, :, trialIdx)      = norm_sub;
                    stim2_subTrialNorm(subjIdx, :, :, trialIdx) = norm_subTrial;
                end
            end
        end
    end

    %% --- Output ---
    normOut = struct();
    normOut.channels = channels;

    normOut.stim1_zscore = stim1_zscore;
    normOut.stim1_subNorm = stim1_subNorm;
    normOut.stim1_subTrialNorm = stim1_subTrialNorm;

    normOut.stim2_zscore = stim2_zscore;
    normOut.stim2_subNorm = stim2_subNorm;
    normOut.stim2_subTrialNorm = stim2_subTrialNorm;

    fprintf('✅ Trial-wise normalization complete (no averaging).\n');
end