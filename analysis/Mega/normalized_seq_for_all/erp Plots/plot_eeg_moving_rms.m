function plot_eeg_moving_rms(actnorm, passnorm, win_samples, norm_type)
% plot_eeg_moving_rms - Non-overlapping Moving RMS for normalized data
%
% Usage: plot_eeg_moving_rms(actnorm, passnorm, 10, 'zscore')

    if nargin < 3 || isempty(win_samples), win_samples = 10; end
    if nargin < 4 || isempty(norm_type), norm_type = 'zscore'; end

    act_12_1 = extract_eeg_moving_rms(actnorm.Out12, 1, win_samples, norm_type);
    act_12_2 = extract_eeg_moving_rms(actnorm.Out12, 2, win_samples, norm_type);
    act_34_1 = extract_eeg_moving_rms(actnorm.Out34, 1, win_samples, norm_type);
    act_34_2 = extract_eeg_moving_rms(actnorm.Out34, 2, win_samples, norm_type);
    
    pass_12_1 = extract_eeg_moving_rms(passnorm.Out12, 1, win_samples, norm_type);
    pass_12_2 = extract_eeg_moving_rms(passnorm.Out12, 2, win_samples, norm_type);
    pass_34_1 = extract_eeg_moving_rms(passnorm.Out34, 1, win_samples, norm_type);
    pass_34_2 = extract_eeg_moving_rms(passnorm.Out34, 2, win_samples, norm_type);

    act_reg_avg  = (act_12_1 + act_34_1) / 2;
    act_rand_avg = (act_12_2 + act_34_2) / 2;
    pass_reg_avg  = (pass_12_1 + pass_34_1) / 2;
    pass_rand_avg = (pass_12_2 + pass_34_2) / 2;

    numTime = size(act_12_1, 2);
    t = linspace(0, 6.5, numTime);

    figure('Name', 'Norm Moving RMS: Active & Passive Avg');
    plot_with_ci(subplot(2, 1, 1), t, act_reg_avg, 'Stim 1 (REG Avg)', act_rand_avg, 'Stim 2 (RAND Avg)', 'Active: Avg REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_reg_avg, 'Stim 1 (REG Avg)', pass_rand_avg, 'Stim 2 (RAND Avg)', 'Passive: Avg REG vs RAND');

    figure('Name', 'Norm Moving RMS: Stim12');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, 'Stim12 Stim 1', act_12_2, 'Stim12 Stim 2', 'Active Stim12: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, 'Stim12 Stim 1', pass_12_2, 'Stim12 Stim 2', 'Passive Stim12: REG vs RAND');

    figure('Name', 'Norm Moving RMS: Stim34');
    plot_with_ci(subplot(2, 1, 1), t, act_34_1, 'Stim34 Stim 1', act_34_2, 'Stim34 Stim 2', 'Active Stim34: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_34_1, 'Stim34 Stim 1', pass_34_2, 'Stim34 Stim 2', 'Passive Stim34: REG vs RAND');

    figure('Name', 'Norm Moving RMS: REG vs REG');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, 'Stim12 REG', act_34_1, 'Stim34 REG', 'Active: Stim12 REG vs Stim34 REG');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, 'Stim12 REG', pass_34_1, 'Stim34 REG', 'Passive: Stim12 REG vs Stim34 REG');
end

%% --- Helper: Data Extraction ---
function out_data = extract_eeg_moving_rms(normOut, stim_idx, win, norm_type)
    field_name = sprintf('stim%d_%s', stim_idx, norm_type);
    data = normOut.(field_name); % [subj x ch x time]
    ft = permute(data, [3, 2, 1]); % [time x ch x subj]

    [T, num_ch, num_subj] = size(ft);
    num_win = floor(T / win);
    
    % Truncate and reshape to window boundaries
    ft_trunc = reshape(ft(1:num_win*win, :, :), [win, num_win, num_ch, num_subj]);
    
    % 1. Moving RMS over time (dim 1) per channel
    rms_ft = rms(ft_trunc, 1, 'omitnan'); % [1 x num_win x ch x subj]
    
    % 2. THEN average across channels (dim 3)
    rms_ch_avg = mean(rms_ft, 3, 'omitnan'); % [1 x num_win x 1 x subj]
    
    out_data = reshape(rms_ch_avg, [num_win, num_subj]).'; % [subj x num_win]
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
    title(plt_title, 'FontSize', 11); xlabel('Time (s)', 'FontSize', 10); ylabel('Norm Moving RMS', 'FontSize', 10);
    xlim([0, 6.5]); legend('Location', 'best'); grid on; hold off;
end