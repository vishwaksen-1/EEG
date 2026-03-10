function normOut = ann_normalizeStimPerSubject2(stimData, datasetName, baselineRef)

%%%%%%%%%%%%%%%%%%%%%%%%%%%% ann - 23/1025

%%%%%% whats done here

% find trial avga nd rms .. tehn save taht and use it sperately for all trails in whcih ever datasegment in use for say active-hitand msis togetehr 
% or miss and fa together


% normalizeStimPerSubject - baseline normalization with optional reference baseline
%
% Usage:
%   normOutA = normalizeStimPerSubject(stimA, 'stimA'); % computes baseline
%   normOutB = normalizeStimPerSubject(stimB, 'stimB', normOutA.baselineRef); % uses baseline from A
%

    if nargin < 2
        datasetName = 'EEGData';
    end
    useExternalBaseline = (nargin == 3 && ~isempty(baselineRef));

 

    %% --- Channel names ---
    channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2', ...
                'P8','T8','FC6','F4','F8','AF4'};

    %% --- Field name detection ---
    if isfield(stimData, 'whole_stim')
        wholeField = 'whole_stim';
    elseif isfield(stimData, 'wholestim')
        wholeField = 'wholestim';
    else
        error('stimData must contain field ''whole_stim'' or ''wholestim''.');
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

    % Preallocate outputs
    stim1_raw = NaN(numSubjects, numCh, numTime);
    stim2_raw = NaN(numSubjects, numCh, numTime);
    stim1_subNorm = NaN(numSubjects, numCh, numTime);
    stim2_subNorm = NaN(numSubjects, numCh, numTime);
    stim1_subTrialNorm = NaN(numSubjects, numCh, numTime);
    stim2_subTrialNorm = NaN(numSubjects, numCh, numTime);

    % Also store baseline values for re-use
    baselineRefOut = struct();

    %% --- Compute per-subject measures ---
    for stimIdx = 1:numStims
        for subjIdx = 1:numSubjects

            ws_trials = squeeze(stimData.(wholeField)(:, :, stimIdx, :, subjIdx));
            bl_trials = squeeze(stimData.baseline(:, :, stimIdx, :, subjIdx));

            ws_mean_trials = mean(ws_trials, 3, 'omitnan');
            bl_mean_trials = mean(bl_trials, 3, 'omitnan');

            ws_ch_time = permute(ws_mean_trials, [2,1]);
            bl_ch_time = permute(bl_mean_trials, [2,1]);

            if stimIdx == 1
                stim1_raw(subjIdx, :, :) = ws_ch_time;
            else
                stim2_raw(subjIdx, :, :) = ws_ch_time;
            end

            %% --- Get or compute baselines ---
            if useExternalBaseline
                % Use baseline values from provided reference
                bl_rms_sub = baselineRef(stimIdx).bl_rms_sub(subjIdx, :).';
                baseline_rms_avg = baselineRef(stimIdx).baseline_rms_avg(subjIdx, :).';
            else
                % Compute new ones from current dataset
                bl_rms_sub = rms(bl_ch_time, 2, 'omitnan');
                fs=256;

                trialwise_rms = zeros(numCh, numTrials);
                for trialIdx = 1:numTrials
                    trial_data = ws_trials(:, :, trialIdx);
                    baseline_win = trial_data(1:round(0.9*fs), :);
                    trialwise_rms(:, trialIdx) = rms(baseline_win, 1, 'omitnan')';
                end
                baseline_rms_avg = mean(trialwise_rms, 2, 'omitnan');
            end

            %% --- Normalize using those baselines ---
            norm_sub = ws_ch_time ./ bl_rms_sub;
            norm_subTrial = ws_ch_time ./ baseline_rms_avg;

            if stimIdx == 1
                stim1_subNorm(subjIdx, :, :) = norm_sub;
                stim1_subTrialNorm(subjIdx, :, :) = norm_subTrial;
            else
                stim2_subNorm(subjIdx, :, :) = norm_sub;
                stim2_subTrialNorm(subjIdx, :, :) = norm_subTrial;
            end

            % Store for later reuse (only if we computed them)
            if ~useExternalBaseline
                baselineRef(stimIdx).bl_rms_sub(subjIdx,:) = bl_rms_sub;
                baselineRef(stimIdx).baseline_rms_avg(subjIdx,:) = baseline_rms_avg;
            end
        end
    end

    %% --- Package outputs ---
    normOut = struct();
    normOut.channels = channels;
    normOut.stim1_raw = stim1_raw;
    normOut.stim1_subNorm = stim1_subNorm;
    normOut.stim1_subTrialNorm = stim1_subTrialNorm;
    normOut.stim2_raw = stim2_raw;
    normOut.stim2_subNorm = stim2_subNorm;
    normOut.stim2_subTrialNorm = stim2_subTrialNorm;

    if ~useExternalBaseline
        normOut.baselineRef = baselineRef; % store for reuse
    end

    % saveFilename = sprintf('%s_normalized_output.mat', datasetName);
    % save(saveFilename, 'normOut', '-v7.3');
    %fprintf('✅ Normalization complete. Results saved to: %s\n', saveFilename);
end
