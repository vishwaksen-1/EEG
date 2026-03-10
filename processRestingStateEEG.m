function resting_state_cell = processRestingStateEEG(T_data_cleaned, T_markers_data)
    % processRestingStateEEG Extracts 30-second central segments for Eyes-Closed 
    % and Eyes-Open resting state conditions from EEG data.
    %
    % Inputs:
    %   T_data_cleaned: Table containing EEG samples and timestamps
    %   T_markers_data: Table containing event markers and timestamps
    %
    % Output:
    %   resting_state_cell: 1x2 cell array {EyesClosedData, EyesOpenData}
    %                       Each cell contains a [7680 x 16] matrix

    %% 1. Configuration
    fs = 256;               % Sampling rate in Hz
    duration_sec = 30;      % Target duration in seconds
    target_samples = fs * duration_sec; % 7680 samples
    
    % Define column names to remove (metadata and markers)
    cols_to_remove = {'markerInd', 'markerType', 'markerValue'};
    
    % Initialize output
    resting_state_cell = cell(1, 2);
    
    %% 2. Extract Timestamps from T_markers_data
    % Index 7: Eyes Closed Start
    % Index 8: Eyes Open Start (also Eyes Closed End)
    % Index 9: Eyes Open End
    try
        t7 = T_markers_data.timestamp(7);
        t8 = T_markers_data.timestamp(8);
        t9 = T_markers_data.timestamp(9);
    catch
        error('T_markers_data does not contain the required marker indices (7, 8, 9).');
    end

    %% 3. Define the intervals
    % Interval 1: Eyes Closed (t7 to t8)
    % Interval 2: Eyes Open (t8 to t9)
    intervals = [t7, t8; t8, t9];
    
    for i = 1:2
        start_ts = intervals(i, 1);
        end_ts = intervals(i, 2);
        
        % Filter T_data_cleaned for timestamps within this range
        % Using logical indexing for performance
        in_range_mask = T_data_cleaned.timestamp >= start_ts & T_data_cleaned.timestamp <= end_ts;
        block_data = T_data_cleaned(in_range_mask, :);
        
        num_available_samples = size(block_data, 1);
        
        if num_available_samples < target_samples
            warning('Interval %d only has %d samples (less than required %d). Using all available.', ...
                i, num_available_samples, target_samples);
            selected_data = block_data;
        else
            % Calculate central index to crop 30 seconds
            mid_idx = floor(num_available_samples / 2);
            half_window = floor(target_samples / 2);
            
            % Adjust range to ensure exactly target_samples
            start_idx = mid_idx - half_window + 1;
            end_idx = start_idx + target_samples - 1;
            
            % Extract the central rows
            selected_data = block_data(start_idx:end_idx, :);
        end
        
        % 4. Data Cleaning & Matrix Conversion
        % Remove the marker columns
        cleaned_block = removevars(selected_data, cols_to_remove);
        
        % Convert table to array (Result is samples x remaining columns)
        % Remaining columns: timestamp, counter, AF3, F7, F3... AF4
        % Dimension: [Samples x 16]
        resting_state_cell{i} = table2array(cleaned_block);
    end
end