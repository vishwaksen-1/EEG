% audio
data_files = {
    'PSD_Spectrogram_Data_set1_act.mat',  'set1', 'act';
    'PSD_Spectrogram_Data_set1_pass.mat', 'set1', 'pass';
    'PSD_Spectrogram_Data_set2_act.mat',  'set2', 'act';
    'PSD_Spectrogram_Data_set2_pass.mat', 'set2', 'pass';
};

s1a = load(data_files{1,1});
s1p = load(data_files{2,1});
s2a = load(data_files{3,1});
s2p = load(data_files{4,1});

stims = {'stim1', 'stim2', 'stim3', 'stim4'};

for s = 1:length(stims)
    stim_name = stims{s};

    fprintf('\n===== Now plotting spectrograms for %s =====\n (press any key)\n', stim_name);
    pause;

    channels = fieldnames(s1a.PSD_Spect_Struct.(stim_name));
    num_channels = length(channels); 

    figure; % Create a new figure for each stim

    for i = 1:num_channels
        ch_name = channels{i};

        % S_min = min(S(:)); % Find the minimum value in the entire spectrogram
        % S_max = max(S(:)); % Find the maximum value in the entire spectrogram
        % 
        % S_normalized_0_1 = (S - S_min) / (S_max - S_min); % Normalize to [0, 1]


        % Extract spectrogram data
        S1a = s1a.PSD_Spect_Struct.(stim_name).(ch_name).spectrogram;
            S1a_min = min(S1a(:));
            S1a_max = max(S1a(:));
            S1a_normalized_0_1 = (S1a - S1a_min) / (S1a_max - S1a_min);

        S2a = s2a.PSD_Spect_Struct.(stim_name).(ch_name).spectrogram;
            S2a_min = min(S2a(:));
            S2a_max = max(S2a(:));
            S2a_normalized_0_1 = (S2a - S2a_min) / (S2a_max - S2a_min);

        S1p = s1p.PSD_Spect_Struct.(stim_name).(ch_name).spectrogram;
            S1p_min = min(S1p(:));
            S1p_max = max(S1p(:));
            S1p_normalized_0_1 = (S1p - S1p_min) / (S1p_max - S1p_min);

        S2p = s2p.PSD_Spect_Struct.(stim_name).(ch_name).spectrogram;
            S2p_min = min(S2p(:));
            S2p_max = max(S2p(:));
            S2p_normalized_0_1 = (S2p - S2p_min) / (S2p_max - S2p_min);

        f = s1a.PSD_Spect_Struct.(stim_name).(ch_name).spectrogram_f;
        t = s1a.PSD_Spect_Struct.(stim_name).(ch_name).spectrogram_t;
        % Plot spectrogram
        subplot(2,2,1)
        imagesc(t, f, abs(S1a_normalized_0_1).^2);
        title("set1 active");
        axis xy;
        xlabel('Time (s)');
        ylabel('Frequency (Hz)');
        clim([0 1]);
        colorbar;
        ylim([0 64]);

        subplot(2,2,2)
        imagesc(t, f, abs(S1p_normalized_0_1).^2);
        title("set1 passive");
        axis xy;
        xlabel('Time (s)');
        ylabel('Frequency (Hz)');
        clim([0 1]);
        colorbar;
        % clim(([min([min(min(abs(S1a).^2)) min(min(abs(S1p).^2))]) max([max(max(abs(S1a).^2)) max(max(abs(S1p).^2))])]*10^4));
        ylim([0 64]);

        subplot(2,2,3)
        imagesc(t, f, abs(S2a_normalized_0_1).^2);
        title("set2 active");
        axis xy;
        xlabel('Time (s)');
        ylabel('Frequency (Hz)');
        clim([0 1]);
        colorbar;
        % clim(([min([min(min(abs(S2a).^2)) min(min(abs(S2p).^2))]) max([max(max(abs(S2a).^2)) max(max(abs(S2p).^2))])]*10^4));
        ylim([0 64]);

        subplot(2,2,4)
        imagesc(t, f, abs(S2p_normalized_0_1).^2);
        title("set2 passive");
        axis xy;
        clim([0 1]);
        colorbar;
        % clim(([min([min(min(abs(S2a).^2)) min(min(abs(S2p).^2))]) max([max(max(abs(S2a).^2)) max(max(abs(S2p).^2))])]*10^4));
        ylim([0 64]);

        sgtitle(sprintf('Spectrograms - %s - Channel: %s', stim_name, ch_name), 'Interpreter', 'none');


        % Wait for key press before next plot
        disp(['Press any key to continue to next channel (' ch_name ')...']);
        pause;
    end
    close; % Close the figure before moving to next stim, comment if you want to keep them open
end

%% 
% video
data_files = {
    'PSD_Spect_Struct_visual.mat';
};

s1a = load(data_files{1});

stims = {'seg1', 'seg2', 'seg3'};

%% Plot spectrograms per channel with subplots for each segment
segments = {'seg1', 'seg2', 'seg3'}; % or use: fieldnames(PSD_Spect_Struct_visual)
num_segments = numel(segments);

channels = fieldnames(PSD_Spect_Struct_visual.(segments{1}));
num_channels = numel(channels);

fprintf('\n===== Plotting spectrograms per channel (each with %d segments) =====\n', num_segments);

for i = 1:num_channels
    ch_name = channels{i};
    figure;
    
    for s = 1:num_segments
        seg_name = segments{s};

        % Extract spectrogram data
        S = PSD_Spect_Struct_visual.(seg_name).(ch_name).spectrogram;
        f = PSD_Spect_Struct_visual.(seg_name).(ch_name).spectrogram_f;
        t = PSD_Spect_Struct_visual.(seg_name).(ch_name).spectrogram_t;

        % Normalize to [0,1] for better comparison
        S_min = min(S(:));
        S_max = max(S(:));
        S_norm = (S - S_min) / (S_max - S_min);

        % --- Subplot for this segment ---
        subplot(1, num_segments, s);
        imagesc(t, f, abs(S_norm).^2);
        axis xy;
        xlabel('Time (s)');
        ylabel('Frequency (Hz)');
        ylim([0 64]);
        clim([0 1]);
        colorbar;
        title(sprintf('%s - %s', seg_name, ch_name), 'Interpreter', 'none');
    end

    sgtitle(sprintf('Spectrograms for %s across segments', ch_name), 'FontWeight', 'bold');
    fprintf('Plotted all segments for channel: %s\n', ch_name);
    
    % Optional: pause to review each channel before proceeding
    disp('Press any key for next channel...');
    pause;
end
