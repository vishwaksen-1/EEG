%% audio
% % Get all channel field names
% channels = fieldnames(PSD_Spect_Struct.stim1);
% 
% % Create figure
% figure;
% hold on;
% grid on;
% 
% % Loop through each channel and plot
% for i = 1:length(channels)
%     ch_name = channels{i};
%     % Extract PSD and frequency for the current channel
%     freq = PSD_Spect_Struct.stim1.(ch_name).psd_f;
%     pxx = PSD_Spect_Struct.stim1.(ch_name).psd;
% 
%     % Plot
%     plot(freq, 10*log10(pxx), 'DisplayName', ch_name); % Use DisplayName for legend
% end
% 
% % Add labels and title
% xlabel('Frequency (Hz)');
% ylabel('Power/Frequency (dB/Hz)');
% title('Power Spectral Density for All Channels - set2 pass stim1');
% legend show; % Show legend with channel names
% hold off;

channels = ["AF3", 'F7', 'F3', 'FC5', 'T7', 'P7', 'O1', 'O2', 'P6', 'T8', 'FC6', 'F4', 'F8', 'AF4']';

%% visual -- segmentwise
load("/MATLAB Drive/EEG/Utils/analysis/Mega/visual/segmentedX.mat"); % load file
meanSegX = squeeze(mean(segmentedX,[1,2])); % 14x3x512
fs = 128; % replace with your actual sampling freq

for j = 1:size(meanSegX, 2) % loop over segments (3)
    fprintf("Plotting for segment number %d\n(press any key)\n", j);
    
    figure; % Create new figure for this segment
    hold on;
    grid on;
    
    for i = 1:length(channels) % loop over channels (14)
        ch_name = channels(i);
        
        % Extract data for channel i, segment j
        data = squeeze(meanSegX(i,j,:));
        window = 128;
        % Compute PSD
        [pxx, freq] = pwelch(data, window, window/2, 256, fs);
        
        % Plot PSD in dB
        plot(freq, 10*log10(pxx), 'DisplayName', ch_name);
    end
    % Set labels, title, legend after plotting
    xlabel('Frequency (Hz)');
    ylabel('Power/Frequency (dB/Hz)');
    title(sprintf('Power Spectral Density for All Channels - segment %d', j));
    legend('show');
    hold off;
    
    pause; % Wait for user before moving on to next segment
end

%% visual - segmentwise channelwise
for i = 1:length(channels) % loop over channels (14)
    fprintf("Plotting for channel number %d\n(press any key)\n", j);
    
    figure; % Create new figure for this segment
    hold on;
    grid on;
    
    for j = 1:size(meanSegX, 2) % loop over segments (3)
        ch_name = channels(i);
        
        % Extract data for channel i, segment j
        data = squeeze(meanSegX(i,j,:));
        
        window = 128;
        % Compute PSD
        [pxx, freq] = pwelch(data, window, window/2, 256, fs);
        
        % Plot PSD in dB
        plot(freq, 10*log10(pxx), 'DisplayName', sprintf("segment %d", j));
    end
    
    % Set labels, title, legend after plotting
    xlabel('Frequency (Hz)');
    ylabel('Power/Frequency (dB/Hz)');
    title(sprintf('Power Spectral Density for All segments - channel %s', channels(i)));
    legend('show');
    hold off;
    
    pause; % Wait for user before moving on to next segment
end