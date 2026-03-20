function plot_eeg_results(actnorm, passnorm, ch_idx)
% plot_eeg_results - Generates 8 plots with 95% CI based on normalized EEG data
% 
% Usage:
%   plot_eeg_results(actnorm, passnorm, [7, 8]); % Plots average of channels 7 & 8 (O1, O2)
%   plot_eeg_results(actnorm, passnorm, 'gfp');  % Plots Global Field Power (RMS across all channels)
% 
% Assumes actnorm and passnorm contain fields: .Out12 and .Out34

    if nargin < 3
        ch_idx = 'gfp'; % Default to Global Field Power if no channels specified
    end

    % --- 1. Process Channels ---
    % Squeeze() reduces the matrix to [numSubjects x numTime]
    
    if ischar(ch_idx) && strcmpi(ch_idx, 'gfp')
        % Global Field Power: Standard Deviation (or RMS) across all channels (dim 2)
        % This prevents positive and negative voltages from canceling each other out
        act_12_1 = squeeze(std(actnorm.Out12.stim1_zscore, 0, 2, 'omitnan'));
        act_12_2 = squeeze(std(actnorm.Out12.stim2_zscore, 0, 2, 'omitnan'));
        act_34_1 = squeeze(std(actnorm.Out34.stim1_zscore, 0, 2, 'omitnan'));
        act_34_2 = squeeze(std(actnorm.Out34.stim2_zscore, 0, 2, 'omitnan'));
        
        pass_12_1 = squeeze(std(passnorm.Out12.stim1_zscore, 0, 2, 'omitnan'));
        pass_12_2 = squeeze(std(passnorm.Out12.stim2_zscore, 0, 2, 'omitnan'));
        pass_34_1 = squeeze(std(passnorm.Out34.stim1_zscore, 0, 2, 'omitnan'));
        pass_34_2 = squeeze(std(passnorm.Out34.stim2_zscore, 0, 2, 'omitnan'));
        
        y_label_text = 'Z-Score (GFP)';
    else
        % Region of Interest: Extract specific channels and average ONLY those
        act_12_1 = squeeze(mean(actnorm.Out12.stim1_zscore(:, ch_idx, :), 2, 'omitnan'));
        act_12_2 = squeeze(mean(actnorm.Out12.stim2_zscore(:, ch_idx, :), 2, 'omitnan'));
        act_34_1 = squeeze(mean(actnorm.Out34.stim1_zscore(:, ch_idx, :), 2, 'omitnan'));
        act_34_2 = squeeze(mean(actnorm.Out34.stim2_zscore(:, ch_idx, :), 2, 'omitnan'));
        
        pass_12_1 = squeeze(mean(passnorm.Out12.stim1_zscore(:, ch_idx, :), 2, 'omitnan'));
        pass_12_2 = squeeze(mean(passnorm.Out12.stim2_zscore(:, ch_idx, :), 2, 'omitnan'));
        pass_34_1 = squeeze(mean(passnorm.Out34.stim1_zscore(:, ch_idx, :), 2, 'omitnan'));
        pass_34_2 = squeeze(mean(passnorm.Out34.stim2_zscore(:, ch_idx, :), 2, 'omitnan'));
        
        y_label_text = 'Z-Score (ROI Avg)';
    end

    % --- 2. Average Stim1's and Stim2's across Outs ---
    % Averaging the two datasets (Out12 and Out34) per subject
    act_reg_avg  = (act_12_1 + act_34_1) / 2;
    act_rand_avg = (act_12_2 + act_34_2) / 2;
    
    pass_reg_avg  = (pass_12_1 + pass_34_1) / 2;
    pass_rand_avg = (pass_12_2 + pass_34_2) / 2;

    % --- 3. Setup Time Axis ---
    numTime = size(act_12_1, 2);
    t = linspace(0, 6.5, numTime);

    % --- 4. Plotting ---

    % Plot 1: Active - Average REG vs Average RAND
    figure('Name', 'Active & Passive Averages');
    ax1 = subplot(2, 1, 1);
    plot_with_ci(ax1, t, act_reg_avg, 'Stim 1 (REG Avg)', act_rand_avg, 'Stim 2 (RAND Avg)', ...
                 'Active: Avg REG vs Avg RAND', y_label_text);

    % Plot 2: Passive - Average REG vs Average RAND
    ax2 = subplot(2, 1, 2);
    plot_with_ci(ax2, t, pass_reg_avg, 'Stim 1 (REG Avg)', pass_rand_avg, 'Stim 2 (RAND Avg)', ...
                 'Passive: Avg REG vs Avg RAND', y_label_text);

    % Plot 3: Active - Out12 REG vs RAND
    figure('Name', 'Stim12 Data');
    ax3 = subplot(2, 1, 1);
    plot_with_ci(ax3, t, act_12_1, 'Out12 Stim 1 (REG)', act_12_2, 'Out12 Stim 2 (RAND)', ...
                 'Active Out12: REG vs RAND', y_label_text);

    % Plot 4: Passive - Out12 REG vs RAND
    ax4 = subplot(2, 1, 2);
    plot_with_ci(ax4, t, pass_12_1, 'Out12 Stim 1 (REG)', pass_12_2, 'Out12 Stim 2 (RAND)', ...
                 'Passive Out12: REG vs RAND', y_label_text);

    % Plot 5: Active - Out34 REG vs RAND
    figure('Name', 'Stim34 Data');
    ax5 = subplot(2, 1, 1);
    plot_with_ci(ax5, t, act_34_1, 'Out34 Stim 1 (REG)', act_34_2, 'Out34 Stim 2 (RAND)', ...
                 'Active Out34: REG vs RAND', y_label_text);

    % Plot 6: Passive - Out34 REG vs RAND
    ax6 = subplot(2, 1, 2);
    plot_with_ci(ax6, t, pass_34_1, 'Out34 Stim 1 (REG)', pass_34_2, 'Out34 Stim 2 (RAND)', ...
                 'Passive Out34: REG vs RAND', y_label_text);

    % Plot 7: Active - Out12 REG vs Out34 REG
    figure('Name', 'REG vs REG');
    ax7 = subplot(2, 1, 1);
    plot_with_ci(ax7, t, act_12_1, 'Out12 Stim 1 (REG)', act_34_1, 'Out34 Stim 1 (REG)', ...
                 'Active: Out12 REG vs Out34 REG', y_label_text);

    % Plot 8: Passive - Out12 REG vs Out34 REG
    ax8 = subplot(2, 1, 2);
    plot_with_ci(ax8, t, pass_12_1, 'Out12 Stim 1 (REG)', pass_34_1, 'Out34 Stim 1 (REG)', ...
                 'Passive: Out12 REG vs Out34 REG', y_label_text);

end

%% --- Helper Function ---
function plot_with_ci(ax, t, data1, name1, data2, name2, plt_title, y_label_text)
    axes(ax); hold on;
    
    m1 = mean(data1, 1, 'omitnan'); s1 = std(data1, 0, 1, 'omitnan'); n1 = sum(~isnan(data1), 1); ci1 = 1.96 * s1 ./ sqrt(n1);
    m2 = mean(data2, 1, 'omitnan'); s2 = std(data2, 0, 1, 'omitnan'); n2 = sum(~isnan(data2), 1); ci2 = 1.96 * s2 ./ sqrt(n2);
    
    fill([t, fliplr(t)], [m1+ci1, fliplr(m1-ci1)], 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(t, m1, 'b', 'LineWidth', 1.5, 'DisplayName', name1);
    
    fill([t, fliplr(t)], [m2+ci2, fliplr(m2-ci2)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(t, m2, 'r', 'LineWidth', 1.5, 'DisplayName', name2);
    
    % Find non-overlapping regions (Significant difference)
    lower1 = m1 - ci1;
    upper1 = m1 + ci1;
    lower2 = m2 - ci2;
    upper2 = m2 + ci2;
    non_overlap = (lower1 > upper2) | (lower2 > upper1);
    
    % Get current y-limits to place the bar at the top
    ylim([0.5 1.7]);
    yl = [0.5 1.7];
    y_range = yl(2) - yl(1);
    ylim([yl(1), yl(2) + 0.1 * y_range]); % Expand upper limit by 10% to make room
    sig_y = yl(2) + 0.05 * y_range;
    
    % Prepare significance line (NaN where they overlap, sig_y where they don't)
    sig_line = NaN(size(t));
    sig_line(non_overlap) = sig_y;
    
    % Plot the significance line
    if any(non_overlap)
        plot(t, sig_line, 'g-', 'LineWidth', 3, 'DisplayName', 'Non-Overlapping CI');
    end
    
    xline(0.5, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(3.6, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    
    title(plt_title, 'FontSize', 11);
    xlabel('Time (s)', 'FontSize', 10);
    ylabel(y_label_text, 'FontSize', 10);
    xlim([0, 6.5]);
    legend('Location', 'best');
    grid on; 
    hold off;
end