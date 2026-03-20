function check_data_range(rawDataStruct, structName)
% check_data_range - Prints statistics to determine the scale/units of raw EEG data
% 
% Usage example: 
%   check_data_range(activeStim12, 'Active Stim 12')

    if nargin < 2
        structName = 'Input Data';
    end
    
    fprintf('\n--- Analyzing Data Range for: %s ---\n', structName);

    % 1. Extract the full trial array
    if isfield(rawDataStruct, 'full_trial')
        data = rawDataStruct.full_trial;
    else
        error('The structure does not contain a ''full_trial'' field.');
    end

    % 2. Flatten the data and remove any NaNs to prevent calculation errors
    data_flat = data(:);
    data_valid = data_flat(~isnan(data_flat));
    
    if isempty(data_valid)
        fprintf('⚠️ WARNING: The data structure contains only NaNs!\n');
        return;
    end

    % 3. Calculate core statistics
    max_val  = max(data_valid);
    min_val  = min(data_valid);
    mean_val = mean(data_valid);
    std_val  = std(data_valid);
    
    % Use quantiles to find the typical range (ignoring 1% extreme outliers/spikes)
    % (Using quantile instead of prctile to avoid requiring the Stats toolbox)
    q_bounds = quantile(data_valid, [0.01, 0.99]);
    
    % 4. Print the report
    fprintf('Absolute Minimum : %12.6f\n', min_val);
    fprintf('Absolute Maximum : %12.6f\n', max_val);
    fprintf('Mean Value       : %12.6f\n', mean_val);
    fprintf('Standard Dev     : %12.6f\n', std_val);
    fprintf('Typical Range (1st - 99th percentile) : [%.6f to %.6f]\n', q_bounds(1), q_bounds(2));

    % 5. Smart Unit Estimation
    % Typical EEG amplitude is around 10 to 100 microvolts (uV)
    % 1 uV = 1e-6 V, 1 mV = 1e-3 V
    
    abs_mean_amp = mean(abs(data_valid));
    fprintf('\n> Unit Estimation based on avg absolute amplitude (%.6f):\n', abs_mean_amp);
    
    if abs_mean_amp < 1e-3
        fprintf('  💡 Looks like Volts (V).\n');
    elseif abs_mean_amp >= 1e-3 && abs_mean_amp < 1
        fprintf('  💡 Looks like milliVolts (mV).\n');
    elseif abs_mean_amp >= 1 && abs_mean_amp < 2000
        fprintf('  💡 Looks like microVolts (uV). This is standard for exported EEG.\n');
    else
        fprintf('  💡 Values are very large (>2000). Might be raw integer ADC values or highly amplified data.\n');
    end
    
    fprintf('--------------------------------------------------\n\n');
end