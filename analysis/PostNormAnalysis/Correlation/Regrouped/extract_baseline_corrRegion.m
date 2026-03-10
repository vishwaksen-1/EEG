function baseline_results = extract_baseline_corrRegion(final_act, maxLagSec, nBoot)
% extract_baseline_corr
%
% Extracts REGION-LEVEL baseline correlations during experiment.
% Baseline = first 0.5 s of during-experiment data.
%
% DATA FORMAT (during data per subject):
%   samples × channels × stim × trials
%   [1664 × 14 × 4 × 10]
%
% Processing steps:
%   1) Take first 0.5 s (128 samples @ 256 Hz)
%   2) Average across trials
%   3) Compute region-level correlations per stimulus
%
% OUTPUT:
%   baseline_results.duringExp_baseline.stim_X.corr
%
% ------------------------------------------------------------

    if nargin < 3 || isempty(nBoot)
        nBoot = 500;
    end

    Fs = 256;
    baselineDurSec = 0.5;
    nBaseSamp = round(baselineDurSec * Fs);  % 128 samples

    fprintf('\n========================================\n');
    fprintf('Extracting DURING-EXPERIMENT BASELINES\n');
    fprintf('Baseline window: first %.1f s (%d samples)\n', ...
            baselineDurSec, nBaseSamp);
    fprintf('========================================\n');

    nSubjects = numel(final_act);

    % Inspect first subject to get dimensions
    exampleRow  = final_act{1};
    duringData  = exampleRow{4};  % samples × channels × stim × trials

    nStim    = size(duringData, 3);
    nChan    = size(duringData, 2);

    duringExp = struct();

    % ------------------------------------------------------------
    % Loop over stimulus conditions
    % ------------------------------------------------------------
    for stim = 1:nStim
        fprintf('\nStimulus %d / %d\n', stim, nStim);

        % Container:
        % subjects × channels × baseline_samples
        subjData = zeros(nSubjects, nChan, nBaseSamp);

        % --------------------------------------------------------
        % Loop over subjects
        % --------------------------------------------------------
        for s = 1:nSubjects
            row = final_act{s};
            durData = row{4};  % samples × channels × stim × trials

            % ----------------------------------------------------
            % 1) Extract baseline samples
            % ----------------------------------------------------
            % [baseline_samples × channels × trials]
            baseSeg = durData(1:nBaseSamp, :, stim, :);

            % ----------------------------------------------------
            % 2) Average across trials
            % ----------------------------------------------------
            % → baseline_samples × channels
            baseMean = mean(baseSeg, 4);

            % ----------------------------------------------------
            % 3) Reformat to channels × samples
            % ----------------------------------------------------
            subjData(s,:,:) = permute(baseMean, [2 1]);
        end

        % --------------------------------------------------------
        % 4) Region-level correlation (bootstrapped)
        % --------------------------------------------------------
        corrStruct = corrRegionBoot(subjData, maxLagSec, nBoot);

        stimField = sprintf('stim_%d', stim);

        duringExp.(stimField) = struct( ...
            'corr', corrStruct, ...
            'params', struct( ...
                'type', 'duringExp_baseline', ...
                'stim', stim, ...
                'baseline_samples', nBaseSamp, ...
                'baseline_duration_sec', baselineDurSec, ...
                'Fs', Fs, ...
                'maxLagSec', maxLagSec, ...
                'nBoot', nBoot ...
            ) ...
        );

        fprintf('  ✓ Baseline correlations computed\n');
    end

    baseline_results.duringExp_baseline = duringExp;

    fprintf('\n✅ Baseline extraction complete.\n');
end
