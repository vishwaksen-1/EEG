% load teh data mat
% clear all;
% clc


 %% 
fs=256;

C=data;
% e.g., set1_active_perrand / set1_passive_... / set2_...
dataCol = 4;               % the column inside each subject-row that holds the 4-D array

% [T x Ch x Stimx Trial x Subj]
A5 = stack_subjects_5D(C, dataCol);  % see local function below
A5_aftr_baselinezeroing= baselinezeroing(A5,fs);
clear A5;
A5=A5_aftr_baselinezeroing;

close all;

plot_shifted_channels(A5, fs)


