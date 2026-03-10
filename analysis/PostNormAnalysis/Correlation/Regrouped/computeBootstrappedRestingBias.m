function results = computeBootstrappedRestingBias(all_data_cell)
    % computeBootstrappedRestingBias Calculates the noise floor (bias) 
    % for resting state regional cross-correlation.
    %
    % Methodology:
    %   - Performs 500 bootstraps.
    %   - In each bootstrap:
    %       1. Takes each subject's data.
    %       2. SHUFFLES the time series of every channel independently 
    %          (destroying temporal correlations).
    %       3. Calculates Region-wise XCorr using the standard windowed method.
    %       4. Averages across all subjects to get the Group Bias for that boot.
    %   - Finally, calculates Mean and Std across the 500 bootstraps.
    %
    % Input:
    %   all_data_cell: Nx2 cell array {SubjectID, {EyesClosed, EyesOpen}}
    %
    % Output:
    %   results: Struct with fields 'eyesClosed' and 'eyesOpen'.
    %            Structure: results.eyesClosed.set_1.bias.mean (8x8xLags)

    %% 1. Configuration
    num_bootstraps = 500;
    fs = 256;
    max_lag_sec = 2; 
    max_lag = round(max_lag_sec * fs); 
    num_lags = 2 * max_lag + 1;
    
    window_sec = 5; 
    window_len = window_sec * fs;
    
    % Region Mapping (Same as analysis script)
    regions = {[1,3,4], [11,12,14], [5], [10], [6], [9], [7], [8]}; 
    regLabels = {'L_Frontal','R_Frontal','L_Temporal','R_Temporal', ...
                 'L_Parietal','R_Parietal','L_Occipital','R_Occipital'};
    num_regions = length(regions);
    cond_names = {'eyesClosed', 'eyesOpen'};
    
    %% 2. Input Validation
    if ~iscell(all_data_cell) || size(all_data_cell, 2) < 2
        error('Input must be an Nx2 cell array (Batch format).');
    end
    
    % Pre-flight check: Extract just the data to avoid passing giant cells to parallel workers
    % We construct a lightweight structure for the workers
    n_subjects = size(all_data_cell, 1);
    clean_data_storage = cell(n_subjects, 2);
    valid_mask = false(n_subjects, 1);
    
    fprintf('Preparing data for bias calculation...\n');
    for s = 1:n_subjects
        try
            sub_raw = all_data_cell{s, 2};
            
            % Normalize data format for storage
            for c = 1:2
                d_in = sub_raw{c};
                if isstruct(d_in)
                    if isfield(d_in, 'eeg_only'), d = d_in.eeg_only;
                    elseif isfield(d_in, 'data'), d = d_in.data(:, 3:end);
                    end
                elseif isnumeric(d_in)
                    d = d_in(:, end-13:end); % Assume last 14 cols
                end
                clean_data_storage{s, c} = d;
            end
            valid_mask(s) = true;
        catch
            fprintf('Skipping invalid subject index %d\n', s);
        end
    end
    
    clean_data_storage = clean_data_storage(valid_mask, :);
    n_valid = sum(valid_mask);
    
    % Get lags vector
    [~, lags_vector] = xcorr(zeros(window_len, 1), max_lag, 'coeff');

    fprintf('Starting Bias Calculation on %d subjects (%d Bootstraps).\n', n_valid, num_bootstraps);
    fprintf('This may take some time due to permutation steps...\n');

    %% 3. Bootstrap Loop (Parallelized)
    
    for c = 1:2
        condition_name = cond_names{c};
        fprintf('Processing Condition: %s\n', condition_name);
        
        % Extract data for this condition only to reduce overhead
        current_cond_data = clean_data_storage(:, c);
        
        % Storage for bootstrap results: [Regions x Regions x Lags x Bootstraps]
        boot_results = zeros(num_regions, num_regions, num_lags, num_bootstraps);
        
        % Parallel Loop for Bootstraps
        parfor b = 1:num_bootstraps
            % Accumulator for the Group Mean of this bootstrap iteration
            group_accum = zeros(num_regions, num_regions, num_lags);
            
            % Loop over subjects (Inside the bootstrap)
            for s = 1:n_valid
                % 1. Get Subject Data
                original_data = current_cond_data{s};
                [n_samp, n_chan] = size(original_data);
                
                % 2. TIME SHUFFLE (The Bias Step)
                % Shuffle each channel independently
                shuffled_data = zeros(n_samp, n_chan);
                for ch = 1:n_chan
                    shuffled_data(:, ch) = original_data(randperm(n_samp), ch);
                end
                
                % 3. Calculate Region XCorr (Standard Windowed Method)
                % Aggregating channels to regions
                reg_data = zeros(n_samp, num_regions);
                for r = 1:num_regions
                    reg_data(:, r) = mean(shuffled_data(:, regions{r}), 2);
                end
                
                % Windowing
                n_windows = floor(n_samp / window_len);
                if n_windows < 1, n_windows = 1; end % Safety
                
                subj_win_accum = zeros(num_regions, num_regions, num_lags);
                
                for w = 1:n_windows
                    idx1 = (w-1)*window_len + 1;
                    idx2 = idx1 + window_len - 1;
                    chunk = reg_data(idx1:idx2, :);
                    
                    [xc, ~] = xcorr(chunk, max_lag, 'coeff');
                    
                    % Reshape [Lags x Regions^2] -> [Regions x Regions x Lags]
                    temp_xc = reshape(xc, [num_lags, num_regions, num_regions]);
                    subj_win_accum = subj_win_accum + permute(temp_xc, [2, 3, 1]);
                end
                
                % Average windows to get Subject Bias
                subj_bias = subj_win_accum / n_windows;
                
                % Add to Group Accumulator
                group_accum = group_accum + subj_bias;
            end
            
            % Average across subjects to get the Group Bias for this bootstrap
            boot_results(:, :, :, b) = group_accum / n_valid;
            
            if mod(b, 50) == 0
                fprintf('.'); % Progress indicator
            end
        end
        fprintf('\n');
        
        %% 4. Summary Statistics
        biasMean = mean(boot_results, 4);
        biasStd = std(boot_results, 0, 4);
        
        % Pack Results
        resStruct.mean = biasMean;
        resStruct.std = biasStd;
        resStruct.lags = lags_vector;
        resStruct.params.num_bootstraps = num_bootstraps;
        resStruct.params.regions = regLabels;
        
        results.(condition_name).set_1.bias = resStruct;
    end
    
    fprintf('Bias calculation complete.\n');
end