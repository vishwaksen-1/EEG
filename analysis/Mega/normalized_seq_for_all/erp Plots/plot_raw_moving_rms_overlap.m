function plot_raw_moving_rms_overlap(activeStim12, activeStim34, passiveStim12, passiveStim34, win_samples, overlap_samples, subtract_baseline)
% 4. Moving RMS with sliding window OVERLAP
    if nargin < 5, win_samples = 10; end
    if nargin < 6, overlap_samples = 5; end % Default 50% overlap
    if nargin < 7, subtract_baseline = true; end % Default behavior is like task 3

    act_12_1 = extract_rms_overlap(activeStim12, 1, win_samples, overlap_samples, subtract_baseline);
    act_12_2 = extract_rms_overlap(activeStim12, 2, win_samples, overlap_samples, subtract_baseline);
    act_34_1 = extract_rms_overlap(activeStim34, 1, win_samples, overlap_samples, subtract_baseline);
    act_34_2 = extract_rms_overlap(activeStim34, 2, win_samples, overlap_samples, subtract_baseline);
    
    pass_12_1 = extract_rms_overlap(passiveStim12, 1, win_samples, overlap_samples, subtract_baseline);
    pass_12_2 = extract_rms_overlap(passiveStim12, 2, win_samples, overlap_samples, subtract_baseline);
    pass_34_1 = extract_rms_overlap(passiveStim34, 1, win_samples, overlap_samples, subtract_baseline);
    pass_34_2 = extract_rms_overlap(passiveStim34, 2, win_samples, overlap_samples, subtract_baseline);

    act_reg_avg  = (act_12_1 + act_34_1) / 2;
    act_rand_avg = (act_12_2 + act_34_2) / 2;
    pass_reg_avg  = (pass_12_1 + pass_34_1) / 2;
    pass_rand_avg = (pass_12_2 + pass_34_2) / 2;

    numTime = size(act_12_1, 2);
    t = linspace(0, 6.5, numTime);

    figure('Name', 'RMS Overlap: Active & Passive Avg');
    plot_with_ci(subplot(2, 1, 1), t, act_reg_avg, 'Stim 1 (REG Avg)', act_rand_avg, 'Stim 2 (RAND Avg)', 'Active: Avg REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_reg_avg, 'Stim 1 (REG Avg)', pass_rand_avg, 'Stim 2 (RAND Avg)', 'Passive: Avg REG vs RAND');

    figure('Name', 'RMS Overlap: Stim12');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, 'Stim12 Stim 1', act_12_2, 'Stim12 Stim 2', 'Active Stim12: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, 'Stim12 Stim 1', pass_12_2, 'Stim12 Stim 2', 'Passive Stim12: REG vs RAND');

    figure('Name', 'RMS Overlap: Stim34');
    plot_with_ci(subplot(2, 1, 1), t, act_34_1, 'Stim34 Stim 1', act_34_2, 'Stim34 Stim 2', 'Active Stim34: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_34_1, 'Stim34 Stim 1', pass_34_2, 'Stim34 Stim 2', 'Passive Stim34: REG vs RAND');

    figure('Name', 'RMS Overlap: REG vs REG');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, 'Stim12 REG', act_34_1, 'Stim34 REG', 'Active: Stim12 REG vs Stim34 REG');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, 'Stim12 REG', pass_34_1, 'Stim34 REG', 'Passive: Stim12 REG vs Stim34 REG');
end

%% --- Helper: Data Extraction ---
function out_data = extract_rms_overlap(raw_struct, stim_idx, win, ovlp, sub_bl)
    ft = squeeze(mean(mean(raw_struct.full_trial(:, :, stim_idx, :, :), 4, 'omitnan'), 2, 'omitnan'));
    
    [T, num_subj] = size(ft);
    step = win - ovlp;
    starts = 1:step:(T - win + 1);
    num_win = length(starts);
    
    rms_ft = zeros(num_win, num_subj);
    for i = 1:num_win
        idx = starts(i):(starts(i) + win - 1);
        rms_ft(i, :) = rms(ft(idx, :), 1, 'omitnan');
    end
    
    if sub_bl
        bl = squeeze(mean(mean(raw_struct.baseline(:, :, stim_idx, :, :), 4, 'omitnan'), 2, 'omitnan'));
        starts_bl = 1:step:(size(bl, 1) - win + 1);
        rms_bl = zeros(length(starts_bl), num_subj);
        for i = 1:length(starts_bl)
            idx = starts_bl(i):(starts_bl(i) + win - 1);
            rms_bl(i, :) = rms(bl(idx, :), 1, 'omitnan');
        end
        bl_rms_mean = mean(rms_bl, 1, 'omitnan');
        rms_ft = rms_ft - bl_rms_mean; % Subtract mean RMS of baseline
    end
    
    out_data = rms_ft.'; % [subj x num_win]
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
    xline(0.5, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(3.6, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    title(plt_title, 'FontSize', 11); xlabel('Time (s)', 'FontSize', 10); ylabel('RMS', 'FontSize', 10);
    xlim([0, 6.5]); legend('Location', 'best'); grid on; hold off;
end