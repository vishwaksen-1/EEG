%% 13/10/25- psd for whoel stim , each stim seperately. r
%pre requisite- run eeg_finaldestination with final_set1/set2_act/pass accordingly

clear;
clc;
f_name = 'final_set2_pass.mat';
load(f_name);
eeg_final_destination();

channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2','P6','T8','FC6','F4','F8','AF4'};
% For first stimulus in final_set1_act
xx1 = squeeze(mean(stim12.whole_stim(:,:,1,:,:), [4 5]));

% For second stimulus in final_set1_act
xx2 = squeeze(mean(stim12.whole_stim(:,:,2,:,:), [4 5]));

% For first stimulus in final_set1_pass
yy1 = squeeze(mean(stim34.whole_stim(:,:,1,:,:), [4 5]));

% For second stimulus in final_set1_pass
yy2 = squeeze(mean(stim34.whole_stim(:,:,2,:,:), [4 5]));

fs = 256; % Replace with your EEG sampling frequency (in Hz)
nChannels = length(channels);
window = 256; % Window length for PSD and spectrogram
    noverlap = 128; % Overlap for spectrogram
nfft = 512; % FFT length for spectrogram

all_data = {xx1, xx2, yy1, yy2};
labels = {'stim1', 'stim2', 'stim3', 'stim4'};
PSD_Spect_Struct = struct();

for dIdx = 1:numel(all_data)
    dat = all_data{dIdx}; % [time x channels]
    label = labels{dIdx};
    for ch = 1:nChannels
        % PSD (Welch)
        [pxx, f_pxx] = pwelch(dat(:,ch), window, window/2, nfft, fs);
        % Spectrogram
        [S, f_S, t_S] = spectrogram(dat(:,ch), window, noverlap, nfft, fs);

       % f_S gives the frequency for each row (in Hz).

% t_S gives the time (in seconds) for each column (center of each window).

        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).psd = pxx;
        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).psd_f = f_pxx;
        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).spectrogram = S;
        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).spectrogram_f = f_S;
        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).spectrogram_t = t_S;
    end
end
save('PSD_Spectrogram_Data.mat', 'PSD_Spect_Struct', '-v7.3');
