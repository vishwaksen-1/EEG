function results = computeBootstrappedRegionXCorr(all_data_cell)
    % computeBootstrappedRegionXCorr Calculates regional cross-correlation.
    % 1. Calculates XCorr for each subject individually.
    % 2. Bootstraps ACROSS SUBJECTS (N=500) to estimate population Mean/Std.
    %
    % Inputs:
    %   all_data_cell: Nx2 cell array where Col 1 is SubjectID, Col 2 is {EyesClosed, EyesOpen}
    %
    % Output:
    %   results: Struct with fields 'eyesClosed' and 'eyesOpen'.
    %            Structure: results.eyesClosed.set_1.corr.mean (8x8xLags)

    %% 1. Configuration
    num_bootstraps = 500;
    fs = 256;
    max_lag_sec = 2; 
    max_lag = round(max_lag_sec * fs); 
    num_lags = 2 * max_lag + 1;
    
    window_sec = 5; 
    window_len = window_sec * fs;
    
    % Region Mapping
    regions = {[1,3,4], [11,12,14], [5], [10], [6], [9], [7], [8]}; 
    regLabels = {'L_Frontal','R_Frontal','L_Temporal','R_Temporal', ...
                 'L_Parietal','R_Parietal','L_Occipital','R_Occipital'};
    num_regions = length(regions);
    
    %% 2. Input Validation
    if ~iscell(all_data_cell) || size(all_data_cell, 2) < 2
        error('Input must be an Nx2 cell array (Batch format from previous script).');
    end
    
    subject_ids = all_data_cell(:, 1);
    data_cells = all_data_cell(:, 2);
    n_subjects = length(subject_ids);
    
    fprintf('Starting Group Analysis on %d subjects...\n', n_subjects);

    %% 3. Pre-Calculate XCorr for EVERY Subject
    % We store all subject matrices in 4D arrays: [Regions x Regions x Lags x nSubjects]
    
    % Initialize storage
    store_EC = zeros(num_regions, num_regions, num_lags, n_subjects);
    store_EO = zeros(num_regions, num_regions, num_lags, n_subjects);
    
    % Track valid subjects (in case some are skipped due to error)
    valid_mask = false(n_subjects, 1);
    
    lags_vector = [];

    parfor s = 1:n_subjects
        % (Using parfor for speed if parallel pool is available, otherwise it runs as for)
        try
            sub_data = data_cells{s}; % {EyesClosed, EyesOpen}
            
            % --- Process Eyes Closed (Index 1) ---
            xc_EC = calculateSubjectXCorr(sub_data{1}, regions, window_len, max_lag, num_regions, num_lags);
            
            % --- Process Eyes Open (Index 2) ---
            xc_EO = calculateSubjectXCorr(sub_data{2}, regions, window_len, max_lag, num_regions, num_lags);
            
            store_EC(:, :, :, s) = xc_EC;
            store_EO(:, :, :, s) = xc_EO;
            valid_mask(s) = true;
            
        catch ME
            fprintf('Error processing Subject %d: %s\n', s, ME.message);
        end
    end
    
    % Filter out invalid subjects
    store_EC = store_EC(:, :, :, valid_mask);
    store_EO = store_EO(:, :, :, valid_mask);
    n_valid = sum(valid_mask);
    
    if n_valid == 0
        error('No valid subjects processed.');
    end
    
    % Get lags vector (just once from xcorr to store in output)
    [~, lags_vector] = xcorr(zeros(window_len, 1), max_lag, 'coeff');

    fprintf('Successfully pre-calculated XCorr for %d subjects.\n', n_valid);
    fprintf('Bootstrapping over subjects (%d bootstraps)...\n', num_bootstraps);

    %% 4. Bootstrap Over Subjects & Format Output
    
    % Define conditions to loop over
    stores = {store_EC, store_EO};
    cond_names = {'eyesClosed', 'eyesOpen'};
    
    for c = 1:2
        current_store = stores{c}; % [8 x 8 x 257 x N_Subj]
        
        boot_means = zeros(num_regions, num_regions, num_lags, num_bootstraps);
        
        rng('default'); % Reproducibility
        
        for b = 1:num_bootstraps
            % 1. Resample SUBJECT indices with replacement
            resample_idx = randi(n_valid, 1, n_valid);
            
            % 2. Select those subjects
            sample_data = current_store(:, :, :, resample_idx);
            
            % 3. Calculate Mean across the resampled subjects
            boot_means(:, :, :, b) = mean(sample_data, 4);
        end
        
        % Calculate Stats across the bootstraps
        final_mean = mean(boot_means, 4);
        final_std = std(boot_means, 0, 4);
        
        % Pack into structure
        params_struct.num_bootstraps = num_bootstraps;
        params_struct.n_subjects = n_valid;
        params_struct.regions = regLabels;
        
        res_struct.mean = final_mean;
        res_struct.std = final_std;
        res_struct.lags = lags_vector;
        res_struct.params = params_struct;
        
        % Specific Output Format: results.(cond).set_1.corr
        results.(cond_names{c}).set_1.corr = res_struct;
    end
    
    fprintf('Done.\n');
end

%% Helper Function: Process Single Subject
function subject_xc_mean = calculateSubjectXCorr(condition_data, regions, window_len, max_lag, num_regions, num_lags)
    % Extracts data, handles types, aggregates regions, and computes mean XCorr across windows
    
    % 1. Extract Raw Data
    if isstruct(condition_data)
        if isfield(condition_data, 'eeg_only')
            raw_data = condition_data.eeg_only;
        elseif isfield(condition_data, 'data')
            raw_data = condition_data.data(:, 3:end); 
        else
            error('Invalid Struct');
        end
    elseif isnumeric(condition_data)
        if size(condition_data, 2) >= 16
            raw_data = condition_data(:, 3:end);
        else
            raw_data = condition_data; 
        end
    else
        error('Invalid Data Type');
    end
    
    % 2. Region Aggregation
    region_data = zeros(size(raw_data, 1), num_regions);
    for r = 1:num_regions
        region_data(:, r) = mean(raw_data(:, regions{r}), 2);
    end
    
    % 3. Windowing & XCorr
    [n_samples, ~] = size(region_data);
    n_windows = floor(n_samples / window_len);
    
    if n_windows < 1
        % Fallback if data is shorter than one window (unlikely given previous checks)
        n_windows = 1;
        window_len = n_samples; 
    end
    
    windowed_xcorr = zeros(num_regions, num_regions, num_lags, n_windows);
    
    for w = 1:n_windows
        start_idx = (w-1) * window_len + 1;
        end_idx = start_idx + window_len - 1;
        chunk = region_data(start_idx:end_idx, :);
        
        [xc, ~] = xcorr(chunk, max_lag, 'coeff');
        
        % Reshape and Permute
        temp_xc = reshape(xc, [num_lags, num_regions, num_regions]);
        windowed_xcorr(:, :, :, w) = permute(temp_xc, [2, 3, 1]);
    end
    
    % 4. Average across windows to get THE Subject's XCorr
    subject_xc_mean = mean(windowed_xcorr, 4);
end