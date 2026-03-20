clear;
clc;
f_name = 'passive.mat';
load(f_name);
eeg_final_destination()

stimData=stim12; % stim12
datasetName='stim12';
passnorm.Out12 = normalizeStimPerSubject(stimData, datasetName, 1);
stimData=stim34; % stim34
datasetName='stim34';
passnorm.Out34 = normalizeStimPerSubject(stimData, datasetName, 1);
% save
save passnorm65 passnorm;

stimData=stim12; % stim12
datasetName='stim12';
passnorm.Out12 = normalizeStimPerSubject(stimData, datasetName, 0);
stimData=stim34; % stim34
datasetName='stim34';
passnorm.Out34 = normalizeStimPerSubject(stimData, datasetName, 0);
% save
save passnorm36 passnorm;


%% %%%%%%%%%%%%%%%%%%%%%%%% section 2 active dataset
clear;
clc;
f_name = 'active.mat';
load(f_name);
eeg_final_destination()

stimData=stim12; % stim12
datasetName='stim12';
actnorm.Out12 = normalizeStimPerSubject(stimData, datasetName, 1);
stimData=stim34; % stim34
datasetName='stim34';
actnorm.Out34 = normalizeStimPerSubject(stimData, datasetName, 1);
% save
save actnorm65 actnorm;

stimData=stim12; % stim12
datasetName='stim12';
actnorm.Out12 = normalizeStimPerSubject(stimData, datasetName, 0);
stimData=stim34; % stim34
datasetName='stim34';
actnorm.Out34 = normalizeStimPerSubject(stimData, datasetName, 0);
% save
save actnorm36 actnorm;

%% %%%%%%%%%%%%%%%%%%%%%%%% section 3 active_hitNCr dataset
clear;
clc;
f_name = 'active_hitNCr.mat';
load(f_name);
eeg_final_destination()

stimData=stim12; % stim12
datasetName='stim12';
actnorm_hitNCr.Out12 = normalizeStimPerSubject(stimData, datasetName, 1);
stimData=stim34; % stim34
datasetName='stim34';
actnorm_hitNCr.Out34 = normalizeStimPerSubject(stimData, datasetName, 1);
% save
save actnorm_hitNCr65 actnorm_hitNCr;

stimData=stim12; % stim12
datasetName='stim12';
actnorm_hitNCr.Out12 = normalizeStimPerSubject(stimData, datasetName, 0);
stimData=stim34; % stim34
datasetName='stim34';
actnorm_hitNCr.Out34 = normalizeStimPerSubject(stimData, datasetName, 0);
% save
save actnorm_hitNCr36 actnorm_hitNCr;

%% %%%%%%%%%%%%%%%%%%%%%%%% section 4 active_faNMiss dataset
clear;
clc;
f_name = 'active_faNMiss.mat';
load(f_name);
eeg_final_destination()

stimData=stim12; % stim12
datasetName='stim12';
actnorm_faNMiss.Out12 = normalizeStimPerSubject(stimData, datasetName, 1);
stimData=stim34; % stim34
datasetName='stim34';
actnorm_faNMiss.Out34 = normalizeStimPerSubject(stimData, datasetName, 1);
% save
save actnorm_faNMiss65 actnorm_faNMiss;

stimData=stim12; % stim12
datasetName='stim12';
actnorm_faNMiss.Out12 = normalizeStimPerSubject(stimData, datasetName, 0);
stimData=stim34; % stim34
datasetName='stim34';
actnorm_faNMiss.Out34 = normalizeStimPerSubject(stimData, datasetName, 0);
% save
save actnorm_faNMiss36 actnorm_faNMiss;
