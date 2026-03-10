
%==========================================================================
%                    EEG DATA CLEANING AND PREPROCESSING SCRIPT
%==========================================================================
% This script performs comprehensive EEG data cleaning (of one subject) using EEGLAB
% Use this to try modifying cleaning algorithm, then ship the changes to eegCleaningPipeline.m
% 
% REQUIREMENTS:
% - Ensure EEGLAB is loaded, only applicable to the file format generated f
%   -or our task 
% - Not a generic code to run any CSV
% - All column numbers required are hard coded
%
% WORKFLOW:
% 1. Load and parse EEG data file
% 2. Basic preprocessing and filtering
% 3. ICA decomposition and artifact removal
% 4. Save cleaned data
% 5. Process marker/event data
%==========================================================================

%% ======================== INITIALIZATION ===============================
% Clear workspace and prepare environment
clear;
clc;
close all;

%% ==================== DATA FILE LOADING AND PARSING ===================
% Load EEG data file and extract relevant columns for processing

addpath("..\");

% File selection dialog
[fname, fdir] = uigetfile( ...
    {'*.csv', 'CSV Files (*.csv)'; ...
     '*.xlsx', 'Excel Files (*.xlsx)'; ...
     '*.txt*', 'Text Files (*.txt*)'}, ...
    'Pick a file');
filename = fullfile(fdir, fname);
fprintf('Selected file: %s\n', filename);

% Parse header information from CSV file
fileID = fopen(filename, 'r');
fgetl(fileID); % first line - header diff ids 
headerLine = fgetl(fileID); % second line only 
fclose(fileID);

% Extract and clean channel names
originalHeaders = strsplit(headerLine, ',');
validHeaders = strrep(originalHeaders, 'EEG.', '');    

% Load data table and select relevant columns
T = readtable(filename, 'HeaderLines', 1);
channel_names = validHeaders(5:18);
columns_to_keep_indices = [2, 3, 5:18, 22, 23, 24]; % Columns 2, 3, data = 5 to 18
T_data = T(:, columns_to_keep_indices);
addpath("..\")
% Assign meaningful column names
new_headers = {'timestamp', 'counter', channel_names{:}, 'markerInd', 'markerType', 'markerValue'};
T_data.Properties.VariableNames = new_headers;
%% ================== EEG DATA PREPARATION FOR EEGLAB ====================
% Extract EEG channel data and prepare for EEGLAB import

% Set sampling frequency
fs = 256;

% Extract EEG data (channels only) and transpose for EEGLAB format
eegData_time_by_chans = T_data{:, 3:16};
eegData = eegData_time_by_chans';  % EEGLAB expects channels x timepoints
[nbchan, pnts] = size(eegData);
%% ====================== EEGLAB DATASET CREATION ========================
% Import data into EEGLAB structure for advanced preprocessing

% Create EEGLAB dataset from raw data
EEG = pop_importdata('dataformat', 'array', 'data', eegData, ...
                     'setname', 'raw_data', 'srate', fs, ...
                     'nbchan', nbchan);
EEG = eeg_checkset(EEG);
fprintf('EEGLAB dataset created.\n\n');

% Set up channel labels (currently unused but prepared for future use)
chanLabels = T_data.Properties.VariableNames(3:16);
chanlocs_struct = struct('labels', chanLabels);

%% ======================== BASIC SIGNAL FILTERING ======================
% Apply frequency filters to remove low-frequency drift and high-frequency noise

% High-pass filter (removes slow drifts and DC offset)
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'filtorder', 1280,'plotfreqz', 0);
EEG = eeg_checkset(EEG);
fprintf('Applied 1 Hz high-pass filter.\n');

% Low-pass filter (removes high-frequency noise and line noise)
EEG = pop_eegfiltnew(EEG, 'hicutoff', 45, 'filtorder', 1280, 'plotfreqz', 0);
EEG = eeg_checkset(EEG);
fprintf('Applied 55 Hz low-pass filter.\n\n');

%% =================== ADVANCED PREPROCESSING STEPS =====================
% Apply re-referencing, artifact subspace reconstruction, and ICA

% Re-reference to average reference (removes common mode artifacts)
EEG = pop_reref(EEG, []);
EEG = eeg_checkset(EEG);

% Artifact Subspace Reconstruction (ASR) - removes high-amplitude artifacts
EEG = clean_asr(EEG, 10); % Clean raw data with standard deviation threshold of 

% Independent Component Analysis (ICA) - separates neural and artifact sources
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'interrupt', 'on');
EEG = eeg_checkset(EEG);
%% ================= ICA COMPONENT CLASSIFICATION & REMOVAL ==============
% Automatically identify and remove artifact components using ICLabel

% Load channel locations for accurate component classification
channel_location_file_path = 'D:\auditory_perrand_data_code\eeg_perrand_analysis_5725\emtv_ch_loc.ced';
loc_filename = channel_location_file_path;
EEG.chanlocs = readlocs(loc_filename);

% Run ICLabel to classify ICA components
EEG = iclabel(EEG);

% Define automatic rejection thresholds for different artifact types
% Based on standard practices in EEG literature
rejection_thresholds = [NaN NaN;  % Brain: Never auto-reject (keep neural activity)
                        0.8 1.0;  % Muscle: Flag if > 80% probability
                        0.8 1.0;  % Eye: Flag if > 80% probability  
                        NaN NaN;  % Heart: Never flag automatically
                        NaN NaN;  % Line Noise: Never flag automatically
                        NaN NaN;  % Channel Noise: Never flag automatically
                        NaN NaN]; % Other: Never flag automatically

% Apply automatic flagging based on thresholds
EEG = pop_icflag(EEG, rejection_thresholds);

% Component rejection rationale:
% - Eye blink artifacts: Typically strongest at frontal electrodes (FP1, FP2, AF3, AF4)
% - Muscle artifacts: From jaw clenching, yawning (T7, T8, F7, F8) - high frequency components
% - Brain components: Neural activity (e.g., alpha rhythm) strongest over occipital lobe (O1, O2)
%   Should NOT be flagged for removal 

%% ============== MANUAL COMPONENT REVIEW AND FINAL REMOVAL ==============
% Review automatically flagged components and perform final cleanup

% Display number of automatically flagged components
num_flagged = sum(EEG.reject.gcompreject);
fprintf('%d components have been automatically flagged for rejection.\n', num_flagged);

% Open component selection GUI for manual review and adjustment
% User can modify the automatic selection before final removal
fprintf('Next, visually review and modify this selection in the GUI...\n');
comps_to_reject = pop_selectcomps(EEG, 1:size(EEG.icawinv, 2));

% Get final list of components to be removed
rejected_components = find(EEG.reject.gcompreject);

% Remove selected artifact components from the data
EEG = pop_subcomp(EEG, rejected_components, 0);
EEG = eeg_checkset(EEG);

% Extract cleaned data matrix for saving
cleaned_data_matrix = EEG.data';
clear T_data_cleaned;

%% ============== QUANTITATIVE CLEANING VALIDATION METRICS ===============
% Calculate statistical measures to validate cleaning effectiveness

fprintf('\n=== CLEANING VALIDATION METRICS ===\n');

% Calculate metrics for original (filtered) vs cleaned data
original_data = eegData_time_by_chans;  % Original filtered data (time x channels)
cleaned_data = cleaned_data_matrix;     % Cleaned data (time x channels)

% 1. SIGNAL VARIANCE (should be preserved for neural signals)
original_variance = var(original_data, 0, 1);  % Variance per channel
cleaned_variance = var(cleaned_data, 0, 1);
variance_retention = cleaned_variance ./ original_variance * 100;

fprintf('Signal Variance Retention per Channel (should be 70-95%% for good cleaning):\n');
for ch = 1:length(channel_names)
    fprintf('  %s: %.1f%%\n', channel_names{ch}, variance_retention(ch));
end
fprintf('  Average retention: %.1f%%\n\n', mean(variance_retention));

% 2. RMS (ROOT MEAN SQUARE) - Overall signal power
original_rms = sqrt(mean(original_data.^2, 1));
cleaned_rms = sqrt(mean(cleaned_data.^2, 1));
rms_ratio = cleaned_rms ./ original_rms;

fprintf('RMS Power Ratio (Cleaned/Original) per Channel:\n');
for ch = 1:length(channel_names)
    fprintf('  %s: %.3f\n', channel_names{ch}, rms_ratio(ch));
end
fprintf('  Average RMS ratio: %.3f\n\n', mean(rms_ratio));

% 3. SPECTRAL SIGNAL-TO-NOISE RATIO (SNR) in frequency bands
% Calculate power spectral density for key frequency bands
fs = 256;
[psd_orig, freqs] = pwelch(original_data, fs*2, fs, fs*2, fs);
[psd_clean, ~] = pwelch(cleaned_data, fs*2, fs, fs*2, fs);

% Define EEG frequency bands
delta_band = [1, 4];    % Delta: 1-4 Hz (sleep, deep states)
theta_band = [4, 8];    % Theta: 4-8 Hz (meditation, memory)
alpha_band = [8, 13];   % Alpha: 8-13 Hz (relaxed awareness)
beta_band = [13, 30];   % Beta: 13-30 Hz (active thinking)
gamma_band = [30, 50];  % Gamma: 30-50 Hz (cognitive processing)

% Function to calculate band power
calc_band_power = @(psd, freqs, band) mean(psd(freqs >= band(1) & freqs <= band(2), :), 1);

% Calculate band powers
bands = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
band_ranges = {delta_band, theta_band, alpha_band, beta_band, gamma_band};

fprintf('Spectral Power Changes by Frequency Band:\n');
for b = 1:length(bands)
    orig_power = calc_band_power(psd_orig, freqs, band_ranges{b});
    clean_power = calc_band_power(psd_clean, freqs, band_ranges{b});
    power_change = (clean_power ./ orig_power - 1) * 100;
    
    fprintf('%s Band (%.0f-%.0f Hz): %.1f%% change (avg across channels)\n', ...
        bands{b}, band_ranges{b}(1), band_ranges{b}(2), mean(power_change));
end
fprintf('\n');

% 4. HIGH-FREQUENCY NOISE REDUCTION (50+ Hz)
noise_band = [50, fs/2-1];  % High frequency noise band
orig_noise = calc_band_power(psd_orig, freqs, noise_band);
clean_noise = calc_band_power(psd_clean, freqs, noise_band);
noise_reduction = (1 - clean_noise ./ orig_noise) * 100;

fprintf('High-Frequency Noise Reduction (50+ Hz):\n');
fprintf('  Average noise reduction: %.1f%%\n', mean(noise_reduction));
fprintf('  Best channel: %s (%.1f%% reduction)\n', channel_names{noise_reduction == max(noise_reduction)}, max(noise_reduction));
fprintf('  Worst channel: %s (%.1f%% reduction)\n\n', channel_names{noise_reduction == min(noise_reduction)}, min(noise_reduction));

% 5. KURTOSIS - Measure of signal spikiness (artifacts create high kurtosis)
original_kurtosis = kurtosis(original_data, 1, 1);
cleaned_kurtosis = kurtosis(cleaned_data, 1, 1);
kurtosis_reduction = original_kurtosis - cleaned_kurtosis;

fprintf('Kurtosis Reduction (artifact spikiness removal):\n');
fprintf('  Average kurtosis reduction: %.2f (higher = better artifact removal)\n', mean(kurtosis_reduction));
for ch = 1:length(channel_names)
    fprintf('  %s: %.2f → %.2f (reduction: %.2f)\n', ...
        channel_names{ch}, original_kurtosis(ch), cleaned_kurtosis(ch), kurtosis_reduction(ch));
end
fprintf('\n');

% 6. CORRELATION BETWEEN CHANNELS (should remain high for neural signals)
orig_corr_matrix = corrcoef(original_data);
clean_corr_matrix = corrcoef(cleaned_data);

% Average inter-channel correlation (excluding diagonal)
mask = ~eye(size(orig_corr_matrix));
orig_avg_corr = mean(orig_corr_matrix(mask));
clean_avg_corr = mean(clean_corr_matrix(mask));

fprintf('Inter-Channel Correlation (neural signal preservation):\n');
fprintf('  Original average: %.3f\n', orig_avg_corr);
fprintf('  Cleaned average: %.3f\n', clean_avg_corr);
fprintf('  Change: %.3f (should be minimal for good cleaning)\n\n', clean_avg_corr - orig_avg_corr);

% 7. SUMMARY QUALITY METRICS
fprintf('=== CLEANING QUALITY SUMMARY ===\n');
quality_score = 0;
comments = {};

% Variance retention check
if mean(variance_retention) >= 75 && mean(variance_retention) <= 95
    fprintf('✓ Signal variance retention: GOOD (%.1f%%)\n', mean(variance_retention));
    quality_score = quality_score + 1;
else
    fprintf('⚠ Signal variance retention: POOR (%.1f%%) - should be 75-95%%\n', mean(variance_retention));
    comments{end+1} = 'Check if too much signal was removed';
end

% Noise reduction check
if mean(noise_reduction) >= 20
    fprintf('✓ High-frequency noise reduction: GOOD (%.1f%%)\n', mean(noise_reduction));
    quality_score = quality_score + 1;
else
    fprintf('⚠ High-frequency noise reduction: POOR (%.1f%%) - should be >20%%\n', mean(noise_reduction));
    comments{end+1} = 'Noise removal may be insufficient';
end

% Kurtosis reduction check
if mean(kurtosis_reduction) > 0.5
    fprintf('✓ Artifact removal (kurtosis): GOOD (%.2f reduction)\n', mean(kurtosis_reduction));
    quality_score = quality_score + 1;
else
    fprintf('⚠ Artifact removal (kurtosis): POOR (%.2f reduction)\n', mean(kurtosis_reduction));
    comments{end+1} = 'Artifacts may still be present';
end

% Correlation preservation check
if abs(clean_avg_corr - orig_avg_corr) < 0.1
    fprintf('✓ Neural signal correlation: PRESERVED (%.3f)\n', clean_avg_corr);
    quality_score = quality_score + 1;
else
    fprintf('⚠ Neural signal correlation: CHANGED (%.3f → %.3f)\n', orig_avg_corr, clean_avg_corr);
    comments{end+1} = 'Neural signal structure may be altered';
end

fprintf('\nOVERALL CLEANING QUALITY: %d/4\n', quality_score);
if quality_score >= 3
    fprintf('STATUS: EXCELLENT - Data is well cleaned and ready for analysis\n');
elseif quality_score >= 2
    fprintf('STATUS: GOOD - Data cleaning is acceptable with minor issues\n');
else
    fprintf('STATUS: POOR - Consider adjusting cleaning parameters\n');
end

if ~isempty(comments)
    fprintf('\nRECOMMENDATIONS:\n');
    for i = 1:length(comments)
        fprintf('• %s\n', comments{i});
    end
end

fprintf('\n=== END VALIDATION METRICS ===\n\n');

%% ===================== SAVE CLEANED EEG DATA ===========================
% Reconstruct data table with cleaned EEG data and save results

% Create new table with cleaned data
T_data_cleaned = T_data;  % Keep timestamp and counter columns
% T_data_cleaned(:, 3:4) = T_data(:, 17:18);  % Optional: add marker columns
temp_table = array2table(cleaned_data_matrix);  % Convert cleaned EEG matrix to table

% Combine original metadata with cleaned EEG data
T_data_cleaned(:, 3:16) = temp_table;
T_data.Properties.VariableNames = new_headers;

% Save cleaned data in both EEGLAB and MATLAB formats
cd('D:\auditory_perrand_data_code\cleaned_data');
extracted_string = fname(1 : strfind(fname, '_EPOCX'));

% Save EEGLAB dataset (.set file)
EEG = pop_saveset(EEG, 'filename', extracted_string);

% Save MATLAB data table (.mat file)
mat_filename = [extracted_string, '.mat'];
save(mat_filename, 'T_data_cleaned');

fprintf('Cleaned EEG data saved successfully.\n\n');

%==========================================================================
%                         MARKER/EVENT DATA PROCESSING
%==========================================================================
% This section processes event markers separately from EEG data
% for experimental event timing and stimulus presentation analysis
%==========================================================================

%% ================== INITIALIZE FOR MARKER PROCESSING ===================
% Reset environment for marker data processing
cd('D:\auditory_perrand_data_code\eeg_perrand_analysis_5725\analysis');
clear;
clc;
close all;

%% ================= LOAD AND PROCESS MARKER DATA ========================
% Extract event markers and timing information for experimental analysis

% Select data file containing marker/event information
[fname, fdir] = uigetfile( ...
    {'*.csv', 'CSV Files (*.csv)'; ...
     '*.xlsx', 'Excel Files (*.xlsx)'; ...
     '*.txt*', 'Text Files (*.txt*)'}, ...
    'Pick a file');
filename = fullfile(fdir, fname);
fprintf('Selected file: %s\n', filename);

% Parse header information (consistent with EEG data processing)
fileID = fopen(filename, 'r');
fgetl(fileID); % first line - header diff ids 
headerLine = fgetl(fileID); % second line only 
fclose(fileID);

% Load marker data and extract relevant columns
T = readtable(filename, 'HeaderLines', 1);
% Note: Different column indices for marker data vs EEG data
columns_to_keep_indices = [3, 4, 6, 7]; % Select marker-relevant columns
T_data = T(:, columns_to_keep_indices);

% Assign descriptive names to marker columns
new_headers = {'type', 'markervalue', 'timestamp', 'markerid'};
T_data.Properties.VariableNames = new_headers;

%% ===================== SAVE MARKER DATA =================================
% Save processed marker/event data for subsequent analysis

% Switch to output directory
cd('D:\auditory_perrand_data_code\cleaned_data');

% Generate filename based on original file (consistent naming convention)
extracted_string = fname(1 : strfind(fname, '_EPOCX'));
mat_filename = [extracted_string, 'marker', '.mat'];

% Save marker data
save(mat_filename, 'T_data');

fprintf('Marker data processed and saved successfully.\n');
fprintf('Processing complete. Files saved in: D:\\auditory_perrand_data_code\\cleaned_data\n');

%==========================================================================
%                        CLEANED EEG VISUALIZATION
%==========================================================================
% Interactive scrollable GUI for visualizing the cleaned EEG data
%==========================================================================

%% ================= LOAD CLEANED DATA FOR VISUALIZATION ================
% Load the cleaned EEG data that was just processed

% Load the cleaned data file
load(fullfile('D:\auditory_perrand_data_code\cleaned_data', [extracted_string, '.mat']));

% Extract EEG data matrix (time x channels)
eeg_data = T_data_cleaned{:, 3:16};  % Extract EEG channels (columns 3-16)
channel_labels = T_data_cleaned.Properties.VariableNames(3:16);
fs = 256;  % Sampling frequency
time_vector = (0:size(eeg_data,1)-1) / fs;  % Time vector in seconds

%% =================== CREATE SCROLLABLE EEG VIEWER GUI =================
% Build interactive GUI for EEG data visualization

% Launch the EEG viewer GUI
launch_eeg_viewer(eeg_data, channel_labels, fs, time_vector);

fprintf('\nInteractive EEG viewer launched. Use controls to navigate through the data.\n');
fprintf('- Use arrow buttons or slider to scroll through time\n');
fprintf('- Adjust "Time Window" to change display duration\n');
fprintf('- Adjust "Amplitude Scale" to change vertical spacing between channels\n');

%==========================================================================
%                            END OF SCRIPT
%==========================================================================

function launch_eeg_viewer(eeg_data, channel_labels, fs, time_vector)
% LAUNCH_EEG_VIEWER - Create an interactive scrollable EEG data viewer
%
% Usage: launch_eeg_viewer(eeg_data, channel_labels, fs, time_vector)
%
% Inputs:
%   eeg_data       - EEG data matrix (time_points x channels)
%   channel_labels - Cell array of channel names
%   fs             - Sampling frequency in Hz
%   time_vector    - Time vector in seconds

    % Create main figure
    fig = figure('Name', 'Cleaned EEG Data Viewer', 'NumberTitle', 'off', ...
        'Position', [100, 100, 1200, 800], 'MenuBar', 'none', 'ToolBar', 'figure');

    % Parameters for display
    window_duration = 10;  % Display window duration in seconds
    window_samples = window_duration * fs;
    n_channels = size(eeg_data, 2);
    channel_spacing = 100;  % Vertical spacing between channels

    % Initialize display parameters
    current_start = 1;
    max_start = max(1, size(eeg_data,1) - window_samples + 1);

    % Create axes for EEG plot
    ax = axes('Parent', fig, 'Position', [0.1, 0.2, 0.8, 0.7]);
    hold(ax, 'on');
    grid(ax, 'on');

    % Create UI controls
    uicontrol('Style', 'text', 'String', 'Time Window (seconds):', ...
        'Position', [50, 50, 120, 20], 'HorizontalAlignment', 'left');

    window_edit = uicontrol('Style', 'edit', 'String', num2str(window_duration), ...
        'Position', [180, 50, 60, 25], 'Callback', @update_window_callback);

    uicontrol('Style', 'text', 'String', 'Amplitude Scale:', ...
        'Position', [260, 50, 100, 20], 'HorizontalAlignment', 'left');

    scale_edit = uicontrol('Style', 'edit', 'String', num2str(channel_spacing), ...
        'Position', [370, 50, 60, 25], 'Callback', @update_scale_callback);

    % Navigation buttons
    uicontrol('Style', 'pushbutton', 'String', '<<', 'Position', [450, 50, 40, 25], ...
        'Callback', @(src,evt) scroll_data_callback(-window_samples));

    uicontrol('Style', 'pushbutton', 'String', '<', 'Position', [500, 50, 40, 25], ...
        'Callback', @(src,evt) scroll_data_callback(-window_samples/4));

    uicontrol('Style', 'pushbutton', 'String', '>', 'Position', [550, 50, 40, 25], ...
        'Callback', @(src,evt) scroll_data_callback(window_samples/4));

    uicontrol('Style', 'pushbutton', 'String', '>>', 'Position', [600, 50, 40, 25], ...
        'Callback', @(src,evt) scroll_data_callback(window_samples));

    % Time slider
    time_slider = uicontrol('Style', 'slider', 'Min', 1, 'Max', max_start, ...
        'Value', current_start, 'Position', [50, 20, 500, 20], ...
        'Callback', @slider_callback);

    % Time display
    time_text = uicontrol('Style', 'text', 'String', '', ...
        'Position', [570, 15, 200, 25], 'HorizontalAlignment', 'left');

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
        
        % Plot each channel with vertical offset
        colors = lines(n_channels);
        for ch = 1:n_channels
            offset = (n_channels - ch) * channel_spacing;
            plot(ax, current_time, current_data(:,ch) + offset, ...
                'Color', colors(ch,:), 'LineWidth', 1);
            
            % Add channel labels
            text(ax, current_time(1), offset, channel_labels{ch}, ...
                'VerticalAlignment', 'middle', 'FontSize', 10, 'FontWeight', 'bold');
        end
        
        % Set axis properties
        xlim(ax, [current_time(1), current_time(end)]);
        ylim(ax, [-channel_spacing, n_channels * channel_spacing]);
        xlabel(ax, 'Time (seconds)');
        ylabel(ax, 'Channels');
        title(ax, sprintf('Cleaned EEG Data - Window: %.1f - %.1f seconds', ...
            current_time(1), current_time(end)));
        grid(ax, 'on');
        
        % Update time display
        set(time_text, 'String', sprintf('Time: %.1f - %.1f s (Total: %.1f s)', ...
            current_time(1), current_time(end), time_vector(end)));
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
        if ~isnan(new_duration) && new_duration > 0
            window_duration = new_duration;
            window_samples = window_duration * fs;
            max_start = max(1, size(eeg_data,1) - window_samples + 1);
            current_start = min(current_start, max_start);
            set(time_slider, 'Max', max_start, 'Value', current_start);
            plot_eeg_data();
        else
            set(src, 'String', num2str(window_duration));
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

end