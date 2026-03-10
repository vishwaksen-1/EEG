%% ================= USER INPUT =================
% Example: stim1 of Out12
corrStruct = results.Out34.stim2_subTrialNorm.corr;

meanCorr = corrStruct.mean;   % [14 x 14 x T]
stdCorr  = corrStruct.std;    % [14 x 14 x T]
lags     = corrStruct.lags;   %#ok<NASGU>

nCh = size(meanCorr,1);
T   = size(meanCorr,3);

% Confidence levels
confLevels = [0.90, 0.95, 0.99];
zVals      = [1.645, 1.96, 2.576];

%% ================= STEP 1: EXTRACT OFF-DIAGONAL PAIRS =================
mask = ~eye(nCh);
nPairs = nnz(mask);

meanPairs = zeros(nPairs, T);
stdPairs  = zeros(nPairs, T);

idx = 1;
for i = 1:nCh
    for j = 1:nCh
        if mask(i,j)
            meanPairs(idx,:) = squeeze(meanCorr(i,j,:));
            stdPairs(idx,:)  = squeeze(stdCorr(i,j,:));
            idx = idx + 1;
        end
    end
end

%% ================= STEP 1.5: UNIQUE PAIRS & CENTRAL LAGS =================
% Use only upper triangle (i < j) → 91 pairs
pairIdx = find(triu(ones(nCh),1));
nPairs  = numel(pairIdx);

meanPairs = zeros(nPairs, T);
stdPairs  = zeros(nPairs, T);

[idx_i, idx_j] = ind2sub([nCh nCh], pairIdx);

for p = 1:nPairs
    meanPairs(p,:) = squeeze(meanCorr(idx_i(p), idx_j(p), :));
    stdPairs(p,:)  = squeeze(stdCorr(idx_i(p), idx_j(p), :));
end

% --- central lag window (~512 lags) ---
midLag = ceil(T/2);
lagHalfWidth = 256;

lagIdx = (midLag - lagHalfWidth) : (midLag + lagHalfWidth - 1);

meanPairs = meanPairs(:, lagIdx);
stdPairs  = stdPairs(:, lagIdx);

Tsel = numel(lagIdx);   % should be ~512

% %% ================= STEP 2: BUILD NULL DISTRIBUTION (FAST) =================
% % Null = distribution of absolute correlations under no temporal preference
% 
% nullVals = abs(meanPairs(:));

%% ================= STEP 2: NULL DISTRIBUTION (POINTWISE, CORRECT) =================
nShuffle = 500;

% We only need percentiles, so subsample intelligently
% Collect one random lag per pair per shuffle
nullVals = zeros(nShuffle * nPairs, 1);
idx = 1;

for s = 1:nShuffle
    for p = 1:nPairs
        % Permute lag axis
        permIdx = randperm(Tsel);
        shuffledCorr = meanPairs(p, permIdx);

        % Take ONE random lag (pointwise null)
        randLag = randi(Tsel);
        nullVals(idx) = abs(shuffledCorr(randLag));
        idx = idx + 1;
    end
end

%% ================= STEP 3: HIGH-ACTIVITY THRESHOLDS =================
thrAbs = struct();

thrAbs(1).confidence = 0.90;
thrAbs(1).value      = prctile(nullVals, 90);

thrAbs(2).confidence = 0.95;
thrAbs(2).value      = prctile(nullVals, 95);

thrAbs(3).confidence = 0.99;
thrAbs(3).value      = prctile(nullVals, 99);

fprintf('\nAbsolute High-Correlation Thresholds (Null-based)\n');
fprintf('------------------------------------------------\n');
for k = 1:numel(thrAbs)
    fprintf('%2.0f%% confidence: |Corr| > %.3f\n', ...
        thrAbs(k).confidence*100, thrAbs(k).value);
end