% 
clear
clc
close all
load('passnorm.mat');
PSD_Spect_Struct_passive = computePSD_Spectrogram_AllStims(passnorm);
 load('actnorm.mat')
 PSD_Spect_Struct_actnorm = computePSD_Spectrogram_AllStims(actnorm);


load('actnorm_hitNcr.mat')
PSD_Spect_Struct_actnorm_hitNcr= computePSD_Spectrogram_AllStims(actnorm_hitNcr);

 load('actnorm_faNmiss.mat')
PSD_Spect_Struct_actnorm_faNmiss = computePSD_Spectrogram_AllStims(actnorm_faNmiss);