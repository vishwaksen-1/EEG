count=1;


%%
sub=1; 
setno=1;

markerRows = find(~isnan(T_data_cleaned.markerInd));   % rows that carry any marker
markerIDs  = T_data_cleaned.markerInd(markerRows); 
markerVal= T_data_cleaned.markerValue(markerRows);
    blocksEEG{1}   = T_data_cleaned{markerRows(1):markerRows(2)-1 , 3:16};   % grab EEG only
    blocksEEG{2}   = T_data_cleaned{markerRows(3):markerRows(end-2)-1 , 3:16};   % grab EEG only
    blocksEEG{3}   = T_data_cleaned{markerRows(end-1)+1:markerRows(end) , 3:16};   % grab EEG only

fs      = 256;
segDur  = 6.5;   
db_act{count,1} = ['s' num2str(sub)];
db_act{count,2} = ['set' num2str(setno)];
db_act{count,3} = blocksEEG{1};
db_act{count,4} = segmentBlockAnn(blocksEEG{2}, fs, segDur);   
db_act{count,5} = blocksEEG{3};
count=count+1;