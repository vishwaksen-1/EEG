function data4D = segmentBlock(eegBlock, fs, segDur)
% eegBlock  — [N × 14] double (samples × channels)

% segDur    —here 6.5)
%
% segCell   — {nSeg × 1} cell array; each cell is [segLen × 14]
load('jablingOrder_set1.mat');
jablingOrder = jablingOrder_set1;
segLen  = round(segDur * fs);           % 6.5 s = 1664 samples
nSeg    = floor(size(eegBlock,1) / segLen);
segCell = mat2cell(eegBlock(1:nSeg*segLen , :), ...
    repmat(segLen,nSeg,1), size(eegBlock,2));
%                order=jablingOrder';
% stimcode=order(:);
% data4D = zeros(segLen, 14, 8, 10);

% for no_stims=1:8
%             index_stimlines=find(stimcode==no_stims);
%            for ind=1:length(index_stimlines)
%                 yyy{ind}= segCell{index_stimlines(ind)};
%            end
% end
p=1;
nTrial=10;
nStim=8;
for t = 1:nTrial
    for k = 1:nStim
        stimID = jablingOrder(t,k);   % which stimulus was played k-th in trial t
        %   cellGrid{t, stimID} = segCell{p};
        
        data4D(:,:,stimID,t) = segCell{p};
        
        p = p + 1;
    end
end
end