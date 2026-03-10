function baseline_results = extract_baseline_corr(final_act)
% extract_baselines_corrs - Compute pre- and during-experiment baseline correlations
%
% INPUT:
%   final_act : {N×1 cell}, where each element = {subjName, setName, preBaseline, duringData, postData}
%
% OUTPUT:
%   baseline_results.preExp_baseline
%   baseline_results.duringExp_baseline
%
% Uses corrAcrr() for computing correlations (bootstrapping across subjects)
%
% Author: [Your Name]
% Date: [YYYY-MM-DD]

    Fs = 256;
    maxLag_preExp = 1.8;  % seconds
    durBaseline_s = 0.5;  % seconds
    nSamples_during = round(durBaseline_s * Fs);
    nSubjects = numel(final_act);

    %% ============================
    % 1️⃣ PRE-EXPERIMENT BASELINE
    % =============================
    fprintf('\n===== PRE-EXPERIMENT BASELINE =====\n');

    % Prepare segment parameters
    skipSamples = 5 * Fs;      % skip first 5 seconds (1280)
    takeSamples = 4 * Fs;      % take next 4 seconds (1024)

    preSegments = {};  % store valid subjects' data
    subjKeep = [];

    for s = 1:nSubjects
        dat = final_act{s};
        if isempty(dat) || numel(dat) < 3 || isempty(dat{3})
            warning('Subject %d missing pre-baseline data.', s);
            continue;
        end

        base = dat{3}; % [samples × channels]
        if size(base,1) < (skipSamples + takeSamples)
            warning('Subject %d baseline too short (%d samples). Skipped.', s, size(base,1));
            continue;
        end

        % Extract clean segment: skip first 5s, take next 4s
        seg = base(skipSamples+1 : skipSamples+takeSamples, :);
        preSegments{end+1} = seg; %#ok<AGROW>
        subjKeep(end+1) = s; %#ok<AGROW>
    end

    nValid = numel(preSegments);
    if nValid == 0
        error('No valid pre-experiment baseline segments found!');
    end
    fprintf('Valid subjects for pre-baseline: %d / %d\n', nValid, nSubjects);

    nCh = size(preSegments{1}, 2);
    nSamples = size(preSegments{1}, 1);

    % Build [subjects × channels × samples] array
    preData = NaN(nValid, nCh, nSamples);
    for i = 1:nValid
        preData(i,:,:) = preSegments{i}';
    end

    % Compute correlations with corrAcrr()
    [corrStruct_pre, acorrStruct_pre] = corrAcrr(preData, maxLag_preExp);

    baseline_results.preExp_baseline = struct( ...
        'corr', corrStruct_pre, ...
        'acorr', acorrStruct_pre, ...
        'params', struct('type', 'preExp', 'Fs', Fs, ...
                         'maxLag', maxLag_preExp, ...
                         'segment', [skipSamples takeSamples]) ...
    );

    fprintf('Computed pre-experiment baseline correlations successfully.\n');

    %% ============================
    % 2️⃣ DURING-EXPERIMENT BASELINE (0–0.5s)
    % =============================
    fprintf('\n===== DURING-EXPERIMENT BASELINE =====\n');

    nStims = 4;
    duringExp = struct();

    for stim = 1:nStims
        fprintf('Processing stim %d ...\n', stim);

        duringSegments = {};
        for s = 1:nSubjects
            dat = final_act{s};
            if isempty(dat) || numel(dat) < 4 || isempty(dat{4})
                continue;
            end

            expData = dat{4}; % [1664 × ch × stim × trials]
            if size(expData,3) < stim
                continue;
            end

            % Extract first 0.5s baseline across trials
            trials = squeeze(expData(1:nSamples_during,:,stim,:)); % [samples × ch × trials]
            trialsMean = mean(trials, 3, 'omitnan');               % average across trials
            duringSegments{end+1} = trialsMean; %#ok<AGROW>
        end

        nValid = numel(duringSegments);
        if nValid == 0
            warning('No valid subjects for stim %d during-baseline.', stim);
            continue;
        end

        nCh = size(duringSegments{1}, 2);
        nSamples = size(duringSegments{1}, 1);
        duringData = NaN(nValid, nCh, nSamples);

        for i = 1:nValid
            duringData(i,:,:) = duringSegments{i}';
        end

        % Compute correlations
        [corrStruct_dur, acorrStruct_dur] = corrAcrr(duringData, durBaseline_s);

        stimField = sprintf('stim%d_baseline', stim);
        duringExp.(stimField) = struct( ...
            'corr', corrStruct_dur, ...
            'acorr', acorrStruct_dur, ...
            'params', struct('type', 'duringExp', 'stim', stim, ...
                             'Fs', Fs, 'maxLag', durBaseline_s) ...
        );

        fprintf('  Stim %d baseline computed.\n', stim);
    end

    baseline_results.duringExp_baseline = duringExp;

    fprintf('\n✅ Baseline correlation extraction complete.\n');
end
