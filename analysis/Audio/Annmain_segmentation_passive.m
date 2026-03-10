%main_segmentation_passive
% rootDir   = 'D:\EEG analysis\cleaned_data_andmarker';
% subIDs    = {'S1','S2',};
% setIDs    = {'set1','set2'}; 
% idea ,.. 
% create  database, where 
% each row , each subject 

count=1;

%% 

sub=8;
setno=2;
% load the files both data and marker

%data=T_data_cleaned;
%marker =T_data;
%cd('D:\EEG analysis\eeg_perrand_analysis');
markerRows = find(~isnan(T_data_cleaned.markerInd));   % rows that carry any marker
markerIDs  = T_data_cleaned.markerInd(markerRows); 
markerVal= T_data_cleaned.markerValue(markerRows);

%blocksEEG   = cell(numel(markerRows)/2,1);   % pre-allocate
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
count=count+1;

%% main segmentation - active sets

%% 