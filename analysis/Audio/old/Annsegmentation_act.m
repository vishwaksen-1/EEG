%% segmentation files
% load clean data file and marker file
%

function db_act = segmentation_act(sub,setno,T_data_cleaned)
%%
% seperate 8 stimulus based on jabling order , then find resting seperate and also attach a marker also
markerRows = find(~isnan(T_data_cleaned.markerInd));   % rows that carry any marker
markerIDs  = T_data_cleaned.markerInd(markerRows);
markerVal= T_data_cleaned.markerValue(markerRows);
    blocksEEG{1}   = T_data_cleaned{markerRows(1):markerRows(2)-1 , 3:16};   % grab EEG only
    blocksEEG{2}   = T_data_cleaned{markerRows(3):markerRows(end-2)-1 , 3:16};   % grab EEG only
    blocksEEG{3}   = T_data_cleaned{markerRows(end-1)+1:markerRows(end) , 3:16};   % grab EEG only

fs      = 256;
segDur  = 6.5;
db_act{sub,1} = ['s' num2str(sub)];
db_act{sub,2} = ['set' num2str(setno)];
db_act{sub,3} = blocksEEG{1};
db_act{sub,4} = segmentBlockAnn(blocksEEG{2}, fs, segDur);
db_act{sub,5}  = blocksEEG{3};

end
