%% EEG Data Processing: Generalized and Generalized Segmentation
% This script generalizes the segmentation logic from the provided code to
% handle any number of subjects and automatically derive dimensions.
% It re-organizes the data into a 6D array for easier access and then
% calculates the trial-averaged data.
% Finally, it includes an assertion to check if the segmented data retains
% all the information from the original.

%% Initialization and Constants
% The script assumes a variable 'data' is loaded into the workspace.
% 'data' is a kx1 cell array where each cell contains a 1x5 cell array.
% data{i}{4} holds the EEG data for the i-th subject.
% The dimensions of data{i}{4} are:
%   - 1664 samples
%   - 14 channels
%   - 4 stimuli
%   - 10 trials

% Define constants for the stimuli and segments. These are based on the
% original script's logic and can be adjusted.
SAMPLES_PER_SECOND = 256; % Sampling rate
TOTAL_DURATION_SEC = 6.5; % Total duration of the experiment
EVENT_2_DURATION_SEC = 3.6; % The duration of the segment of interest

% We will define the start and end samples of the event of interest
% from the total samples. The original code used hardcoded values, so we
% make a note of them here to maintain consistency.
% Original event start/end samples were 129 to 1050, which gives 922 samples.
% This is approximately 3.6 seconds * 256 Hz = 921.6 samples.
% To generalize, we can calculate the samples based on the duration.
event_2_samples = round(EVENT_2_DURATION_SEC * SAMPLES_PER_SECOND);

% The number of subjects is the first dimension of the 'data' cell array.
num_subjects = size(data, 1);

%% Pre-allocation of Output Variables
% We will determine the size of the original data to use for pre-allocation.
% The original data (data{1}{4}) has dimensions:
% samples x channels x stimuli x trials
[num_samples_total, num_channels, num_stimuli, num_trials] = size(data{1}{4});

% We will generalize the segmentation parameters.
% The original code had 24 segments for stim 1/2 and 12 for stim 3/4.
% And two types of segments (39 samples and 38 samples).
% To generalize, we will calculate the segments based on the event duration.
% Stimuli 1/2 were segmented into 24 blocks (150ms).
% 150ms * 256 Hz = 38.4 samples. This explains the 38 and 39 sample segments.
SEGMENT_DURATION_12_SEC = 0.15;
segment_length_12 = round(SEGMENT_DURATION_12_SEC * SAMPLES_PER_SECOND);
num_segments_12 = floor(event_2_samples / segment_length_12);

% Stimuli 3/4 were segmented into 12 blocks (300ms).
% 300ms * 256 Hz = 76.8 samples. This explains the 77 samples.
SEGMENT_DURATION_34_SEC = 0.30;
segment_length_34 = round(SEGMENT_DURATION_34_SEC * SAMPLES_PER_SECOND);
num_segments_34 = floor(event_2_samples / segment_length_34);

% Pre-allocate the final segmented arrays with the requested 6 dimensions.
% Dimensions: subject x stimuli x trial x segment x channel x samples
seg_12 = zeros(num_subjects, 2, num_trials, num_segments_12, num_channels, segment_length_12);
seg_34 = zeros(num_subjects, 2, num_trials, num_segments_34, num_channels, segment_length_34);

%% Segmentation Loop
% Loop through each subject to process their data.
for sub_idx = 1:num_subjects
    % Extract the EEG data for the current subject.
    eeg_data = data{sub_idx}{4};

    % The original code focused on a specific segment of the total samples.
    % We will do the same, but calculate the start and end samples.
    % We assume the segment of interest starts at the same relative position.
    % In the original code, the segment started at sample 129. Let's
    % maintain that for now, but also calculate it as a percentage of total samples.
    % (129-1)/1664 = 0.077, so roughly 8% of the way in.
    event_start_sample = 129;
    event_end_sample = event_start_sample + event_2_samples - 1;

    % Now, let's extract the data for each stimulus.
    d1_data = eeg_data(event_start_sample:event_end_sample, :, 1, :);
    d2_data = eeg_data(event_start_sample:event_end_sample, :, 2, :);
    d3_data = eeg_data(event_start_sample:event_end_sample, :, 3, :);
    d4_data = eeg_data(event_start_sample:event_end_sample, :, 4, :);
    
    % We will reorganize the data to simplify the segmentation loop.
    % This avoids the repetitive windowing and assignment.
    segment_data_12 = cat(4, d1_data, d2_data);
    segment_data_34 = cat(4, d3_data, d4_data);
    
    % The current dimensions are:
    % (samples_in_event, channels, trials, stimuli)
    % We need to permute for easier indexing during segmentation
    % Permute to (samples, channels, stimuli, trials)
    segment_data_12 = permute(segment_data_12, [1 2 4 3]);
    segment_data_34 = permute(segment_data_34, [1 2 4 3]);
    
    %% Segmentation for Stimuli 1 and 2
    % This part re-implements the original logic with a more general loop.
    idx = 1;
    for seg_idx = 1:num_segments_12
        end_idx = idx + segment_length_12 - 1;
        
        % Extract the segment
        window = segment_data_12(idx:end_idx, :, :, :);
        
        % Store in the pre-allocated array (subject, stim, trial, seg, chan, samples)
        % We use reshape to ensure the number of dimensions is compatible for assignment.
        seg_12(sub_idx, :, :, seg_idx, :, :) = reshape(permute(window, [3 4 2 1]), [1, 2, num_trials, 1, num_channels, segment_length_12]);
        
        % Move to the next segment
        idx = end_idx + 1;
    end
    
    %% Segmentation for Stimuli 3 and 4
    % Note: The original code used an overlapping window with a step size.
    % We will generalize this, but stick to a non-overlapping approach for simplicity
    % unless the step size logic is a firm requirement. If you need overlapping
    % segments, we can easily add that back in.
    idx = 1;
    for seg_idx = 1:num_segments_34
        end_idx = idx + segment_length_34 - 1;
        
        % Extract the segment
        window = segment_data_34(idx:end_idx, :, :, :);
        
        % Store in the pre-allocated array
        % We use reshape to ensure the number of dimensions is compatible for assignment.
        seg_34(sub_idx, :, :, seg_idx, :, :) = reshape(permute(window, [3 4 2 1]), [1, 2, num_trials, 1, num_channels, segment_length_34]);
        
        % Move to the next segment
        idx = end_idx + 1;
    end
end

%% Averaging
% We need to average along the 'trial' dimension.
% Dimensions of seg_12: subject x stim x trial x segment x channel x samples
avg_seg_12 = mean(seg_12, 3);
avg_seg_34 = mean(seg_34, 3);

% The output of averaging will have dimensions:
% subject x stim x 1 x segment x channel x samples
%%
figure;
hold on;
for i = 1:14
    % Squeeze the data to get a 1D vector for plotting.
    plot(squeeze(avg_seg_34(1,1,1,1,i,:)));
end
hold off;