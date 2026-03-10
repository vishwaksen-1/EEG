function [data4Dc, data4Dw, cMat] = t_segmentBlock(eegBlock, fs, segDur, jabling_file_option, experiment_type, markerRows, globalStartIdx)
% t_segmentBlock  — Segments an EEG block into two 4D matrices: one for correct responses (data4Dc)
%                  and one for incorrect responses (data4Dw).
%                  segmentBlock with an extension ;)
%
%   Args:
%       eegBlock (double): [N x 14] double array (samples x channels). This is the main block of data for segmentation.
%       fs (double): Sampling frequency in Hz.
%       segDur (double): Desired segment duration in seconds.
%       jabling_file_option (int): 0 for 'jablingOrder0.mat', 1 for 'jablingOrder1.mat', 2 for 'jablingOrder2.mat'.
%       experiment_type (string): 'active' or 'passive'. Determines if behavioral sorting is performed.
%       markerRows (vector): Contains the raw row indices of ALL markers from the original T_data_cleaned. (Required for active).
%       globalStartIdx (int): The absolute starting row index of eegBlock in the original T_data_cleaned table. (Required for active).
%
%   Returns:
%       data4Dc (double): Segmented 4D matrix [samples x channels x stim x trials] for CORRECT responses (or ALL data for passive).
%       data4Dw (double): Segmented 4D matrix [samples x channels x stim x trials] for INCORRECT responses (or empty for passive).
%       cMat    (double): 1D Stim wise correct counts matrix
% Load the correct jabling order file based on the option
switch jabling_file_option
    case 0
        load('jablingOrder.mat');
    case 1
        load('jablingOrder1.mat');
    case 2
        load('jablingOrder2.mat');
    otherwise
        error('Invalid jabling_file_option. Use 0, 1, or 2.');
end

num_eeg_channels = size(eegBlock, 2);
segLen = round(segDur * fs);           % Segment length in samples
nSeg   = floor(size(eegBlock,1) / segLen);
segCell = mat2cell(eegBlock(1:nSeg*segLen , :), ...
    repmat(segLen,nSeg,1), num_eeg_channels);

% --- Initialization ---
nTrial = 10;
if jabling_file_option == 0, nStim = 8; else nStim = 4; end
expectedSegs = nTrial * nStim;

if nSeg < expectedSegs
    warning('Not enough data for all %d expected segments. Data will be truncated.', expectedSegs);
end

% Pre-allocate the two 4D matrices to the maximum possible size (nTrial x nStim)
data4Dc = zeros(segLen, num_eeg_channels, nStim, nTrial);
data4Dw = zeros(segLen, num_eeg_channels, nStim, nTrial);

% Counters to track the number of correct/wrong trials *per stimulus ID*
correctCount = zeros(1, nStim);
wrongCount = zeros(1, nStim);

p = 1; % Index for segCell

% --- Active Keypress Markers Setup ---
if strcmpi(experiment_type, 'active')
    if nargin < 7 || isempty(markerRows) || isempty(globalStartIdx)
        error('For active experiment, both ''markerRows'' and ''globalStartIdx'' must be provided.');
    end
    
    % StimID 1 and 3 are periodic (target for keypress); 2 and 4 are aperiodic (non-target)
    periodic_stim_ids = [1, 3]; 
end

% --- Segmentation Loop ---
for t = 1:nTrial
    for k = 1:nStim
        % Check if we have more segments to process
        if p > nSeg
            break; % Exit inner loop if we run out of segments
        end

        stimID = jablingOrder(t,k);   % which stimulus was played k-th in trial t
        
        % --- 1. Determine Response Type (Only for Active) ---
        response_value = 1; % Default to 1 (Correct/Passive)
        
        if strcmpi(experiment_type, 'active')
            % Calculate the global index window of the current segment
            segStartGlobal = globalStartIdx + (p - 1) * segLen;
            segEndGlobal = segStartGlobal + segLen - 1;
            
            % Check if a keypress event falls within the current segment's window
            markersInSegment = markerRows(markerRows >= segStartGlobal & markerRows <= segEndGlobal);
            
            is_periodic = ismember(stimID, periodic_stim_ids);
            has_response = ~isempty(markersInSegment); % Keypress detected (single point event)
            
            % --- Behavioral Scoring ---
            if is_periodic % Target stimulus (Requires a keypress)
                if ~has_response
                    % Miss (Incorrect)
                    response_value = -1; 
                end
            else % Non-target stimulus (Requires NO keypress)
                if has_response
                    % False Alarm (Incorrect)
                    response_value = -1; 
                end
            end
            % If response_value is 1, it's a Hit (P+R) or Correct Rejection (A+NoR)
            % If response_value is -1, it's a Miss (P+NoR) or False Alarm (A+R)

        end % End active analysis
        
        % --- 2. Populate the Correct or Wrong Matrix ---
        current_segment = segCell{p};

        if response_value == 1 % Correct/Passive
            correctCount(stimID) = correctCount(stimID) + 1;
            % Place segment into the next available trial slot for this stimID in data4Dc
            data4Dc(:,:,stimID, correctCount(stimID)) = current_segment;
        else % response_value == -1 (Wrong/Incorrect)
            wrongCount(stimID) = wrongCount(stimID) + 1;
            % Place segment into the next available trial slot for this stimID in data4Dw
            data4Dw(:,:,stimID, wrongCount(stimID)) = current_segment;
        end
        
        p = p + 1;
    end
    if p > nSeg
        break; % Exit outer loop if we run out of segments
    end
end

% --- 3. Final Truncation ---
% Find the maximum number of trials used for C and W across all stimuli
maxCorrectTrials = max(correctCount);
maxWrongTrials = max(wrongCount);

cMat = correctCount;

% % Truncate data4Dc
% if maxCorrectTrials == 0
%      data4Dc = zeros(segLen, num_eeg_channels, nStim, 0); % Empty matrix, preserving dimensions
% else
%      data4Dc = data4Dc(:,:,:, 1:maxCorrectTrials);
% end
% 
% % Truncate data4Dw
% if maxWrongTrials == 0
%      data4Dw = zeros(segLen, num_eeg_channels, nStim, 0); % Empty matrix, preserving dimensions
% else
%      data4Dw = data4Dw(:,:,:, 1:maxWrongTrials);
% end

% NOTE on Passive: If experiment_type was 'passive', maxWrongTrials will be 0, and data4Dw will be an empty matrix.
end