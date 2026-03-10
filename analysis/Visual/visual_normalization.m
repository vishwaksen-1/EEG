datanorm = struct();
datanorm.Out = struct();
datanorm.Out.channels = cell(1, 14);  % optional channel names

numSubjects = numel(data);
numCh = 14;
numSegs = 3;
numSamp = 512;

%%
% Initialize empty arrays
seg_raw = zeros(numSubjects, numCh, numSamp, numSegs);

for i = 1:numSubjects
    allData = data{i}{4};   % (samples x channels x segments x trials)
   
    % Average across trials
    meanAcrossTrials = mean(allData, 4);   % (samples x channels x segments)
   
    % Reorder to (channels x samples x segments)
    meanAcrossTrials = permute(meanAcrossTrials, [2 1 3]);
   
    % Store in seg_raw
    seg_raw(i, :, :, :) = meanAcrossTrials;  % 26x14x512x3
end

datanorm.Out.seg1_raw = squeeze(seg_raw(:,:,:,1)); % (26x14x512)
datanorm.Out.seg2_raw = squeeze(seg_raw(:,:,:,2));
datanorm.Out.seg3_raw = squeeze(seg_raw(:,:,:,3));

seg1_raw = datanorm.Out.seg1_raw;

%% Compute RMS per subject x channel
baselineRMS = sqrt(mean(seg1_raw.^2, 3));  % (26x14)

for seg = 1:3
    segRaw = squeeze(seg_raw(:,:,:,seg));  % (26x14x512)
    segNorm = zeros(size(segRaw));

    for subj = 1:numSubjects
        % broadcast RMS for that subject (14x512)
        segNorm(subj,:,:) = squeeze(segRaw(subj,:,:)) ./ baselineRMS(subj,:)' ;
    end

    datanorm.Out.(['seg' num2str(seg) '_subNorm']) = segNorm;
end

%%
globalBaselineRMS = mean(baselineRMS, 1);  % (1x14)

for seg = 1:3
    segRaw = squeeze(seg_raw(:,:,:,seg));  % (26x14x512)
    segGlobalNorm = zeros(size(segRaw));

    for subj = 1:numSubjects
        segGlobalNorm(subj,:,:) = squeeze(segRaw(subj,:,:)) ./ globalBaselineRMS';
    end

    datanorm.Out.(['seg' num2str(seg) '_subNormByGlobalBaseline']) = segGlobalNorm;
end

%%
save('datanorm.mat', 'datanorm');