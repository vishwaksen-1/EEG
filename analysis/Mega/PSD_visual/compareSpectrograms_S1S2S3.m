function TF_Compare = compareSpectrograms_S1S2S3(PSD_Spect_Struct)
% -------------------------------------------------------------------------
% Compares spectrograms for S1–S2–S3 (Standard–Deviant–Standard)
% Uses time-resolved spectral pattern distances
%
% OUTPUT:
%   TF_Compare.(band).(channel).DI   -> Deviance Index (S2 vs S1)
%   TF_Compare.(band).(channel).RCI  -> Recovery / Carryover Index
%   TF_Compare.(band).(channel).D12, D13, D23 (averaged distances)
% -------------------------------------------------------------------------

bands = {'delta_spectrogram','theta_spectrogram','alpha_spectrogram','beta_spectrogram','gamma_spectrogram'};
channels = fieldnames(PSD_Spect_Struct.seg1_subNorm(1));
nSubj = numel(PSD_Spect_Struct.seg1_subNorm);

eps_val = 1e-12;

for b = 1:numel(bands)
    band = bands{b};

    for ch = 1:numel(channels)
        chName = channels{ch};

        D12_all = zeros(nSubj,1);
        D13_all = zeros(nSubj,1);
        D23_all = zeros(nSubj,1);

        for subj = 1:nSubj

            % ---- Extract spectrograms ----
            S1 = PSD_Spect_Struct.seg1_subNorm(subj).(chName).(band);
            S2 = PSD_Spect_Struct.seg2_subNorm(subj).(chName).(band);
            S3 = PSD_Spect_Struct.seg3_subNorm(subj).(chName).(band);

            % Skip if spectrograms missing (e.g., delta/theta)
            if isempty(S1) || isempty(S2) || isempty(S3)
                D12_all(subj) = NaN;
                D13_all(subj) = NaN;
                D23_all(subj) = NaN;
                continue;
            end

            % ---- Convert to log-power ----
            S1 = 10*log10(abs(S1).^2 + eps_val);
            S2 = 10*log10(abs(S2).^2 + eps_val);
            S3 = 10*log10(abs(S3).^2 + eps_val);

            % ---- Normalize per time bin (pattern-based) ----
            for t = 1:size(S1,2)
                S1(:,t) = zscore(S1(:,t));
                S2(:,t) = zscore(S2(:,t));
                S3(:,t) = zscore(S3(:,t));
            end

            % ---- Time-resolved distances ----
            d12_t = sqrt(sum((S1 - S2).^2,1));
            d13_t = sqrt(sum((S1 - S3).^2,1));
            d23_t = sqrt(sum((S2 - S3).^2,1));

            % ---- Average over time ----
            D12_all(subj) = mean(d12_t);
            D13_all(subj) = mean(d13_t);
            D23_all(subj) = mean(d23_t);
        end

        % ---- Store subject-level ----
        TF_Compare.(band).(chName).D12 = D12_all;
        TF_Compare.(band).(chName).D13 = D13_all;
        TF_Compare.(band).(chName).D23 = D23_all;

        % ---- Indices ----
        TF_Compare.(band).(chName).DI  = nanmean(D12_all);
        TF_Compare.(band).(chName).RCI = ...
            nanmean(D13_all ./ (D12_all + eps_val));
    end
end
end
