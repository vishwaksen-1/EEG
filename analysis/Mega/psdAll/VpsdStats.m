clear
clc
%% Setup
data_files = {
    'PSD_Spect_Struct_visual.mat';
};
segs = {'seg1', 'seg2', 'seg3'};
channels = {'ch_AF3','ch_F7','ch_F3','ch_FC5','ch_T7','ch_P7','ch_O1',...
            'ch_O2','ch_P6','ch_T8','ch_FC6','ch_F4','ch_F8','ch_AF4'};

% Initialize data container
PSD_Data = struct();

%% Load all data into PSD_Data.(set).(cond).(seg).(channel)
for i = 1:size(data_files,1)
    filename = data_files{i,1};
    
    fprintf("Loading %s...\n", filename);
    temp = load(filename); % loads PSD_Spect_Struct
    
    for s = 1:length(segs)
        seg = segs{s};
        for c = 1:length(channels)
            ch = channels{c};
            % Save PSD and frequency
            PSD_Data.(seg).(ch).psd = ...
                temp.PSD_Spect_Struct_visual.(seg).(ch).psd;
            PSD_Data.(seg).(ch).freq = ...
                temp.PSD_Spect_Struct_visual.(seg).(ch).psd_f;
        end
    end
end

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
    file = data_files{i};
    
    fprintf('Loading %s...\n', file);
    temp = load(file); % loads PSD_Spect_Struct

    for s = 1:length(segs)
        seg = segs{s};
        
        for c = 1:length(channels)
            ch = channels{c};
            
            % Get PSD and frequency
            psd = temp.PSD_Spect_Struct_visual.(seg).(ch).psd;
            freq = temp.PSD_Spect_Struct_visual.(seg).(ch).psd_f;

            % Compute band powers
            for b = 1:size(bands,1)
                band_name = bands{b,1};
                band_range = bands{b,2};
                
                % Find frequency indices within band
                band_idx = freq >= band_range(1) & freq <= band_range(2);
                
                % Integrate power in band (area under curve)
                band_power = trapz(freq(band_idx), psd(band_idx));  % Linear scale

                % Store
                BandPower.(seg).(band_name).(ch) = band_power;
            end
        end
    end
end

% (Optional) Save band power data
save('BandPower_video.mat', 'BandPower');

%% Plot alpha band power: seg comparisons (seg1-seg2, seg2-seg3, seg3-seg1)
band_list = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
segs = {'seg1', 'seg2', 'seg3'};
pairs = {'seg1', 'seg2'; 'seg3', 'seg2'; 'seg3', 'seg1'};
colors = {'r', 'b'; 'g', 'b'; 'g', 'r'};

for j = 1:length(band_list)
    band = band_list{j};
    figure;
    
    for p = 1:size(pairs,1)
        segA = pairs{p,1};
        segB = pairs{p,2};
        colA = colors{p,1};
        colB = colors{p,2};
        
        powerA = zeros(1, length(channels));
        powerB = zeros(1, length(channels));
        
        for c = 1:length(channels)
            ch = channels{c};
            powerA(c) = BandPower.(segA).(band).(ch);
            powerB(c) = BandPower.(segB).(band).(ch);
        end
        
        subplot(1, 4, p); % 3 subplots in a row
        hold on;
        plot(powerA, '-o', 'DisplayName', segA, 'Color', colA);
        plot(powerB, '-o', 'DisplayName', segB, 'Color', colB);
        hold off;
        
        xticks(1:length(channels));
        xticklabels(channels);
        xtickangle(45);
        ylabel(sprintf('%s Band Power', band));
        title(sprintf('%s vs %s', segA, segB));
        grid on;
        legend('Location', 'best');
    end
    powerA = zeros(1, length(channels));
    powerB = zeros(1, length(channels));
    for c = 1:length(channels)
            ch = channels{c};
            powerA(c) = BandPower.seg1.(band).(ch);
            powerB(c) = BandPower.seg2.(band).(ch);
            powerC(c) = BandPower.seg3.(band).(ch);
    end
    subplot(1, 4, 4); % 3 subplots in a row
    hold on;
    plot(powerA, '-o', 'DisplayName', 'seg1', 'Color', 'r');
    plot(powerB, '-o', 'DisplayName', 'seg2', 'Color', 'b');
    plot(powerC, '-o', 'DisplayName', 'seg3', 'Color', 'g');
    hold off;
    xticks(1:length(channels));
    xticklabels(channels);
    xtickangle(45);
    ylabel(sprintf('%s Band Power', band));
    title(sprintf('seg1 vs seg2 vs seg3'));
    grid on;
    legend('Location', 'best');

    sgtitle(sprintf('%s Band Power', band));
end

