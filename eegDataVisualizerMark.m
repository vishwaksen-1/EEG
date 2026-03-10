%==========================================================================
%                       EEG DATA VISUALIZATION TOOL - with Markers
%==========================================================================
% Interactive GUI for visualizing EEG data from raw CSV files or cleaned MAT files
%
% FEATURES:
% - Load raw CSV files (EmotivX 14-electrode format)
% - Load cleaned MAT files (processed data)
% - Interactive scrollable GUI with time navigation
% - Adjustable time window and amplitude scaling
% - Channel-by-channel display with labels
% - Optional: Plot vertical marker lines from 'markerInd' column
%
% USAGE:
% 1. Run the script from the MATLAB command window:
%    - `eegDataVisualizer()` to run normally.
%    - `eegDataVisualizer(1)` to plot marker lines.
% 2. Select file type (CSV or MAT)
% 3. Browse and select your file
% 4. Use GUI controls to navigate and adjust display
%==========================================================================
function eegDataVisualizer(varargin)
    % Main function to launch the EEG data visualizer
    clc;
    close;
    % Check for optional input argument to enable marker plotting
    plot_markers = false;
    if nargin > 0 && ~isempty(varargin{1})
        plot_markers = true;
        fprintf("Marking Markers\n");
    end
    
    % Clear workspace and close previous plots
    
    % close all;
    
    fprintf('=== EEG DATA VISUALIZER ===\n');
    fprintf('Interactive tool for visualizing raw and cleaned EEG data\n\n');
    
    % File type selection dialog
    file_choice = questdlg('Select the type of EEG data file to visualize:', ...
                          'EEG Data Visualizer', ...
                          'Raw CSV File', 'Cleaned MAT File', 'Cancel', ...
                          'Raw CSV File');
    
    if strcmp(file_choice, 'Cancel') || isempty(file_choice)
        fprintf('Visualization cancelled.\n');
        return;
    end
    
    % Load data based on file type selection
    if strcmp(file_choice, 'Raw CSV File')
        [eeg_data, channel_labels, fs, time_vector, data_info, marker_timestamps] = load_csv_data(plot_markers);
    else
        % Pass the plot_markers flag to the load_mat_data function
        [eeg_data, channel_labels, fs, time_vector, data_info, marker_timestamps] = load_mat_data(plot_markers);
    end
    
    % Check if data was loaded successfully
    if isempty(eeg_data)
        fprintf('No data loaded. Exiting visualizer.\n');
        return;
    end
    
    % Launch the interactive GUI
    launch_eeg_viewer(eeg_data, channel_labels, fs, time_vector, data_info, marker_timestamps, plot_markers);
    
    fprintf('\nEEG Data Visualizer launched successfully!\n');
    fprintf('Use the GUI controls to navigate through your data.\n');
end

%--------------------------------------------------------------------------
% SUBFUNCTIONS
%--------------------------------------------------------------------------

function [eeg_data, channel_labels, fs, time_vector, data_info, marker_timestamps] = load_csv_data(plot_markers)
    % Load and parse raw CSV data from EmotivX format
    
    fprintf('Loading raw CSV data...\n');
    
    % File selection dialog for CSV files
    [fname, fdir] = uigetfile( ...
        {'*.csv', 'CSV Files (*.csv)'; ...
         '*.txt', 'Text Files (*.txt)'; ...
         '*.*', 'All Files (*.*)'}, ...
        'Select Raw EEG Data File (CSV)');
    
    if isequal(fname, 0)
        fprintf('File selection cancelled.\n');
        eeg_data = [];
        channel_labels = {};
        fs = [];
        time_vector = [];
        data_info = struct();
        marker_timestamps = [];
        return;
    end
    
    filename = fullfile(fdir, fname);
    fprintf('Selected file: %s\n', filename);
    
    try
        % Parse header information from CSV file (exactly like ann_cleaning_trial.m)
        fileID = fopen(filename, 'r');
        fgetl(fileID); % first line - header diff ids 
        headerLine = fgetl(fileID); % second line only 
        fclose(fileID);
        
        fprintf('Debug - Header line: %s\n', headerLine(1:min(150, length(headerLine))));
        
        % Extract and clean channel names (exactly like ann_cleaning_trial.m)
        originalHeaders = strsplit(headerLine, ',');
        validHeaders = strrep(originalHeaders, 'EEG.', '');    
        
        % Load data table and select relevant columns (exactly like ann_cleaning_trial.m)
        T = readtable(filename, 'HeaderLines', 1);
        channel_names = validHeaders(5:18);  % Exact same as ann_cleaning_trial.m
        columns_to_keep_indices = [2, 3, 5:18, 22, 23, 24]; % Exact same as ann_cleaning_trial.m
        T_data = T(:, columns_to_keep_indices);
        
        % Assign meaningful column names (exactly like ann_cleaning_trial.m)
        new_headers = {'timestamp', 'counter', channel_names{:}, 'markerInd', 'markerType', 'markerValue'};
        T_data.Properties.VariableNames = new_headers;
        
        fprintf('Debug - Total columns found: %d\n', length(originalHeaders));
        fprintf('Debug - Selected columns: %s\n', mat2str(columns_to_keep_indices));
        fprintf('Debug - Channel names: %s\n', strjoin(channel_names, ', '));
        fprintf('Debug - Table size after selection: %d rows x %d columns\n', size(T_data, 1), size(T_data, 2));
        
        % Extract EEG data (columns 3-16 typically contain EEG channels)
        eeg_data = T_data{:, 3:16};  % Columns 3-16 contain EEG channels (same as ann_cleaning_trial.m)
        channel_labels = channel_names;
        
        % Extract marker timestamps if requested
        marker_timestamps = [];
        if plot_markers
            marker_column_index = find(strcmp(T_data.Properties.VariableNames, 'markerInd'));
            if ~isempty(marker_column_index)
                marker_values = T_data{:, marker_column_index};
                % Find indices where markerInd is a non-NaN positive number
                marker_indices = find(~isnan(marker_values) & marker_values > 0);
                marker_timestamps = (marker_indices - 1) / 256; % Convert to seconds
                fprintf('Found %d marker events.\n', length(marker_indices));
                
                % Print the list of marker indices
                fprintf('Marker Indices (row numbers):\n');
                disp(marker_indices);

            else
                fprintf('Warning: markerInd column not found in data.\n');
            end
        end
        
        fprintf('Debug - EEG data extracted: %d samples x %d channels\n', size(eeg_data, 1), size(eeg_data, 2));
        fprintf('Debug - Data range: min=%.3f, max=%.3f\n', min(eeg_data(:)), max(eeg_data(:)));
        
        % Check for non-numeric data
        if any(isnan(eeg_data(:)) | isinf(eeg_data(:)))
            fprintf('Warning - Found NaN or Inf values in data\n');
            eeg_data(isnan(eeg_data) | isinf(eeg_data)) = 0;
        end
        
        % Set parameters
        fs = 256;  % Sampling frequency (standard for EmotivX)
        time_vector = (0:size(eeg_data,1)-1) / fs;  % Time vector in seconds
        
        % Create data info structure
        data_info = struct();
        data_info.filename = fname;
        data_info.type = 'Raw CSV Data';
        data_info.n_samples = size(eeg_data, 1);
        data_info.n_channels = size(eeg_data, 2);
        data_info.duration = time_vector(end);
        data_info.sampling_rate = fs;
        
        fprintf('✓ CSV data loaded successfully:\n');
        fprintf('  - Channels: %d\n', data_info.n_channels);
        fprintf('  - Samples: %d\n', data_info.n_samples);
        fprintf('  - Duration: %.1f seconds\n', data_info.duration);
        fprintf('  - Sampling rate: %d Hz\n', data_info.sampling_rate);
        fprintf('  - Data summary: mean=%.3f, std=%.3f\n', mean(eeg_data(:)), std(eeg_data(:)));
        
        % Final validation
        if isempty(eeg_data) || size(eeg_data, 1) == 0 || size(eeg_data, 2) == 0
            error('EEG data is empty after processing');
        end
        
        fprintf('\n');
        
    catch ME
        fprintf('❌ Error loading CSV file: %s\n', ME.message);
        fprintf('Make sure the file follows the EmotivX CSV format.\n');
        eeg_data = [];
        channel_labels = {};
        fs = [];
        time_vector = [];
        data_info = struct();
        marker_timestamps = [];
    end
end
function [eeg_data, channel_labels, fs, time_vector, data_info, marker_timestamps] = load_mat_data(plot_markers)
    % Load cleaned MAT data from processed files
    
    fprintf('Loading cleaned MAT data...\n');
    
    % File selection dialog for MAT files
    [fname, fdir] = uigetfile( ...
        {'*.mat', 'MATLAB Data Files (*.mat)'; ...
         '*.*', 'All Files (*.*)'}, ...
        'Select Cleaned EEG Data File (MAT)');
    
    if isequal(fname, 0)
        fprintf('File selection cancelled.\n');
        eeg_data = [];
        channel_labels = {};
        fs = [];
        time_vector = [];
        data_info = struct();
        marker_timestamps = [];
        return;
    end
    
    filename = fullfile(fdir, fname);
    fprintf('Selected file: %s\n', filename);
    
    try
        % Load MAT file
        loaded_data = load(filename);
        
        % Check if T_data_cleaned exists (standard format from cleaning script)
        if isfield(loaded_data, 'T_data_cleaned')
            T_data_cleaned = loaded_data.T_data_cleaned;
            
            % Extract EEG data (columns 3-16 typically contain EEG channels)
            eeg_data = T_data_cleaned{:, 3:16};
            channel_labels = T_data_cleaned.Properties.VariableNames(3:16);

            % Extract marker timestamps from the table if it exists
            if plot_markers
                marker_column_index = find(strcmp(T_data_cleaned.Properties.VariableNames, 'markerInd'));
                if ~isempty(marker_column_index)
                    marker_values = T_data_cleaned{:, marker_column_index};
                    marker_indices = find(~isnan(marker_values) & marker_values > 0);
                    fs = 256; % Assuming 256 Hz for MAT files as well
                    marker_timestamps = (marker_indices - 1) / fs;
                    fprintf('Found %d marker events from T_data_cleaned.\n', length(marker_indices));
                    
                    % Print the list of marker indices
                    fprintf('Marker Indices (row numbers):\n');
                    disp(marker_indices);
                    
                else
                    fprintf('Warning: markerInd column not found in T_data_cleaned table.\n');
                    marker_timestamps = [];
                end
            else
                marker_timestamps = [];
            end
            
        elseif isfield(loaded_data, 'eeg_data')
            % Alternative format: direct eeg_data variable
            eeg_data = loaded_data.eeg_data;
            
            if isfield(loaded_data, 'channel_labels')
                channel_labels = loaded_data.channel_labels;
            else
                % Generate default channel labels
                channel_labels = arrayfun(@(x) sprintf('Ch%d', x), 1:size(eeg_data,2), 'UniformOutput', false);
            end
            
            % Extract marker timestamps from mat file if present
            marker_timestamps = [];
            if plot_markers && isfield(loaded_data, 'marker_timestamps')
                marker_timestamps = loaded_data.marker_timestamps;
                fprintf('Found %d marker events in MAT file.\n', length(marker_timestamps));
            end
            
        else
            % Try to find any numeric matrix that could be EEG data
            fields = fieldnames(loaded_data);
            found_data = false;
            
            for i = 1:length(fields)
                field_data = loaded_data.(fields{i});
                if isnumeric(field_data) && size(field_data, 2) >= 10 && size(field_data, 2) <= 20
                    eeg_data = field_data;
                    channel_labels = arrayfun(@(x) sprintf('Ch%d', x), 1:size(eeg_data,2), 'UniformOutput', false);
                    found_data = true;
                    fprintf('Found EEG data in field: %s\n', fields{i});
                    break;
                end
            end
            
            if ~found_data
                error('Could not find EEG data in MAT file. Expected variables: T_data_cleaned or eeg_data');
            end
        end
        
        % Set parameters
        if isfield(loaded_data, 'fs')
            fs = loaded_data.fs;
        else
            fs = 256;  % Default sampling frequency
            fprintf('Using default sampling rate: %d Hz\n', fs);
        end
        
        time_vector = (0:size(eeg_data,1)-1) / fs;  % Time vector in seconds
        
        % Create data info structure
        data_info = struct();
        data_info.filename = fname;
        data_info.type = 'Cleaned MAT Data';
        data_info.n_samples = size(eeg_data, 1);
        data_info.n_channels = size(eeg_data, 2);
        data_info.duration = time_vector(end);
        data_info.sampling_rate = fs;
        
        fprintf('✓ MAT data loaded successfully:\n');
        fprintf('  - Channels: %d\n', data_info.n_channels);
        fprintf('  - Samples: %d\n', data_info.n_samples);
        fprintf('  - Duration: %.1f seconds\n', data_info.duration);
        fprintf('  - Sampling rate: %d Hz\n\n', data_info.sampling_rate);
        
    catch ME
        fprintf('❌ Error loading MAT file: %s\n', ME.message);
        fprintf('Make sure the file contains valid EEG data.\n');
        eeg_data = [];
        channel_labels = {};
        fs = [];
        time_vector = [];
        data_info = struct();
        marker_timestamps = [];
    end
end
function launch_eeg_viewer(eeg_data, channel_labels, fs, time_vector, data_info, marker_timestamps, plot_markers)
    % Create interactive EEG data viewer GUI
    %
    % Inputs:
    %   eeg_data          - EEG data matrix (time_points x channels)
    %   channel_labels    - Cell array of channel names
    %   fs                - Sampling frequency in Hz
    %   time_vector       - Time vector in seconds
    %   data_info         - Structure with file information
    %   marker_timestamps - Timestamps for plotting markers (optional)
    %   plot_markers      - Boolean flag to enable/disable marker plotting
    
    % Create main figure
    fig = figure('Name', sprintf('EEG Data Viewer - %s', data_info.type), ...
                'NumberTitle', 'off', ...
                'Position', [100, 100, 1400, 900], ...
                'MenuBar', 'none', ...
                'ToolBar', 'figure');
    
    % Parameters for display
    window_duration = 10;  % Display window duration in seconds
    window_samples = window_duration * fs;
    n_channels = size(eeg_data, 2);
    % Auto-calculate appropriate channel spacing based on data amplitude
    data_std = std(eeg_data(:));
    
    % For raw CSV data, use larger spacing; for cleaned data, use smaller spacing
    if strcmp(data_info.type, 'Raw CSV Data')
        % Raw data typically has much larger amplitudes
        channel_spacing = max(200, data_std * 4);  % Adaptive spacing based on data
        fprintf('Auto-scaling for raw CSV data: channel spacing = %.1f\n', channel_spacing);
    else
        % Cleaned data has smaller, more controlled amplitudes
        channel_spacing = max(100, data_std * 2);
        fprintf('Auto-scaling for cleaned data: channel spacing = %.1f\n', channel_spacing);
    end
    
    % Initialize display parameters
    current_start = 1;
    max_start = max(1, size(eeg_data,1) - window_samples + 1);
    
    % Create axes for EEG plot
    ax = axes('Parent', fig, 'Position', [0.1, 0.25, 0.8, 0.65]);
    hold(ax, 'on');
    grid(ax, 'on');
    
    % Create information panel
    info_panel = uipanel('Parent', fig, 'Title', 'Data Information', ...
                        'Position', [0.1, 0.02, 0.8, 0.15]);
    
    % Display file information
    info_text = sprintf(['File: %s | Type: %s | Channels: %d | Samples: %d | ' ...
                        'Duration: %.1f s | Sampling Rate: %d Hz'], ...
                       data_info.filename, data_info.type, data_info.n_channels, ...
                       data_info.n_samples, data_info.duration, data_info.sampling_rate);
    
    uicontrol('Parent', info_panel, 'Style', 'text', 'String', info_text, ...
             'Position', [10, 60, 1000, 25], 'HorizontalAlignment', 'left', ...
             'FontSize', 10);
    
    % Create UI controls
    uicontrol('Parent', info_panel, 'Style', 'text', 'String', 'Time Window (seconds):', ...
        'Position', [10, 30, 120, 20], 'HorizontalAlignment', 'left');
    
    window_edit = uicontrol('Parent', info_panel, 'Style', 'edit', ...
        'String', num2str(window_duration), ...
        'Position', [140, 30, 60, 25], 'Callback', @update_window_callback);
    
    uicontrol('Parent', info_panel, 'Style', 'text', 'String', 'Amplitude Scale:', ...
        'Position', [220, 30, 100, 20], 'HorizontalAlignment', 'left');
    
    scale_edit = uicontrol('Parent', info_panel, 'Style', 'edit', ...
        'String', num2str(channel_spacing), ...
        'Position', [330, 30, 60, 25], 'Callback', @update_scale_callback);
    
    % Navigation buttons
    uicontrol('Parent', info_panel, 'Style', 'pushbutton', 'String', '<<', ...
        'Position', [420, 30, 40, 25], ...
        'Callback', @(src,evt) scroll_data_callback(-window_samples), ...
        'TooltipString', 'Jump backward by full window');
    
    uicontrol('Parent', info_panel, 'Style', 'pushbutton', 'String', '<', ...
        'Position', [470, 30, 40, 25], ...
        'Callback', @(src,evt) scroll_data_callback(-window_samples/4), ...
        'TooltipString', 'Step backward by quarter window');
    
    uicontrol('Parent', info_panel, 'Style', 'pushbutton', 'String', '>', ...
        'Position', [520, 30, 40, 25], ...
        'Callback', @(src,evt) scroll_data_callback(window_samples/4), ...
        'TooltipString', 'Step forward by quarter window');
    
    % Reset button
    uicontrol('Parent', info_panel, 'Style', 'pushbutton', 'String', 'Reset View', ...
        'Position', [630, 30, 80, 25], ...
        'Callback', @reset_view_callback, ...
        'TooltipString', 'Reset to beginning and default settings');
    
    % Time slider
    time_slider = uicontrol('Parent', info_panel, 'Style', 'slider', ...
        'Min', 1, 'Max', max_start, 'Value', current_start, ...
        'Position', [10, 5, 600, 20], ...
        'Callback', @slider_callback);
    
    % Time display
    time_text = uicontrol('Parent', info_panel, 'Style', 'text', 'String', '', ...
        'Position', [620, 5, 200, 20], 'HorizontalAlignment', 'left');
    
    % Initial plot
    plot_eeg_data();
    
    % Plotting function
    function plot_eeg_data()
        % Clear previous plot
        cla(ax);
        hold(ax, 'on');
        
        % Calculate end sample
        current_end = min(current_start + window_samples - 1, size(eeg_data,1));
        
        % Extract current time window
        current_time = time_vector(current_start:current_end);
        current_data = eeg_data(current_start:current_end, :);
        
        % Debug information
        fprintf('Debug Plot - current_start: %d, current_end: %d\n', current_start, current_end);
        fprintf('Debug Plot - time range: %.2f to %.2f\n', current_time(1), current_time(end));
        fprintf('Debug Plot - data size: %d x %d\n', size(current_data, 1), size(current_data, 2));
        fprintf('Debug Plot - data range: %.3f to %.3f\n', min(current_data(:)), max(current_data(:)));
        
        % Plot each channel with vertical offset
        colors = lines(n_channels);
        for ch = 1:n_channels
            offset = (n_channels - ch) * channel_spacing;
            plot(ax, current_time, current_data(:,ch) + offset, ...
                'Color', colors(ch,:), 'LineWidth', 1);
            
            % Add channel labels
            text(ax, current_time(1) - 0.2, offset, channel_labels{ch}, ...
                'VerticalAlignment', 'middle', 'FontSize', 10, 'FontWeight', 'bold', ...
                'Color', colors(ch,:));
        end
        
        % Plot marker lines if requested and available
        if plot_markers && ~isempty(marker_timestamps)
            % Filter markers that fall within the current time window
            markers_in_window = marker_timestamps(marker_timestamps >= current_time(1) & ...
                                                  marker_timestamps <= current_time(end));
            
            if ~isempty(markers_in_window)
                for marker_time = markers_in_window'
                    plot(ax, [marker_time, marker_time], ylim(ax), ...
                         'r--', 'LineWidth', 1.5);
                end
            end
        end
        
        % Set axis properties
        xlim(ax, [current_time(1), current_time(end)]);
        ylim(ax, [-channel_spacing, n_channels * channel_spacing]);
        xlabel(ax, 'Time (seconds)', 'FontSize', 12);
        ylabel(ax, 'EEG Channels', 'FontSize', 12);
        title(ax, sprintf('%s - Window: %.1f - %.1f seconds', ...
            data_info.type, current_time(1), current_time(end)), 'FontSize', 14);
        grid(ax, 'on');
        
        % Update time display
        set(time_text, 'String', sprintf('%.1f - %.1f s / %.1f s', ...
            current_time(1), current_time(end), time_vector(end)));
        
        fprintf('Debug Plot - Plot completed\n');
    end
    
    % Callback functions
    function scroll_data_callback(delta)
        current_start = max(1, min(current_start + round(delta), max_start));
        set(time_slider, 'Value', current_start);
        plot_eeg_data();
    end
    
    function slider_callback(src, ~)
        current_start = round(get(src, 'Value'));
        plot_eeg_data();
    end
    
    function update_window_callback(src, ~)
        new_duration = str2double(get(src, 'String'));
        if ~isnan(new_duration) && new_duration > 0 && new_duration <= data_info.duration
            window_duration = new_duration;
            window_samples = window_duration * fs;
            max_start = max(1, size(eeg_data,1) - window_samples + 1);
            current_start = min(current_start, max_start);
            set(time_slider, 'Max', max_start, 'Value', current_start);
            plot_eeg_data();
        else
            set(src, 'String', num2str(window_duration));
            if new_duration > data_info.duration
                msgbox(sprintf('Window duration cannot exceed total duration (%.1f s)', data_info.duration), ...
                       'Invalid Input', 'warn');
            end
        end
    end
    
    function update_scale_callback(src, ~)
        new_scale = str2double(get(src, 'String'));
        if ~isnan(new_scale) && new_scale > 0
            channel_spacing = new_scale;
            plot_eeg_data();
        else
            set(src, 'String', num2str(channel_spacing));
        end
    end
    
    function reset_view_callback(~, ~)
        current_start = 1;
        window_duration = 10;
        window_samples = window_duration * fs;
        channel_spacing = 100;
        max_start = max(1, size(eeg_data,1) - window_samples + 1);
        
        set(time_slider, 'Max', max_start, 'Value', current_start);
        set(window_edit, 'String', num2str(window_duration));
        set(scale_edit, 'String', num2str(channel_spacing));
        plot_eeg_data();
    end
end
