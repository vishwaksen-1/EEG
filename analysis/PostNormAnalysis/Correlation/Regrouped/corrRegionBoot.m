function corrStruct = corrRegionBoot(signal, maxLagSec, nBoot)
% corrRegionBoot
% Computes bootstrapped REGION-level *directed* lagged cross-correlations
%
% INPUTS:
%   signal     : subjects × channels × samples
%   maxLagSec  : maximum lag (seconds)
%   nBoot      : number of bootstraps (default = 500)
%
% OUTPUT:
%   corrStruct.mean : regions × regions × lags
%   corrStruct.std  : regions × regions × lags
%   corrStruct.lags : lag vector (seconds)
%   corrStruct.params : metadata
%
% NOTE:
%   corr(r1,r2,τ) = corr(r2,r1,-τ)

    %% ---------------- Parameters ----------------
    Fs = 256;
    maxLagSamples = round(maxLagSec * Fs);

    if nargin < 3
        nBoot = 500;
    end

    %% ---------------- Channel labels ----------------
    channels_labels = {'AF3','F7','F3','FC5','T7','P7','O1','O2', ...
                       'P8','T8','FC6','F4','F8','AF4'};
    idx = @(labels) find(ismember(channels_labels, labels));

    %% ---------------- Region definitions ----------------
    groups = {
        idx({'AF3','F3','FC5'}), ...   % L Frontal
        idx({'FC6','F4','AF4'}), ...   % R Frontal
        idx({'T7'}), ...               % L Temporal
        idx({'T8'}), ...               % R Temporal
        idx({'P7'}), ...               % L Parietal
        idx({'P8'}), ...               % R Parietal
        idx({'O1'}), ...               % L Occipital
        idx({'O2'})                    % R Occipital
    };

    region_labels = {'L_Frontal','R_Frontal','L_Temporal','R_Temporal', ...
                     'L_Parietal','R_Parietal','L_Occipital','R_Occipital'};

    nRegions = numel(groups);

    %% ---------------- Remove invalid subjects ----------------
    validSubjects = squeeze(all(all(~isnan(signal),2),3));
    signal = signal(validSubjects,:,:);

    [nSubjects, nChannels, ~] = size(signal);

    %% ---------------- Lag vector ----------------
    lags = (-maxLagSamples:maxLagSamples) / Fs;
    nLags = numel(lags);

    %% ---------------- Bootstrap storage ----------------
    regionCorrBoot = zeros(nBoot, nRegions, nRegions, nLags);

    %% ---------------- Bootstrap loop ----------------
    for b = 1:nBoot
        % Resample subjects
        subjIdx = randsample(nSubjects, nSubjects, true);
        bootData = squeeze(mean(signal(subjIdx,:,:),1));  % channels × samples

        % ---------- Channel-level lagged correlations ----------
        chanCorr = zeros(nChannels, nChannels, nLags);

        for ch1 = 1:nChannels
            for ch2 = ch1:nChannels
                c = xcorr(bootData(ch1,:), bootData(ch2,:), ...
                          maxLagSamples, 'coeff');

                chanCorr(ch1,ch2,:) = c;         % ch1 -> ch2
                chanCorr(ch2,ch1,:) = flip(c);   % ch2 -> ch1
            end
        end

        % ---------- Aggregate into regions (DIRECTED) ----------
        for r1 = 1:nRegions
            for r2 = 1:nRegions
                vals = chanCorr(groups{r1}, groups{r2}, :);
                regionCorrBoot(b,r1,r2,:) = ...
                    squeeze(mean(vals, [1 2], 'omitnan'));
            end
        end

        if mod(b,50) == 0
            fprintf('Bootstrap %d / %d completed\n', b, nBoot);
        end
    end

    %% ---------------- Summary statistics ----------------
    corrStruct.mean = squeeze(mean(regionCorrBoot,1));
    corrStruct.std  = squeeze(std(regionCorrBoot,[],1));
    corrStruct.lags = lags;

    %% ---------------- Metadata ----------------
    corrStruct.params = struct( ...
        'nBoot', nBoot, ...
        'maxLagSec', maxLagSec, ...
        'Fs', Fs, ...
        'region_labels', {region_labels} ...
    );
end
