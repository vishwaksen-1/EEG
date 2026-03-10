function PSD_Spect_Struct = computePSD_Spectrogram_Allsegs(datanorm)
% -------------------------------------------------------------------------
% computePSD_Spectrogram_Allsegs - Combines seg1–3 data (raw + normalized)
% and computes PSD, spectrogram, and band power for each subject & channel.
%
% INPUT:
%   datanorm.Out.seg1_raw / seg2_raw / seg1_subNorm / ...
%   datanorm.Out.seg1_raw / seg2_raw / seg1_subNorm / ...
%
% OUTPUT:
%   PSD_Spect_Struct.(segLabel).(type) with:
%       .psd, .spectrogram, .bandPowerMatrix per subject
%
% -------------------------------------------------------------------------

%% ---------------- CONFIGURATION ----------------
channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2',...
            'P8','T8','FC6','F4','F8','AF4'};
fs = 256;           % Sampling frequency (Hz)
window = 64;        % Window length for PSD/spectrogram
noverlap = window/2;
nfft = 512;

freqBands = struct( ...
    'delta', [0.1 4], ...
    'theta', [4 8], ...
    'alpha', [8 12], ...
    'beta',  [12 30], ...
    'gamma', [30 50]);
bandNames = fieldnames(freqBands);
nBands = length(bandNames);
nChannels = length(channels);

segLabels = {'seg1','seg2','seg3'};
dataTypes = {'raw','subNorm','subNormByGlobalBaseline'};

%% ---------------- COLLECT DATA ----------------
disp('🔹 Collecting seg1–3 data...');

Results = struct();

% ---- Out: seg1, seg2, seg3 ----
if isfield(datanorm, 'Out')
    src = datanorm.Out;
    Results.seg1_raw = src.seg1_raw;
    Results.seg1_subNorm = src.seg1_subNorm;
    Results.seg1_subNormByGlobalBaseline = src.seg1_subNormByGlobalBaseline;

    Results.seg2_raw = src.seg2_raw;
    Results.seg2_subNorm = src.seg2_subNorm;
    Results.seg2_subNormByGlobalBaseline = src.seg2_subNormByGlobalBaseline;

    Results.seg3_raw = src.seg3_raw;
    Results.seg3_subNorm = src.seg3_subNorm;
    Results.seg3_subNormByGlobalBaseline = src.seg3_subNormByGlobalBaseline;
end

%% ---------------- PSD + SPECTROGRAM ----------------
disp('🔹 Computing PSD & Spectrogram per subject/channel...');

PSD_Spect_Struct = struct();

for s = 1:numel(segLabels)
    seg = segLabels{s};

    for d = 1:numel(dataTypes)
        dtype = dataTypes{d};
        fieldName = [seg '_' dtype];

        if ~isfield(Results, fieldName)
            fprintf('⚠️ Missing field: %s\n', fieldName);
            continue;
        end

        data = Results.(fieldName);  % [subjects × channels × datapoints]
        if isempty(data)
            fprintf('⚠️ Empty data for %s\n', fieldName);
            continue;
        end

        nSubjects = size(data, 1);
        disp(['Processing ' fieldName ' (', num2str(nSubjects), ' subjects)...']);

        for subj = 1:nSubjects
            subjData = squeeze(data(subj, :, :));  % [channels × time]

            for ch = 1:nChannels
                sig = subjData(ch, :)';

                % PSD
                [pxx, f_pxx] = pwelch(sig, window, window/2, nfft, fs);

                % Spectrogram
                [S, f_S, t_S] = spectrogram(sig, window, noverlap, nfft, fs);

                % Store full PSD and spectrogram
                PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).psd = pxx;
                PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).psd_f = f_pxx;
                PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).spectrogram = S;
                PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).spectrogram_f = f_S;
                PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).spectrogram_t = t_S;

                % Band power computation
                bandPowerMatrix = zeros(nBands, 1);
                for b = 1:nBands
                    band = bandNames{b};
                    freqRange = freqBands.(band);
                    freqIdx_psd = (f_pxx >= freqRange(1)) & (f_pxx <= freqRange(2));
                    band_psd = pxx(freqIdx_psd);
                    band_freqs = f_pxx(freqIdx_psd);
                    total_power = trapz(band_freqs, band_psd);
                    bandPowerMatrix(b) = total_power;

                    % Save band-wise PSD & Spectrogram
                    PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).([band '_psd']) = band_psd;
                    PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).([band '_psd_f']) = band_freqs;
                    freqIdx_spect = (f_S >= freqRange(1)) & (f_S <= freqRange(2));
                    PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).([band '_spectrogram']) = S(freqIdx_spect, :);
                    PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).([band '_spectrogram_f']) = f_S(freqIdx_spect);
                end

                PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).bandPowerMatrix = bandPowerMatrix;
            end
        end
    end
end

%% ---------------- SAVE RESULTS ----------------
save('PSD_Spectrogram_Allseg_AllSubjects.mat', 'PSD_Spect_Struct', '-v7.3');
disp('✅ All seg PSD and spectrogram computations completed and saved!');

end
