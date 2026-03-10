function db = t_segmentEEGData(sub, setno, T_data_cleaned, experiment_type)
% t_segment_eeg_data - Unified function to segment EEG data for active or passive experiments.
% This function has an extension segment_eeg_data. Does the same but
% creates 1x6 Cells < considers behavioural trial responses
%
%   Args:
%       sub (int): The subject number.
%       setno (int): The set number, which is now also used to select the jablingOrder file.
%       T_data_cleaned (table): The cleaned EEG data table.
%       experiment_type (string): 'active' or 'passive'.
%
%   Returns:
%       db (cell): A cell array containing the segmented data.

%% Define macro for initial delay
INITIAL_DELAY_MS = 592;
delay_samples = round(INITIAL_DELAY_MS / 1000 * 256);

% Find all rows that contain a marker
markerRows = find(~isnan(T_data_cleaned.markerInd));
markerIDs  = T_data_cleaned.markerInd(markerRows); 
markerVal  = T_data_cleaned.markerValue(markerRows);

blocksEEG = {}; % Initialize a cell array to hold EEG blocks

% Determine data blocks based on experiment type
if strcmpi(experiment_type, 'active')
    % Logic for active experiment (3 specific blocks)
    blocksEEG{1}   = T_data_cleaned{markerRows(1):markerRows(2)-1 , 3:16};
    blocksEEG{2}   = T_data_cleaned{markerRows(3)+128+delay_samples:markerRows(end-2)+127+delay_samples , 3:16};
    blocksEEG{3}   = T_data_cleaned{markerRows(end-1)+129:markerRows(end) , 3:16};
elseif strcmpi(experiment_type, 'passive')
    % Logic for passive experiment (iterates through markers in pairs)
    blk = 0;
    for k = 1:2:numel(markerRows)
        blk = blk + 1;
        idxStart = markerRows(k) + delay_samples;
        idxEnd   = markerRows(k+1) + delay_samples;
        blocksEEG{blk} = T_data_cleaned{idxStart:idxEnd-1 , 3:16};
    end
else
    error('Invalid experiment_type. Please use ''active'' or ''passive''.');
end

fs = 256;
segDur = 6.5;

% Create the final database cell array
db = {};
db{1,1} = ['s' num2str(sub)];
db{1,2} = ['set' num2str(setno)];
db{1,3} = blocksEEG{1};

% Pass the main data block to the updated segmentBlock function,
% using setno as the jabling_file_option.
if strcmpi(experiment_type, 'active')
    gSi = markerRows(3)+128+delay_samples;
    [db{1,4}, db{1,5}, x] = t_segmentBlock(blocksEEG{2}, fs, segDur, setno, experiment_type, markerRows, gSi);
    db{1,6} = blocksEEG{3};
    db{1,7} = x; % stim wise number of correct responses
    
elseif strcmpi(experiment_type, 'passive')
    % Assuming the second block in passive is the main one for segmentation
    [db{1,4}, db{1,5}, ~] = t_segmentBlock(blocksEEG{2}, fs, segDur, setno, experiment_type);
    % You may need to adjust this depending on which block you want segmented 
    db{1,6} = blocksEEG{3};
end

end