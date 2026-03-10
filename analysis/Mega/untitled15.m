% run eeg_final dest with required dadaset 
% tehn avg across , trials, sub for one stim 
xx=squeeze(mean(stim12.whole_stim(:,:,1,:,:),[4,5]));

%corr - heatmap
[rcorr, pval] = corrcoef(xx);
channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2','P6','T8','FC6','F4','F8','AF4'};
figure;
h = heatmap(channels, channels, rcorr);
h.CellLabelFormat = '%.2f';
title('EEG Channel Correlation Heatmap');
% heatmap p-values
figure;
p = heatmap(channels, channels, pval);
p.CellLabelFormat = '%.4f';
title('EEG Channel p-val Heatmap');

%% done till set1-pass-stim1