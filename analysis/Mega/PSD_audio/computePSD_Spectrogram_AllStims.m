function PSD_Spect_Struct = computePSD_Spectrogram_AllStims(passnorm)
% -------------------------------------------------------------------------
% computePSD_Spectrogram_AllStims - Combines stim1–4 data (raw + normalized)
% and computes PSD, spectrogram, and band power for each subject & channel.
%
% INPUT:
%   passnorm.Out12.stim1_raw / stim2_raw / stim1_subNorm / ...
%   passnorm.Out34.stim1_raw / stim2_raw / stim1_subNorm / ...
%
% OUTPUT:
%   PSD_Spect_Struct.(stimLabel).(type) with:
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

stimLabels = {'stim1','stim2','stim3','stim4'};
dataTypes = {'raw','subNorm','subTrialNorm'};

%% ---------------- COLLECT DATA ----------------
disp('🔹 Collecting stim1–4 data...');

Results = struct();

% ---- Out12: stim1, stim2 ----
if isfield(passnorm, 'Out12')
    src = passnorm.Out12;
    Results.stim1_raw = src.stim1_raw;
    Results.stim1_subNorm = src.stim1_subNorm;
    Results.stim1_subTrialNorm = src.stim1_subTrialNorm;

    Results.stim2_raw = src.stim2_raw;
    Results.stim2_subNorm = src.stim2_subNorm;
    Results.stim2_subTrialNorm = src.stim2_subTrialNorm;
end

% ---- Out34: stim3, stim4 ----
if isfield(passnorm, 'Out34')
    src = passnorm.Out34;
    Results.stim3_raw = src.stim1_raw;
    Results.stim3_subNorm = src.stim1_subNorm;
    Results.stim3_subTrialNorm = src.stim1_subTrialNorm;

    Results.stim4_raw = src.stim2_raw;
    Results.stim4_subNorm = src.stim2_subNorm;
    Results.stim4_subTrialNorm = src.stim2_subTrialNorm;
end

%% ---------------- PSD + SPECTROGRAM ----------------
disp('🔹 Computing PSD & Spectrogram per subject/channel...');

PSD_Spect_Struct = struct();

for s = 1:numel(stimLabels)
    stim = stimLabels{s};

    for d = 1:numel(dataTypes)
        dtype = dataTypes{d};
        fieldName = [stim '_' dtype];

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

        % --- Handle all-NaN signals ---
        if all(isnan(sig)) || isempty(sig)
            warning('⚠️ Subject %d, %s, %s: all-NaN or empty signal. Filling with NaN outputs.', ...
                    subj, channels{ch}, fieldName);

            nanPSD = nan(nfft/2+1, 1);
            nanFreqs = linspace(0, fs/2, nfft/2+1)';
            nanSpect = nan(nfft/2+1, 1);
            nanTime = nan(1, 1);

            PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).psd = nanPSD;
            PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).psd_f = nanFreqs;
            PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).spectrogram = nanSpect;
            PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).spectrogram_f = nanFreqs;
            PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).spectrogram_t = nanTime;
            PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).bandPowerMatrix = nan(nBands,1);
            continue;
        end

        % --- Compute PSD ---
        [pxx, f_pxx] = pwelch(sig, window, window/2, nfft, fs);

        % --- Compute Spectrogram ---
        [S, f_S, t_S] = spectrogram(sig, window, noverlap, nfft, fs);

        % --- Store results ---
        PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).psd = pxx;
        PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).psd_f = f_pxx;
        PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).spectrogram = S;
        PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).spectrogram_f = f_S;
        PSD_Spect_Struct.(fieldName)(subj).(['ch_' channels{ch}]).spectrogram_t = t_S;

        % --- Band power ---
        bandPowerMatrix = zeros(nBands, 1);
        for b = 1:nBands
            band = bandNames{b};
            freqRange = freqBands.(band);
            freqIdx_psd = (f_pxx >= freqRange(1)) & (f_pxx <= freqRange(2));
            band_psd = pxx(freqIdx_psd);
            band_freqs = f_pxx(freqIdx_psd);
            total_power = trapz(band_freqs, band_psd);
            bandPowerMatrix(b) = total_power;

            % Save band-specific
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
% save('PSD_Spectrogram_AllStim_AllSubjects.mat', 'PSD_Spect_Struct', '-v7.3');
disp('✅ All stim PSD and spectrogram computations completed and saved!');

end
