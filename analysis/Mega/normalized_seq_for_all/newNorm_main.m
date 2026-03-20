clear;
clc;
f_name = 'passive.mat';
load(f_name);
eeg_final_destination()

stimData=stim12; % stim12
datasetName='stim12';
Tpassnorm.Out12 = newNormalizeStimPerSubject(stimData, datasetName, 1);
stimData=stim34; % stim34
datasetName='stim34';
Tpassnorm.Out34 = newNormalizeStimPerSubject(stimData, datasetName, 1);
% save
save Tpassnorm65 Tpassnorm;

stimData=stim12; % stim12
datasetName='stim12';
Tpassnorm.Out12 = newNormalizeStimPerSubject(stimData, datasetName, 0);
stimData=stim34; % stim34
datasetName='stim34';
Tpassnorm.Out34 = newNormalizeStimPerSubject(stimData, datasetName, 0);
% save 
save Tpassnorm36 Tpassnorm;


%% %%%%%%%%%%%%%%%%%%%%%%%% section 2 active dataset 
clear;
clc;
f_name = 'active.mat';
load(f_name);
eeg_final_destination()

stimData=stim12; % stim12
datasetName='stim12';
Tactnorm.Out12 = newNormalizeStimPerSubject(stimData, datasetName, 1);
stimData=stim34; % stim34
datasetName='stim34';
Tactnorm.Out34 = newNormalizeStimPerSubject(stimData, datasetName, 1);
% save
save Tactnorm65 Tactnorm;

stimData=stim12; % stim12
datasetName='stim12';
Tactnorm.Out12 = newNormalizeStimPerSubject(stimData, datasetName, 0);
stimData=stim34; % stim34
datasetName='stim34';
Tactnorm.Out34 = newNormalizeStimPerSubject(stimData, datasetName, 0);
% save 
save Tactnorm36 Tactnorm;

%% %%%%%%%%%%%%%%%%%%%%%%%% section 3 active_hitNCr dataset 
clear;
clc;
f_name = 'active_hitNCr.mat';
load(f_name);
eeg_final_destination()

stimData=stim12; % stim12
datasetName='stim12';
Tactnorm_hitNCr.Out12 = newNormalizeStimPerSubject(stimData, datasetName, 1);
stimData=stim34; % stim34
datasetName='stim34';
Tactnorm_hitNCr.Out34 = newNormalizeStimPerSubject(stimData, datasetName, 1);
% save
save Tactnorm_hitNCr65 Tactnorm_hitNCr;

stimData=stim12; % stim12
datasetName='stim12';
Tactnorm_hitNCr.Out12 = newNormalizeStimPerSubject(stimData, datasetName, 0);
stimData=stim34; % stim34
datasetName='stim34';
Tactnorm_hitNCr.Out34 = newNormalizeStimPerSubject(stimData, datasetName, 0);
% save 
save Tactnorm_hitNCr36 Tactnorm_hitNCr;

%% %%%%%%%%%%%%%%%%%%%%%%%% section 4 active_faNMiss dataset 
clear;
clc;
f_name = 'active_faNMiss.mat';
load(f_name);
eeg_final_destination()

stimData=stim12; % stim12
datasetName='stim12';
Tactnorm_faNMiss.Out12 = newNormalizeStimPerSubject(stimData, datasetName, 1);
stimData=stim34; % stim34
datasetName='stim34';
Tactnorm_faNMiss.Out34 = newNormalizeStimPerSubject(stimData, datasetName, 1);
% save
save Tactnorm_faNMiss65 Tactnorm_faNMiss;

stimData=stim12; % stim12
datasetName='stim12';
Tactnorm_faNMiss.Out12 = newNormalizeStimPerSubject(stimData, datasetName, 0);
stimData=stim34; % stim34
datasetName='stim34';
Tactnorm_faNMiss.Out34 = newNormalizeStimPerSubject(stimData, datasetName, 0);
% save 
save Tactnorm_faNMiss36 Tactnorm_faNMiss;