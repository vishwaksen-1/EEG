%% segmentation files 
% load clean data file and marker file 
% 

function db_pas= segmentation_passive(sub,setno,T_data_cleaned)
%% 
% seperate 8 stimulus based on jabling order , then find resting seperate and also attach a marker also 
markerRows = find(~isnan(T_data_cleaned.markerInd));   % rows that carry any marker
markerIDs  = T_data_cleaned.markerInd(markerRows); 
markerVal= T_data_cleaned.markerValue(markerRows);

blocksEEG   = cell(numel(markerRows)/2,1);   % pre-allocate
blk         = 0;

for k = 1:2:numel(markerRows)
    blk = blk + 1;

    idxStart = markerRows(k);
    idxEnd   = markerRows(k+1);

    blocksEEG{blk}   = T_data_cleaned{idxStart:idxEnd-1 , 3:16};   % grab EEG only
end
fs      = 256;
segDur  = 6.5;   
db_pas{count,1} = ['s' num2str(sub)];
db_pas{count,2} = ['set' num2str(setno)];
db_pas{count,3} = blocksEEG{1};
db_pas{count,4} = segmentBlockAnn(blocksEEG{2}, fs, segDur);   
db_pas{count,5}  = blocksEEG{3};

end