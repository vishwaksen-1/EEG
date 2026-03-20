function plot_eeg_baseline_subtracted(actnorm, passnorm, norm_type, base_samples)
% plot_eeg_baseline_subtracted - Plots Abs(Normalized Signal - Baseline Mean)
%
% Usage: plot_eeg_baseline_subtracted(actnorm, passnorm, 'zscore', 128)

    if nargin < 3 || isempty(norm_type), norm_type = 'zscore'; end
    if nargin < 4 || isempty(base_samples), base_samples = 128; end % default 500ms at 256Hz

    act_12_1 = extract_eeg_sub_baseline(actnorm.Out12, 1, norm_type, base_samples);
    act_12_2 = extract_eeg_sub_baseline(actnorm.Out12, 2, norm_type, base_samples);
    act_34_1 = extract_eeg_sub_baseline(actnorm.Out34, 1, norm_type, base_samples);
    act_34_2 = extract_eeg_sub_baseline(actnorm.Out34, 2, norm_type, base_samples);
    
    pass_12_1 = extract_eeg_sub_baseline(passnorm.Out12, 1, norm_type, base_samples);
    pass_12_2 = extract_eeg_sub_baseline(passnorm.Out12, 2, norm_type, base_samples);
    pass_34_1 = extract_eeg_sub_baseline(passnorm.Out34, 1, norm_type, base_samples);
    pass_34_2 = extract_eeg_sub_baseline(passnorm.Out34, 2, norm_type, base_samples);

    act_reg_avg  = (act_12_1 + act_34_1) / 2;
    act_rand_avg = (act_12_2 + act_34_2) / 2;
    pass_reg_avg  = (pass_12_1 + pass_34_1) / 2;
    pass_rand_avg = (pass_12_2 + pass_34_2) / 2;

    numTime = size(act_12_1, 2);
    t = linspace(0, 6.5, numTime);

    figure('Name', 'Norm Base Subtracted: Active & Passive Avg');
    plot_with_ci(subplot(2, 1, 1), t, act_reg_avg, 'Stim 1 (REG Avg)', act_rand_avg, 'Stim 2 (RAND Avg)', 'Active: Avg REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_reg_avg, 'Stim 1 (REG Avg)', pass_rand_avg, 'Stim 2 (RAND Avg)', 'Passive: Avg REG vs RAND');

    figure('Name', 'Norm Base Subtracted: Stim12');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, 'Stim12 Stim 1', act_12_2, 'Stim12 Stim 2', 'Active Stim12: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, 'Stim12 Stim 1', pass_12_2, 'Stim12 Stim 2', 'Passive Stim12: REG vs RAND');

    figure('Name', 'Norm Base Subtracted: Stim34');
    plot_with_ci(subplot(2, 1, 1), t, act_34_1, 'Stim34 Stim 1', act_34_2, 'Stim34 Stim 2', 'Active Stim34: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_34_1, 'Stim34 Stim 1', pass_34_2, 'Stim34 Stim 2', 'Passive Stim34: REG vs RAND');

    figure('Name', 'Norm Base Subtracted: REG vs REG');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, 'Stim12 REG', act_34_1, 'Stim34 REG', 'Active: Stim12 REG vs Stim34 REG');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, 'Stim12 REG', pass_34_1, 'Stim34 REG', 'Passive: Stim12 REG vs Stim34 REG');
end

%% --- Helper: Data Extraction ---
function out_data = extract_eeg_sub_baseline(normOut, stim_idx, norm_type, base_samples)
    field_name = sprintf('stim%d_%s', stim_idx, norm_type);
    data = normOut.(field_name); % [subj x ch x time]
    
    % Permute to [time x ch x subj] for easier processing
    ft = permute(data, [3, 2, 1]); 
    
    % Baseline mean over time (dim 1)
    bl = ft(1:base_samples, :, :);
    bl_mean = mean(bl, 1, 'omitnan'); % [1 x ch x subj]
    
    % Subtract baseline per channel
    ft_sub = ft - bl_mean;
    
    % 1. Take Absolute Magnitude (Continuous version of RMS for 1 sample) per channel
    ft_abs = abs(ft_sub);
    
    % 2. THEN average across channels (dim 2)
    data_ch_avg = mean(ft_abs, 2, 'omitnan'); % [time x 1 x subj]
    
    numTime = size(data_ch_avg, 1);
    numSubj = size(data_ch_avg, 3);
    out_data = reshape(data_ch_avg, [numTime, numSubj]).'; % [subj x time]
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
    
    lower1 = m1 - ci1; upper1 = m1 + ci1;
    lower2 = m2 - ci2; upper2 = m2 + ci2;
    non_overlap = (lower1 > upper2) | (lower2 > upper1);
    
    yl = ylim(); y_range = yl(2) - yl(1);
    ylim([yl(1), yl(2) + 0.1 * y_range]);
    sig_y = yl(2) + 0.05 * y_range;
    
    sig_line = NaN(size(t)); sig_line(non_overlap) = sig_y;
    if any(non_overlap), plot(t, sig_line, 'g-', 'LineWidth', 3, 'DisplayName', 'Non-Overlapping CI'); end
    
    xline(0.5, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off'); xline(3.6, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    title(plt_title, 'FontSize', 11); xlabel('Time (s)', 'FontSize', 10); ylabel('Norm Amplitude (Base Sub)', 'FontSize', 10);
    xlim([0, 6.5]); legend('Location', 'best'); grid on; hold off;
end