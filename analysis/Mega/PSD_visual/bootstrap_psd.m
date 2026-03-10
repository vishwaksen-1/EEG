%% === Corrected bootstrap_psd function ===
function [bootMean, bootCI, freq] = bootstrap_psd(dataStruct, segField, chan, band, nBoot, ciPercent)
    % Bootstraps PSD across subjects and returns:
    %   bootMean : (nFreq x 1) bootstrap mean
    %   bootCI   : (nFreq x 2) [lower upper] percentiles (ciPercent)
    %   freq     : (nFreq x 1) frequency vector
    %
    % Inputs:
    %   dataStruct - struct with fields like seg1_raw, seg2_raw, ...
    %   segField   - e.g. 'seg1_raw'
    %   chan       - e.g. 'ch_AF3'
    %   band       - e.g. 'psd' or 'alpha_psd'
    %   nBoot      - number of bootstrap resamples
    %   ciPercent  - two-element vector, e.g. [5 95] for 90% CI

    % Frequency vector (column)
    freq = dataStruct.(segField)(1).(chan).([band '_f']);
    freq = freq(:);

    % Collect PSDs across subjects (freq x subjects)
    nSubjects = numel(dataStruct.(segField));
    allSubjectsData = NaN(numel(freq), nSubjects);
    for s = 1:nSubjects
        d = dataStruct.(segField)(s).(chan).(band);
        allSubjectsData(:, s) = d(:);
    end

    % Pre-allocate
    nFreq = size(allSubjectsData, 1);
    bootMeans = zeros(nFreq, nBoot);

    % Bootstrap across subjects
    for b = 1:nBoot
        idx = randi(nSubjects, [nSubjects, 1]);      % sample subject indices with replacement
        sample = allSubjectsData(:, idx);            % freq x nSubjects
        bootMeans(:, b) = mean(sample, 2);          % freq x 1
    end

    % Mean across bootstrap samples (freq x 1)
    bootMean = mean(bootMeans, 2);

    % Percentile CI (explicit lower and upper vectors)
    lowerPct = ciPercent(1);
    upperPct = ciPercent(2);
    ciLower = prctile(bootMeans, lowerPct, 2);  % freq x 1
    ciUpper = prctile(bootMeans, upperPct, 2);  % freq x 1

    bootCI = [ciLower(:), ciUpper(:)];          % freq x 2

    % ensure column shapes
    bootMean = bootMean(:);
    freq = freq(:);
end
