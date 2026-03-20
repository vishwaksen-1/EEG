function debug_data_overlap(structA, structB, structNameA, structNameB)
% Run this to check if your two structs have identical data for Stim 1 (REG)
% Usage example: 
%   debug_data_overlap(activeStim12, activeStim34, 'activeStim12', 'activeStim34')

    fprintf('\n--- Debugging Data Overlap for %s vs %s ---\n', structNameA, structNameB);

    % 1. Extract just Stimulus 1 (REG) from the full_trial fields
    dataA = structA.full_trial(:, :, 1, :, :);
    dataB = structB.full_trial(:, :, 1, :, :);

    % 2. Check for exact equality
    if isequal(dataA, dataB)
        fprintf('⚠️ WARNING: The REG data in %s and %s are EXACTLY identical!\n', structNameA, structNameB);
        fprintf('   This is why your plots are perfectly overlapping.\n');
        fprintf('   Check how you load or assign these variables in your workspace.\n');
    else
        fprintf('✅ The data matrices are NOT exactly identical.\n');
        
        % 3. Check the maximum numerical difference (just in case they are close but not exact)
        max_diff = max(abs(dataA - dataB), [], 'all', 'omitnan');
        fprintf('   Maximum absolute difference between the two datasets: %f\n', max_diff);
        
        if max_diff < 1e-10
            fprintf('⚠️ The difference is essentially zero. They are practically identical.\n');
        else
            fprintf('   They are genuinely different datasets. If they still overlap in the plot,\n');
            fprintf('   they might just have highly similar trial-averaged means.\n');
        end
    end
    
    % 4. Quick visual difference plot of the trial-and-channel averages
    avgA = squeeze(mean(mean(dataA, 4, 'omitnan'), 2, 'omitnan')); % [time x subj]
    avgB = squeeze(mean(mean(dataB, 4, 'omitnan'), 2, 'omitnan')); % [time x subj]
    
    figure('Name', 'Debug Difference Plot');
    plot(mean(avgA, 2, 'omitnan') - mean(avgB, 2, 'omitnan'), 'k', 'LineWidth', 1.5);
    title(sprintf('Difference between %s and %s (Mean across subjects)', structNameA, structNameB));
    xlabel('Time Samples');
    ylabel('Amplitude Difference');
    grid on;
    
    fprintf('--------------------------------------------------\n\n');
end