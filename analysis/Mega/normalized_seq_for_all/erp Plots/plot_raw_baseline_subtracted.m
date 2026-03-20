function plot_raw_baseline_subtracted(activeStim12, activeStim34, passiveStim12, passiveStim34)
% Generates plots for: RMS(full_trial) - mean(RMS(baseline)) across channels

    act_12_1 = extract_and_sub_baseline(activeStim12, 1);
    act_12_2 = extract_and_sub_baseline(activeStim12, 2);
    act_34_1 = extract_and_sub_baseline(activeStim34, 1);
    act_34_2 = extract_and_sub_baseline(activeStim34, 2);
    
    pass_12_1 = extract_and_sub_baseline(passiveStim12, 1);
    pass_12_2 = extract_and_sub_baseline(passiveStim12, 2);
    pass_34_1 = extract_and_sub_baseline(passiveStim34, 1);
    pass_34_2 = extract_and_sub_baseline(passiveStim34, 2);

    act_reg_avg  = (act_12_1 + act_34_1) / 2;
    act_rand_avg = (act_12_2 + act_34_2) / 2;
    pass_reg_avg  = (pass_12_1 + pass_34_1) / 2;
    pass_rand_avg = (pass_12_2 + pass_34_2) / 2;

    numTime = size(act_12_1, 2);
    t = linspace(0, 6.5, numTime);

    figure('Name', 'Base Subtracted: Active & Passive Avg');
    plot_with_ci(subplot(2, 1, 1), t, act_reg_avg, 'Stim 1 (REG Avg)', act_rand_avg, 'Stim 2 (RAND Avg)', 'Active: Avg REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_reg_avg, 'Stim 1 (REG Avg)', pass_rand_avg, 'Stim 2 (RAND Avg)', 'Passive: Avg REG vs RAND');

    figure('Name', 'Base Subtracted: Stim12');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, 'Stim12 Stim 1', act_12_2, 'Stim12 Stim 2', 'Active Stim12: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, 'Stim12 Stim 1', pass_12_2, 'Stim12 Stim 2', 'Passive Stim12: REG vs RAND');

    figure('Name', 'Base Subtracted: Stim34');
    plot_with_ci(subplot(2, 1, 1), t, act_34_1, 'Stim34 Stim 1', act_34_2, 'Stim34 Stim 2', 'Active Stim34: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_34_1, 'Stim34 Stim 1', pass_34_2, 'Stim34 Stim 2', 'Passive Stim34: REG vs RAND');

    figure('Name', 'Base Subtracted: REG vs REG');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, 'Stim12 REG', act_34_1, 'Stim34 REG', 'Active: Stim12 REG vs Stim34 REG');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, 'Stim12 REG', pass_34_1, 'Stim34 REG', 'Passive: Stim12 REG vs Stim34 REG');
end

%% --- Helper: Data Extraction ---
function out_data = extract_and_sub_baseline(raw_struct, stim_idx)
    ft = raw_struct.full_trial(:, :, stim_idx, :, :);
    bl = raw_struct.baseline(:, :, stim_idx, :, :);
    
    % 1. RMS across trials per channel
    ft_rms = rms(ft, 4, 'omitnan');
    bl_rms = rms(bl, 4, 'omitnan');
    
    % Mean of baseline over time (dim 1)
    bl_mean = mean(bl_rms, 1, 'omitnan');
    
    % Subtract baseline per channel
    data_sub = ft_rms - bl_mean;
    
    % 2. THEN average across channels (dim 2)
    data_ch_avg = mean(data_sub, 2, 'omitnan');
    
    numTime = size(data_ch_avg, 1);
    numSubj = size(data_ch_avg, 5);
    out_data = reshape(data_ch_avg, [numTime, numSubj]).';
end

%% --- Helper: Plotting ---
function plot_with_ci(ax, t, data1, name1, data2, name2, plt_title)
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
    yl = ylim();
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
    title(plt_title, 'FontSize', 11); xlabel('Time (s)', 'FontSize', 10); ylabel('Amplitude (RMS Diff)', 'FontSize', 10);
    xlim([0, 6.5]); legend('Location', 'best'); grid on; hold off;
end