function result = extractBehaviourAll(folder)
% extractBehaviourAll(folder)
%   Scans all .mat files in 'folder' (same files t_segmentAllEEG uses),
%   reads T_data_cleaned from each, and computes:
%
%   result(sub, stim, trial).lag   -> reaction time in seconds (or -1)
%   result(sub, stim, trial).res   ->  1 = correct, 0 = incorrect, -1 = miss
%
%   This function applies exactly the same behavioral logic as
%   t_segmentBlock/t_segmentEEGData:
%     - Uses marker ROW INDICES (find(~isnan(T_data_cleaned.markerInd)))
%       and treats any marker occurrence inside a segment as a response.
%     - Uses the same globalStartIdx computation for the main block:
%           gSi = markerRows(3) + 128 + delay_samples
%     - Segment length = round(segDur * fs)
%     - Stimulus order is taken from jablingOrder(.)
%
%   Defaults:
%     fs = 256; segDur = 6.5; INITIAL_DELAY_MS = 592;
%
%   Note: This version follows the 'active' experiment globalStartIdx rule.
%         For passive datasets, there are usually no behavioral responses,
%         and results will be populated according to the rules below.

%% Parameters
fs = 256;
segDur = 6.5;
segLen = round(segDur * fs);
INITIAL_DELAY_MS = 592;
delay_samples = round(INITIAL_DELAY_MS / 1000 * fs);

% collect files using same fileGlobber regex as t_segmentAllEEG
addpath('../..'); % adjust if needed
file_ending_regex = '.*(?<!_marker|_cleaning_stats)\.mat$';
files = fileGlobber(file_ending_regex, folder);

if isempty(files)
    error('No valid .mat files found in the folder.');
end

numSubjects = numel(files);
fprintf('Found %d subject files.\n', numSubjects);

% infer experiment type and setno from first filename (same heuristic)
firstFile = files{1};
base = firstFile(1:end-4);
if contains(base, 'act', 'IgnoreCase', true)
    experimentType = 'active';
elseif contains(base, 'pas', 'IgnoreCase', true)
    experimentType = 'passive';
else
    error('Could not determine experiment type from filename (expect "act" or "pas").');
end

if contains(base, 'set1', 'IgnoreCase', true)
    setno = 1;
elseif contains(base, 'set2', 'IgnoreCase', true)
    setno = 2;
else
    setno = 0;
end

% Load jablingOrder file according to setno (matches t_segmentBlock behaviour)
switch setno
    case 0, load('jablingOrder.mat', 'jablingOrder');
    case 1, load('jablingOrder1.mat', 'jablingOrder');
    case 2, load('jablingOrder2.mat', 'jablingOrder');
    otherwise, error('Invalid set number.');
end

% determine nStim and nTrials from jablingOrder
[nTrialsFromOrder, nStim] = size(jablingOrder);
% In your pipeline nTrials is 10. Use nTrials from jablingOrder rows if present,
% else fallback to 10.
if nTrialsFromOrder > 0
    nTrials = nTrialsFromOrder;
else
    nTrials = 10;
end

% Preallocate result with default -1
result(numSubjects, nStim, nTrials) = struct('lag', -1, 'res', -1);

% periodic targets as in t_segmentBlock
periodic_stim_ids = [1, 3];

%% Process each subject
for s = 1:numSubjects
    fprintf('Processing subject %d/%d: %s\n', s, numSubjects, files{s});
    fullPath = fullfile(folder, files{s});

    % Load only T_data_cleaned
    try
        load(fullPath, 'T_data_cleaned');
    catch ME
        warning('Could not load T_data_cleaned from %s: %s. Skipping subject.', files{s}, ME.message);
        continue;
    end

    % Find marker rows (same as original code)
    markerRows = find(~isnan(T_data_cleaned.markerInd));
    % markerValues available if needed: markerValues = T_data_cleaned.markerValue(markerRows);

    % If not enough markers to determine block start, warn and skip
    if numel(markerRows) < 3
        warning('Not enough markers in %s to determine globalStartIdx. Filling with -1.', files{s});
        continue;
    end

    % Compute the globalStartIdx for the main block (same formula as t_segmentEEGData)
    globalStartIdx = markerRows(3) + 128 + delay_samples;

    % Now iterate segments in the same order as t_segmentBlock:
    % p counts segments 1..(nTrials * nStim)
    p = 1;
    for tr = 1:nTrials
        for st = 1:nStim
            stimID = jablingOrder(tr, st);

            % compute segment global start & end (inclusive)
            segStartGlobal = globalStartIdx + (p - 1) * segLen;
            segEndGlobal = segStartGlobal + segLen - 1;

            % markers inside this segment (exact same check as t_segmentBlock)
            markersInSegment = markerRows(markerRows >= segStartGlobal & markerRows <= segEndGlobal);

            is_periodic = ismember(stimID, periodic_stim_ids);
            has_response = ~isempty(markersInSegment);

            if ~has_response
                if is_periodic
                    % MISS
                    result(s, stimID, tr).res = -1;
                    result(s, stimID, tr).lag = -1;
                else
                    % CORRECT REJECTION
                    result(s, stimID, tr).res = 1;
                    result(s, stimID, tr).lag = -1;
                end
            else
                % FIRST marker = response
                firstMarkerIdx = markersInSegment(1);
                lag_samples = firstMarkerIdx - segStartGlobal;
                lag_sec = lag_samples / fs;
            
                if is_periodic
                    % HIT
                    result(s, stimID, tr).res = 1;
                    result(s, stimID, tr).lag = lag_sec;
                else
                    % FALSE ALARM
                    result(s, stimID, tr).res = 0;
                    result(s, stimID, tr).lag = lag_sec;
                end
            end

            p = p + 1;
        end
    end
end

fprintf('Behaviour extraction complete.\n');
end
