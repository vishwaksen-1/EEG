function [corrStruct, acorrStruct] = corrAcrr(signal, maxLagSec, nBoot)
% corrAcrr - Compute bootstrapped channel correlation and autocorrelation
%
% Inputs:
%   signal     : signal
%   maxLagSec  : maximum lag for correlation, in seconds
%
% Outputs:
%   corrStruct : struct containing mean/std cross-channel correlations
%   acorrStruct: struct containing mean/std channel autocorrelations
%
% Signal dimensions: subjects × channels × samples
%
% Sampling rate is assumed to be 256 Hz (modify below if needed)

    %% --- Parameters ---
    Fs = 256;                                  % Sampling rate (Hz)
    maxLagSamples = round(maxLagSec * Fs);     % Convert seconds → samples
    
    if nargin < 3
        nBoot = 500;                           % number of Bootstraps
    end

    %% --- Extract signal ---
    % signal = datanorm.(var1).(var2);           % [subjects × channels × samples]
    

    validSubjects = squeeze(all(all(~isnan(signal), 2), 3));   % [nSubjects × 1 logical]
    
    % Keep only valid subjects
    signal = signal(validSubjects, :, :);

    [nSubjects, nChannels, ~] = size(signal);

    %% --- Initialize arrays ---
    lags = (-maxLagSamples:maxLagSamples) / Fs;  % in seconds
    acorrAll = zeros(nBoot, nChannels, numel(lags));
    corrAll  = zeros(nBoot, nChannels, nChannels, numel(lags));

    compl = 0;

    %% --- Bootstrap loop ---
    for b = 1:nBoot
        idx = randsample(nSubjects, nSubjects, true);
        bootData = squeeze(mean(signal(idx, :, :), 1)); % [channels × samples]
        
        if mod(b, 50) == 0
            compl = compl + 10;
            fprintf('Bootstrap progress: %d%% completed\n', compl);
        end

        % Autocorrelation (per channel)
        for ch = 1:nChannels
            acorrAll(b, ch, :) = xcorr(bootData(ch, :), maxLagSamples, 'coeff');
        end

        % Cross-channel correlation
        for ch1 = 1:nChannels
            for ch2 = ch1:nChannels
                c = xcorr(bootData(ch1, :), bootData(ch2, :), maxLagSamples, 'coeff');
                corrAll(b, ch1, ch2, :) = c;
                corrAll(b, ch2, ch1, :) = flip(c); % flipped
            end
        end
    end

    %% --- Compute summary statistics ---
    acorrStruct.mean = squeeze(mean(acorrAll, 1));
    acorrStruct.std  = squeeze(std(acorrAll, [], 1));
    acorrStruct.lags = lags;

    corrStruct.mean = squeeze(mean(corrAll, 1));
    corrStruct.std  = squeeze(std(corrAll, [], 1));
    corrStruct.lags = lags;

    %% --- Metadata ---
    acorrStruct.params = struct( ...
        'nBoot', nBoot, ...
        'maxLagSec', maxLagSec, ...
        'Fs', Fs ...
    );
    corrStruct.params = acorrStruct.params;
end
