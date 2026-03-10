% Assume segmentedX is loaded in workspace: size(segmentedX) = [26 10 14 3 512]

numSubjects = size(segmentedX, 1);
numTrials   = size(segmentedX, 2);
numCh       = size(segmentedX, 3);
numSegs     = size(segmentedX, 4);
numSamp     = size(segmentedX, 5);

data = cell(numSubjects, 1);  % Initialize 26x1 cell

for i = 1:numSubjects
    % Extract:
    % 3rd element: Segment 1, first trial
    seg1_firstTrial = squeeze(segmentedX(i, 1, :, 1, :))';  % (samples x channels)

    % 4th element: All data (samples x channels x segments x trials)
    allData = permute(squeeze(segmentedX(i, :, :, :, :)), [5 3 4 2]-1); 
    % 512 x 14 x 3 x 10

    % 5th element: Segment 3, last trial
    seg3_lastTrial = squeeze(segmentedX(i, numTrials, :, numSegs, :))';  % (samples x channels)

    % Assemble subject data cell
    data{i} = {'visual', '--', seg1_firstTrial, allData, seg3_lastTrial};
end
