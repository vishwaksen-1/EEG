clear
clc
%% Setup
data_files = {
    'PSD_Spectrogram_Data_set1_act.mat',  'set1', 'act';
    'PSD_Spectrogram_Data_set1_pass.mat', 'set1', 'pass';
    'PSD_Spectrogram_Data_set2_act.mat',  'set2', 'act';
    'PSD_Spectrogram_Data_set2_pass.mat', 'set2', 'pass';
};

sets = {'set1', 'set2'};
conds = {'act', 'pass'};
stims = {'stim1', 'stim2', 'stim3', 'stim4'};
channels = {'ch_AF3','ch_F7','ch_F3','ch_FC5','ch_T7','ch_P7','ch_O1',...
            'ch_O2','ch_P6','ch_T8','ch_FC6','ch_F4','ch_F8','ch_AF4'};

% Initialize data container
PSD_Data = struct();

%% Load all data into PSD_Data.(set).(cond).(stim).(channel)
for i = 1:size(data_files,1)
    filename = data_files{i,1};
    set_name = data_files{i,2};
    cond_name = data_files{i,3};
    
    fprintf("Loading %s...\n", filename);
    temp = load(filename); % loads PSD_Spect_Struct
    
    for s = 1:length(stims)
        stim = stims{s};
        for c = 1:length(channels)
            ch = channels{c};
            % Save PSD and frequency
            PSD_Data.(set_name).(cond_name).(stim).(ch).psd = ...
                temp.PSD_Spect_Struct.(stim).(ch).psd;
            PSD_Data.(set_name).(cond_name).(stim).(ch).freq = ...
                temp.PSD_Spect_Struct.(stim).(ch).psd_f;
        end
    end
end

%% Active vs Passive PSD Comparison (example: set1, stim1)

stim = 'stim1';
set = 'set1';

for c = 1:length(channels)
    ch = channels{c};
    
    % Get PSDs and frequencies
    psd_act = PSD_Data.(set).act.(stim).(ch).psd;
    psd_pass = PSD_Data.(set).pass.(stim).(ch).psd;
    freq = PSD_Data.(set).act.(stim).(ch).freq;
    
    % Optional: smooth PSD
    % psd_act = smooth(psd_act, 5);
    % psd_pass = smooth(psd_pass, 5);
    
    % Plot
    % subplot(4, 4, c);
    figure;
    plot(freq, psd_act, 'b', 'DisplayName', 'Active');
    hold on;
    plot(freq, psd_pass, 'r', 'DisplayName', 'Passive');
    title(ch, 'Interpreter', 'none');
    xlabel('Hz'); ylabel('Power (dB/Hz)');
    legend;
    grid on;
    pause;
end
sgtitle(sprintf('PSD Comparison - %s - %s', set, stim));

close all;
clear
clc

%% Load all 4 data structs
data_files = {
    'PSD_Spectrogram_Data_set1_act.mat',  'set1', 'act';
    'PSD_Spectrogram_Data_set1_pass.mat', 'set1', 'pass';
    'PSD_Spectrogram_Data_set2_act.mat',  'set2', 'act';
    'PSD_Spectrogram_Data_set2_pass.mat', 'set2', 'pass';
};

sets = {'set1', 'set2'};
conds = {'act', 'pass'};
stims = {'stim1', 'stim2', 'stim3', 'stim4'};
channels = {'ch_AF3','ch_F7','ch_F3','ch_FC5','ch_T7','ch_P7','ch_O1',...
            'ch_O2','ch_P6','ch_T8','ch_FC6','ch_F4','ch_F8','ch_AF4'};

% Define frequency bands
bands = {
    'delta', [0.1 4];
    'theta', [4 8];
    'alpha', [8 13];
    'beta',  [13 30];
    'gamma', [30 45];
};

% Container for band powers
BandPower = struct();

%% Process each dataset
for i = 1:size(data_files,1)
    file = data_files{i,1};
    set_name = data_files{i,2};
    cond_name = data_files{i,3};
    
    fprintf('Loading %s...\n', file);
    temp = load(file); % loads PSD_Spect_Struct

    for s = 1:length(stims)
        stim = stims{s};
        
        for c = 1:length(channels)
            ch = channels{c};
            
            % Get PSD and frequency
            psd = temp.PSD_Spect_Struct.(stim).(ch).psd;
            freq = temp.PSD_Spect_Struct.(stim).(ch).psd_f;

            % Compute band powers
            for b = 1:size(bands,1)
                band_name = bands{b,1};
                band_range = bands{b,2};
                
                % Find frequency indices within band
                band_idx = freq >= band_range(1) & freq <= band_range(2);
                
                % Integrate power in band (area under curve)
                band_power = trapz(freq(band_idx), psd(band_idx));  % Linear scale

                % Store
                BandPower.(set_name).(cond_name).(stim).(band_name).(ch) = band_power;
            end
        end
    end
end

% (Optional) Save band power data
save('BandPower_audio.mat', 'BandPower');

%% Plot alpha band power: act vs pass for stim1-4 (set1)
set = 'set1';
band_list = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
stim_list = {'stim1', 'stim2', 'stim3', 'stim4'};
for j = 1:length(band_list)
    figure;
    band = band_list{j};
    for i = 1:length(stim_list)
        stim = stim_list{i};
    
        alpha_act = zeros(1, length(channels));
        alpha_pass = zeros(1, length(channels));
    
        for c = 1:length(channels)
            ch = channels{c};
            alpha_pass(c) = BandPower.(set).pass.(stim).(band).(ch);
            alpha_act(c)  = BandPower.(set).act.(stim).(band).(ch);
        end
    
        subplot(2, 2, i); % 2x2 grid, i-th subplot
        plot(alpha_act);
        hold on;
        plot(alpha_pass);
        xticks(1:length(channels));
        xticklabels(channels);
        xtickangle(45);
        ylabel(sprintf('%s Band Power', band));
        legend('Active', 'Passive');
        title(sprintf('%s Band Power - %s - %s', band, set, stim));
        grid on;
    end
end
