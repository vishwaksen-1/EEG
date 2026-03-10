function data4D = segmentBlock(eegBlock, fs, segDur, jabling_file_option)
% segmentBlock  — Segments an EEG block into a 4D matrix.
%
%   Args:
%       eegBlock (double): [N x 14] double array (samples x channels).
%       fs (double): Sampling frequency in Hz.
%       segDur (double): Desired segment duration in seconds.
%       jabling_file_option (int): 0 for 'jablingOrder0.mat',
%                                  1 for 'jablingOrder1.mat',
%                                  2 for 'jablingOrder2.mat'.
%
%   Returns:
%       data4D (double): The segmented 4D matrix.

% Load the correct jabling order file based on the option
switch jabling_file_option
    case 0
        load('jablingOrder.mat');
    case 1
        load('jablingOrder1.mat');
    case 2
        load('jablingOrder2.mat');
    otherwise
        error('Invalid jabling_file_option. Use 0, 1, or 2.');
end

segLen = round(segDur * fs);           % Segment length in samples
nSeg   = floor(size(eegBlock,1) / segLen);
segCell = mat2cell(eegBlock(1:nSeg*segLen , :), ...
    repmat(segLen,nSeg,1), size(eegBlock,2));

% Check for consistency between data and hardcoded trials/stims
nTrial = 10;
if jabling_file_option == 0, nStim = 8; else nStim = 4; end
expectedSegs = nTrial * nStim;
if nSeg < expectedSegs
    warning('Not enough data for all %d expected segments. The data will be truncated.', expectedSegs);
    % We will proceed, but the loops will only run for the available segments.
    % To be more robust, one might resize the data4D matrix based on nSeg.
    % For now, we will just fill what's available and leave the rest as zeros.
end

data4D = zeros(segLen, size(eegBlock, 2), nStim, nTrial);
p = 1; % Index for segCell

for t = 1:nTrial
    for k = 1:nStim
        % Check if we have more segments to process
        if p > nSeg
            break; % Exit inner loop if we run out of segments
        end

        stimID = jablingOrder(t,k);   % which stimulus was played k-th in trial t
        
        % Populate the 4D matrix
        data4D(:,:,stimID,t) = segCell{p};
        
        p = p + 1;
    end
    if p > nSeg
        break; % Exit outer loop if we run out of segments
    end
end
end