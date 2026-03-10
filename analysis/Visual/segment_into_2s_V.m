function segment_into_2s_V(X)

fs = 256;                
winLength = 2 * fs;       
[numSub, numTrials, numChan, numPoints] = size(X);

numSeg = 3; % hard coded 

% Subject x Trial x Channel x Segment x DataPoints
segmentedX = nan(numSub, numTrials, numChan, numSeg, winLength);

%% Loop through and segment
for s = 1:numSub
    for t = 1:numTrials
        for c = 1:numChan
            signal = squeeze(X(s, t, c, :));
            
            for seg = 1:numSeg
                idxStart = (seg-1)*winLength + 1;
                idxEnd   = seg*winLength;
                segmentedX(s, t, c, seg, :) = signal(idxStart:idxEnd);
            end
        end
    end
end

%disp(['Data segmented into ' num2str(numSeg) ' segments of 2s each.']);



end