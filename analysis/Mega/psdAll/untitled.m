%% Construct unified PSD structure from variable `ans`
% ans: [14 x 3 x 512]  (channels x segments x samples)
% Output: PSD_Spect_Struct_visual (1x1 struct)

data = squeeze(mean(segmentedX, [1 2])); % rename for clarity
num_channels = size(data, 1);
num_segments = size(data, 2);
fs = 256; % adjust this if your sampling rate differs

segments = {'seg1', 'seg2', 'seg3'};

PSD_Spect_Struct_visual = struct();

channels = {"AF3", 'F7', 'F3', 'FC5', 'T7', 'P7', 'O1', 'O2', ...
             'P6', 'T8', 'FC6', 'F4', 'F8', 'AF4'};

for s = 1:num_segments
    seg_name = segments{s};
    for ch = 1:length(channels)
        signal = squeeze(data(ch, s, :));
        
        % --- Compute PSD ---
        [psd, psd_f] = pwelch(signal, 64, 32, 128, fs);
        
        % --- Compute Spectrogram ---
        [spec, spec_f, spec_t] = spectrogram(signal, 64, 32, 128, fs, 'yaxis');
        
        % --- Store in structure ---
        PSD_Spect_Struct_visual.(seg_name).(sprintf('ch_%s', channels{ch})).psd = psd;
        PSD_Spect_Struct_visual.(seg_name).(sprintf('ch_%s', channels{ch})).psd_f = psd_f;
        PSD_Spect_Struct_visual.(seg_name).(sprintf('ch_%s', channels{ch})).spectrogram = (spec);
        PSD_Spect_Struct_visual.(seg_name).(sprintf('ch_%s', channels{ch})).spectrogram_f = spec_f;
        PSD_Spect_Struct_visual.(seg_name).(sprintf('ch_%s', channels{ch})).spectrogram_t = spec_t;
    end
end
