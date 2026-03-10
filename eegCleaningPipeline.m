function eegCleaningPipeline(data_folder)
% EEGCLEANINGPIPELINE A batch processing function for cleaning EEG data (all subjects in one folder)
%
%   This function iterates through all EEG data files ('.md.csv') and their
%   corresponding marker files ('_intervalMarker.csv') in a specified
%   folder. It applies a series of EEG preprocessing steps using EEGLAB,
%   generates a cleaning validation report, and saves the cleaned data
%   and markers to a new output folder.

%   Usage:
%       eegCleaningPipeline(data_folder)
%
%   Calls:
%       fileGlobber
%
%   Inputs:
%       data_folder (optional, string): The path to the folder containing
%                                       the raw EEG and marker files. If
%                                       not provided, the function uses a
%                                       default path from fileGlobber.
%
%   Output:
%       None. The function saves cleaned data, markers, and a cleaning
%       report to a new folder named 'Cleaned_YYYY_MM_DD_HH_MM_SS' inside
%       the local 'Cleaned' directory.
%
%   REQUIREMENTS:
%   - The 'fileGlobber' function must be in the MATLAB path.
%   - EEGLAB and its dependencies (e.g., ICLabel, clean_asr) must be
%     installed and on the MATLAB path.
%   - All required data files (EEG and marker) must be in the same folder.
%
%   EXAMPLE USAGE:
%       % Run the pipeline on the default folder
%       eegCleaningPipeline();
%
%       % Run the pipeline on a specific folder
%       eegCleaningPipeline('C:\MyProject\RawData');
    % Start timing for the entire pipeline
    tic;
    %======================================================================
    %                    INITIALIZATION
    %======================================================================
    
    % Ensure required directories are in the path. Adjust these as needed.
    % These paths should point to the location of the fileGlobber function,
    % EEGLAB, and any other dependencies.
    addpath('../'); % Assuming fileGlobber is one directory up
    
    % If the folder is not provided, use the default from fileGlobber
    if nargin < 1
        % This will run the fileGlobber function with its default folder
        files_info = fileGlobber('.*\.md\.csv$');
        % Extract the folder path from the first file in the list
        if ~isempty(files_info)
            [data_folder, ~, ~] = fileparts(files_info{1});
        else
            error('No data folder specified and fileGlobber did not find any files in its default location.');
        end
    else
        % Use the provided data_folder
        if ~isfolder(data_folder)
            error('Specified folder does not exist: %s', data_folder);
        end
        
        % Use fileGlobber to find all EEG data files in the provided folder
        eeg_files = fileGlobber('.*\.md\.csv$', data_folder);
    end
    % Get list of all EEG data files ('.md.csv')
    eeg_files = fileGlobber('.*\.md\.csv$', data_folder);
    
    if isempty(eeg_files)
        fprintf('No EEG data files found in %s. Exiting.\n', data_folder);
        return;
    end
    
    % Create the output directory with a timestamp
    output_base_dir = fullfile(pwd, 'Cleaned');
    if ~isfolder(output_base_dir)
        mkdir(output_base_dir);
    end
    timestamp_str = datestr(now, 'yyyy_mm_dd_HH_MM_SS');
    output_dir = fullfile(output_base_dir, ['Cleaned_', timestamp_str]);
    mkdir(output_dir);
    fprintf('Output folder created: %s\n\n', output_dir);
    
    %======================================================================
    %                    LOOP THROUGH ALL EEG FILES
    %======================================================================
    
    num_files_processed = 0;
    for i = 1:length(eeg_files)
        % Start timing for the current file
        file_tic = tic;
        eeg_fname = eeg_files{i};
        % Extract the common base filename part that comes before the '.md.csv' suffix.
        % This is a more robust way to handle varying filename lengths.
        base_filename_parts = regexp(eeg_fname, '(.*)\.md\.csv$', 'tokens', 'once');
        if isempty(base_filename_parts)
            fprintf('Could not extract base filename from %s. Skipping.\n', eeg_fname);
            continue;
        end
        base_filename = base_filename_parts{1};
        
        % Directly construct the marker filename, as the name is predictable.
        marker_fname = [base_filename, '_intervalMarker.csv'];
        
        % Check if the marker file actually exists in the data folder.
        marker_filepath = fullfile(data_folder, marker_fname);
        if ~isfile(marker_filepath)
            fprintf('No corresponding marker file found for %s. Skipping.\n', eeg_fname);
            continue;
        end
        fprintf('--------------------------------------------------\n');
        fprintf('Processing file %d/%d: %s\n', i, length(eeg_files), eeg_fname);
        fprintf('Corresponding marker file: %s\n', marker_fname);
        fprintf('--------------------------------------------------\n\n');
        % Full file paths
        eeg_filepath = fullfile(data_folder, eeg_fname);
        %==================================================================
        %                  EEG DATA CLEANING & PREPROCESSING
        %==================================================================
        
        % 1. Load and parse EEG data file
        
        % Parse header information from CSV file
        fileID = fopen(eeg_filepath, 'r');
        fgetl(fileID); % first line - header diff ids 
        headerLine = fgetl(fileID); % second line only 
        fclose(fileID);
        
        % Extract and clean channel names
        originalHeaders = strsplit(headerLine, ',');
        validHeaders = strrep(originalHeaders, 'EEG.', '');    
        
        % Load data table and select relevant columns
        T = readtable(eeg_filepath, 'HeaderLines', 1);
        channel_names = validHeaders(5:18);
        columns_to_keep_indices = [2, 3, 5:18, 22, 23, 24]; % Columns 2, 3, data = 5 to 18
        T_data = T(:, columns_to_keep_indices);
        
        % Assign meaningful column names
        new_headers = {'timestamp', 'counter', channel_names{:}, 'markerInd', 'markerType', 'markerValue'};
        T_data.Properties.VariableNames = new_headers;
        
        % 2. EEG DATA PREPARATION FOR EEGLAB
        fs = 256; % Set sampling frequency
        eegData_time_by_chans = T_data{:, 3:16};
        eegData = eegData_time_by_chans'; % EEGLAB expects channels x timepoints
        [nbchan, pnts] = size(eegData);
        
        % 3. EEGLAB DATASET CREATION
        EEG = pop_importdata('dataformat', 'array', 'data', eegData, ...
                             'setname', 'raw_data', 'srate', fs, ...
                             'nbchan', nbchan);
        EEG = eeg_checkset(EEG);
        fprintf('EEGLAB dataset created.\n\n');
        
        % 4. BASIC SIGNAL FILTERING
        EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 0);
        EEG = eeg_checkset(EEG);
        fprintf('Applied 1 Hz high-pass filter.\n');
        
        EEG = pop_eegfiltnew(EEG, 'hicutoff', 45, 'plotfreqz', 0);
        EEG = eeg_checkset(EEG);
        fprintf('Applied 45 Hz low-pass filter.\n\n');
        
        % 5. ADVANCED PREPROCESSING STEPS
        EEG = pop_reref(EEG, []);
        EEG = eeg_checkset(EEG);
        EEG = clean_asr(EEG, 10);
        EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'interrupt', 'on');
        EEG = eeg_checkset(EEG);
        
        % 6. ICA COMPONENT CLASSIFICATION & REMOVAL
        channel_location_file_path = 'D:\auditory_perrand_data_code\eeg_perrand_analysis_5725\emtv_ch_loc.ced';
        loc_filename = channel_location_file_path;
        EEG.chanlocs = readlocs(loc_filename);
        EEG = iclabel(EEG);
        
        rejection_thresholds = [NaN NaN; 0.8 1.0; 0.8 1.0; NaN NaN; NaN NaN; NaN NaN; NaN NaN];
        EEG = pop_icflag(EEG, rejection_thresholds);
        
        num_flagged = sum(EEG.reject.gcompreject);
        fprintf('%d components have been automatically flagged for rejection.\n', num_flagged);
        
        % No manual review, so components are removed automatically
        rejected_components = find(EEG.reject.gcompreject);
        EEG = pop_subcomp(EEG, rejected_components, 0);
        EEG = eeg_checkset(EEG);
        cleaned_data_matrix = EEG.data';
        clear T_data_cleaned;
        
        % 7. QUANTITATIVE CLEANING VALIDATION METRICS
        
        % Prepare filename for statistics report
        stats_filename = [base_filename, '_cleaning_stats.txt'];
        stats_filepath = fullfile(output_dir, stats_filename);
        stats_fileID = fopen(stats_filepath, 'w');
        
        fprintf(stats_fileID, 'EEG Data Cleaning Report for: %s\n', eeg_fname);
        fprintf(stats_fileID, 'Generated on: %s\n\n', datestr(now));
        
        original_data = eegData_time_by_chans;
        cleaned_data = cleaned_data_matrix;
        
        fprintf(stats_fileID, '=== CLEANING VALIDATION METRICS ===\n');
        original_variance = var(original_data, 0, 1);
        cleaned_variance = var(cleaned_data, 0, 1);
        variance_retention = cleaned_variance ./ original_variance * 100;
        fprintf(stats_fileID, 'Signal Variance Retention per Channel:\n');
        for ch = 1:length(channel_names)
            fprintf(stats_fileID, '  %s: %.1f%%\n', channel_names{ch}, variance_retention(ch));
        end
        fprintf(stats_fileID, '  Average retention: %.1f%%\n\n', mean(variance_retention));
        
        original_rms = sqrt(mean(original_data.^2, 1));
        cleaned_rms = sqrt(mean(cleaned_data.^2, 1));
        rms_ratio = cleaned_rms ./ original_rms;
        fprintf(stats_fileID, 'RMS Power Ratio (Cleaned/Original) per Channel:\n');
        for ch = 1:length(channel_names)
            fprintf(stats_fileID, '  %s: %.3f\n', channel_names{ch}, rms_ratio(ch));
        end
        fprintf(stats_fileID, '  Average RMS ratio: %.3f\n\n', mean(rms_ratio));
        
        fs = 256;
        [psd_orig, freqs] = pwelch(original_data, fs*2, fs, fs*2, fs);
        [psd_clean, ~] = pwelch(cleaned_data, fs*2, fs, fs*2, fs);
        
        delta_band = [1, 4];    
        theta_band = [4, 8];    
        alpha_band = [8, 13];   
        beta_band = [13, 30];   
        gamma_band = [30, 50];  
        
        calc_band_power = @(psd, freqs, band) mean(psd(freqs >= band(1) & freqs <= band(2), :), 1);
        
        bands = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
        band_ranges = {delta_band, theta_band, alpha_band, beta_band, gamma_band};
        fprintf(stats_fileID, 'Spectral Power Changes by Frequency Band:\n');
        for b = 1:length(bands)
            orig_power = calc_band_power(psd_orig, freqs, band_ranges{b});
            clean_power = calc_band_power(psd_clean, freqs, band_ranges{b});
            power_change = (clean_power ./ orig_power - 1) * 100;
            
            fprintf(stats_fileID, '%s Band (%.0f-%.0f Hz): %.1f%% change (avg across channels)\n', ...
                bands{b}, band_ranges{b}(1), band_ranges{b}(2), mean(power_change));
        end
        fprintf(stats_fileID, '\n');
        
        noise_band = [50, fs/2-1];
        orig_noise = calc_band_power(psd_orig, freqs, noise_band);
        clean_noise = calc_band_power(psd_clean, freqs, noise_band);
        noise_reduction = (1 - clean_noise ./ orig_noise) * 100;
        fprintf(stats_fileID, 'High-Frequency Noise Reduction (50+ Hz):\n');
        fprintf(stats_fileID, '  Average noise reduction: %.1f%%\n', mean(noise_reduction));
        fprintf(stats_fileID, '  Best channel: %s (%.1f%% reduction)\n', channel_names{noise_reduction == max(noise_reduction)}, max(noise_reduction));
        fprintf(stats_fileID, '  Worst channel: %s (%.1f%% reduction)\n\n', channel_names{noise_reduction == min(noise_reduction)}, min(noise_reduction));
        
        original_kurtosis = kurtosis(original_data, 1, 1);
        cleaned_kurtosis = kurtosis(cleaned_data, 1, 1);
        kurtosis_reduction = original_kurtosis - cleaned_kurtosis;
        fprintf(stats_fileID, 'Kurtosis Reduction (artifact spikiness removal):\n');
        fprintf(stats_fileID, '  Average kurtosis reduction: %.2f (higher = better artifact removal)\n', mean(kurtosis_reduction));
        for ch = 1:length(channel_names)
            fprintf(stats_fileID, '  %s: %.2f -> %.2f (reduction: %.2f)\n', ...
                channel_names{ch}, original_kurtosis(ch), cleaned_kurtosis(ch), kurtosis_reduction(ch));
        end
        fprintf(stats_fileID, '\n');
        
        orig_corr_matrix = corrcoef(original_data);
        clean_corr_matrix = corrcoef(cleaned_data);
        mask = ~eye(size(orig_corr_matrix));
        orig_avg_corr = mean(orig_corr_matrix(mask));
        clean_avg_corr = mean(clean_corr_matrix(mask));
        fprintf(stats_fileID, 'Inter-Channel Correlation (neural signal preservation):\n');
        fprintf(stats_fileID, '  Original average: %.3f\n', orig_avg_corr);
        fprintf(stats_fileID, '  Cleaned average: %.3f\n', clean_avg_corr);
        fprintf(stats_fileID, '  Change: %.3f (should be minimal for good cleaning)\n\n', clean_avg_corr - orig_avg_corr);
        
        quality_score = 0;
        comments = {};
        if mean(variance_retention) >= 75 && mean(variance_retention) <= 95
            quality_score = quality_score + 1;
        end
        if mean(noise_reduction) >= 20
            quality_score = quality_score + 1;
        end
        if mean(kurtosis_reduction) > 0.5
            quality_score = quality_score + 1;
        end
        if abs(clean_avg_corr - orig_avg_corr) < 0.1
            quality_score = quality_score + 1;
        end
        
        fprintf(stats_fileID, '=== CLEANING QUALITY SUMMARY ===\n');
        fprintf(stats_fileID, 'OVERALL CLEANING QUALITY: %d/4\n', quality_score);
        
        fclose(stats_fileID);
        
        % 8. SAVE CLEANED EEG DATA
        % Create a new table for the cleaned data, preserving the original column headers.
        % First, create a table from the cleaned data matrix
        T_data_cleaned = T_data;

        temp_table = array2table(cleaned_data_matrix);
        
        % Then, set the column headers to the original channel names
        T_data_cleaned(:, 3:16) = temp_table;
        T_data.Properties.VariableNames = new_headers;
        
        cleaned_eeg_filename = [base_filename, '.mat'];
        save(fullfile(output_dir, cleaned_eeg_filename), 'T_data_cleaned');
        
        % 9. LOAD AND PROCESS MARKER DATA
        
        fileID = fopen(marker_filepath, 'r');
        fgetl(fileID);
        headerLine = fgetl(fileID);
        fclose(fileID);
        
        T_markers = readtable(marker_filepath, 'HeaderLines', 1);
        columns_to_keep_indices = [3, 4, 6, 7];
        T_markers_data = T_markers(:, columns_to_keep_indices);
        new_headers = {'type', 'markervalue', 'timestamp', 'markerid'};
        T_markers_data.Properties.VariableNames = new_headers;
        
        marker_mat_filename = [base_filename, '_marker.mat'];
        save(fullfile(output_dir, marker_mat_filename), 'T_markers_data');
        
        num_files_processed = num_files_processed + 1;
        
        % End timing for the current file and display the elapsed time
        file_elapsed_time = toc(file_tic);
        fprintf('Processing of %s completed in %.2f seconds. Output saved to %s\n\n', eeg_fname, file_elapsed_time, output_dir);
    end
    
    % End timing for the entire pipeline and display the total elapsed time
    total_elapsed_time = toc;
    fprintf('--------------------------------------------------\n');
    fprintf('Batch processing complete.\n');
    fprintf('Total files processed: %d\n', num_files_processed);
    fprintf('Total pipeline duration: %.2f seconds.\n', total_elapsed_time);
    fprintf('--------------------------------------------------\n');
end


% 120= sub*14*18 tokens* 10trials* 
% 
% 
% 270 ke liye = sub*14*12 tokens* 10trials* 
% 
% 