
load('passnorm.mat')
all_data={passnorm.Out12.stim1_raw_mean';passnorm.Out12.stim2_raw_mean' ;passnorm.Out34.stim1_raw_mean';passnorm.Out34.stim2_raw_mean'};


channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2','P6','T8','FC6','F4','F8','AF4'};
fs = 256; % EEG sampling frequency (Hz)
nChannels = length(channels);
window = 64; % Window length for PSD and spectrogram
noverlap = window/2; % Overlap for spectrogram
nfft = window*2; % FFT length for spectrogram

% all_data = {squeeze(mean(stim12.whole_stim(:,:,1,:,:), [4 5])), ...
%             squeeze(mean(stim12.whole_stim(:,:,2,:,:), [4 5])), ...
%             squeeze(mean(stim34.whole_stim(:,:,1,:,:), [4 5])), ...
%             squeeze(mean(stim34.whole_stim(:,:,2,:,:), [4 5]))};

%% for raw data mean 


labels = {'stim1', 'stim2', 'stim3', 'stim4'};


% Define EEG frequency bands (Hz)
freqBands = struct( ...
    'delta', [0.1 4], ...
    'theta', [4 8], ...
    'alpha', [8 12], ...
    'beta', [12 30], ...
    'gamma', [30 50]);
bandNames = fieldnames(freqBands);
nBands = length(bandNames);

PSD_Spect_Struct = struct();

for dIdx = 1:numel(all_data)
    dat = all_data{dIdx}; % [time x channels]
    label = labels{dIdx};
    
    % Initialize matrix to store band powers: rows=bands, columns=channels
    bandPowerMatrix = zeros(nBands, nChannels);
    
    for ch = 1:nChannels
        % Full PSD and spectrogram
        [pxx, f_pxx] = pwelch(dat(:,ch), window, window/2, nfft, fs);
        [S, f_S, t_S] = spectrogram(dat(:,ch), window, noverlap, nfft, fs);
        
        % Store full PSD and spectrogram
        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).psd = pxx;
        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).psd_f = f_pxx;
        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).spectrogram = S;
        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).spectrogram_f = f_S;
        PSD_Spect_Struct.(label).(['ch_' channels{ch}]).spectrogram_t = t_S;
        
        % Extract and store band-wise PSD and spectrogram and compute total power per band
       for b = 1:nBands
    band = bandNames{b};
    freqRange = freqBands.(band);

    % Find indices in PSD frequency vector that belong to this band
    freqIdx_psd = (f_pxx >= freqRange(1)) & (f_pxx <= freqRange(2));
    band_psd = pxx(freqIdx_psd);

    PSD_Spect_Struct.(label).(['ch_' channels{ch}]).([band '_psd']) = band_psd;
    PSD_Spect_Struct.(label).(['ch_' channels{ch}]).([band '_psd_f']) = f_pxx(freqIdx_psd);

    % Find indices in spectrogram frequency vector that belong to this band
    freqIdx_spect = (f_S >= freqRange(1)) & (f_S <= freqRange(2));
    PSD_Spect_Struct.(label).(['ch_' channels{ch}]).([band '_spectrogram']) = S(freqIdx_spect, :);
    PSD_Spect_Struct.(label).(['ch_' channels{ch}]).([band '_spectrogram_f']) = f_S(freqIdx_spect);

    % --- Use trapz for power ---
    band_freqs = f_pxx(freqIdx_psd);   % Collect frequency vector for band
    total_power = trapz(band_freqs, band_psd);

    bandPowerMatrix(b, ch) = total_power;
end

    end
    
    % Save band power matrix in the struct for this stimulus
    PSD_Spect_Struct.(label).bandPowerMatrix = bandPowerMatrix;
    
    % Optionally, save or display the bandPowerMatrix here
    fprintf('Stimulus %s band power matrix (rows=bands, cols=channels):\n', label);
    disp(array2table(bandPowerMatrix, 'RowNames', bandNames, 'VariableNames', channels));
end

save('PSD_Spectrogram_Data_Bands_withPower.mat', 'PSD_Spect_Struct', '-v7.3');


%%%%% plot 
% Example data matrix and channel/band names (replace with your own)
all_bands = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
all_channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2','P6','T8','FC6','F4','F8','AF4'};

% Example: replace s1a with your matrix
data_matrix = s1a; % 5x14, rows=bands, cols=channels

figure;
for bandIdx = 1:length(all_bands)
    subplot(length(all_bands),1,bandIdx)
    plot(1:length(all_channels), data_matrix(bandIdx,:), '-o', 'LineWidth', 2)
    set(gca, 'XTick', 1:length(all_channels), 'XTickLabel', all_channels)
    ylabel('log Power')
    title(['Band: ' all_bands{bandIdx}])
    grid on
end
xlabel('Channels')
sgtitle('Band Power Across Channels')
