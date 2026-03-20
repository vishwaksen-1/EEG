function plot_raw_eeg_results(activeStim12, activeStim34, passiveStim12, passiveStim34)
% plot_raw_eeg_results - Plots RMS across trials, then averaged across channels
    
    act_12_1 = extract_and_average(activeStim12, 1);
    act_12_2 = extract_and_average(activeStim12, 2);
    act_34_1 = extract_and_average(activeStim34, 1);
    act_34_2 = extract_and_average(activeStim34, 2);
    
    pass_12_1 = extract_and_average(passiveStim12, 1);
    pass_12_2 = extract_and_average(passiveStim12, 2);
    pass_34_1 = extract_and_average(passiveStim34, 1);
    pass_34_2 = extract_and_average(passiveStim34, 2);

    act_reg_avg  = (act_12_1 + act_34_1) / 2;
    act_rand_avg = (act_12_2 + act_34_2) / 2;
    pass_reg_avg  = (pass_12_1 + pass_34_1) / 2;
    pass_rand_avg = (pass_12_2 + pass_34_2) / 2;

    numTime = size(act_12_1, 2);
    t = linspace(0, 6.5, numTime);

    figure('Name', 'Raw RMS Data: Active & Passive Avg');
    plot_with_ci(subplot(2, 1, 1), t, act_reg_avg, 'Periodic (REG Avg)', act_rand_avg, 'Aperiodic (RAND Avg)', 'Active: Avg REG vs Avg RAND (Raw RMS)');
    plot_with_ci(subplot(2, 1, 2), t, pass_reg_avg, 'Periodic (REG Avg)', pass_rand_avg, 'Aperiodic (RAND Avg)', 'Passive: Avg REG vs Avg RAND (Raw RMS)');

    figure('Name', 'Raw RMS Data: 120 ITI');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, '120 ITI Periodic', act_12_2, '120 ITI Aperiodic', 'Active 120 ITI: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, '120 ITI Periodic', pass_12_2, '120 ITI Aperiodic', 'Passive 120 ITI: REG vs RAND');

    figure('Name', 'Raw RMS Data: 270 ITI');
    plot_with_ci(subplot(2, 1, 1), t, act_34_1, '270 ITI Periodic', act_34_2, '270 ITI Aperiodic', 'Active 270 ITI: REG vs RAND');
    plot_with_ci(subplot(2, 1, 2), t, pass_34_1, '270 ITI Periodic', pass_34_2, '270 ITI Aperiodic', 'Passive 270 ITI: REG vs RAND');

    figure('Name', 'Raw RMS Data: REG vs REG');
    plot_with_ci(subplot(2, 1, 1), t, act_12_1, '120 ITI REG', act_34_1, '270 ITI REG', 'Active: 120 ITI REG vs 270 ITI REG');
    plot_with_ci(subplot(2, 1, 2), t, pass_12_1, '120 ITI REG', pass_34_1, '270 ITI REG', 'Passive: 120 ITI REG vs 270 ITI REG');
end

%% --- Helper: Data Extraction ---
function out_data = extract_and_average(raw_struct, stim_idx)
    data_stim = raw_struct.full_trial(:, :, stim_idx, :, :);
    
    % 1. Take RMS across trials (prevents cancellation)
    data_trial_rms = rms(data_stim, 4, 'omitnan');
    
    % 2. THEN average across channels
    data_ch_avg = mean(data_trial_rms, 2, 'omitnan');
    
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
    xline(0.5, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    xline(3.6, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
    title(plt_title, 'FontSize', 11); xlabel('Time (s)', 'FontSize', 10); ylabel('Amplitude (RMS)', 'FontSize', 10);
    xlim([0, 6.5]); legend('Location', 'best'); grid on; hold off;
end