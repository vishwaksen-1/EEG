load ../actnorm65.mat
load ../passnorm65.mat
load ../actnorm_faNMiss65.mat
load ../actnorm_hitNCr65.mat

addpath ../

load ../passive.mat
f_name = 'passive';
eeg_final_destination()
pass12 = stim12;
pass34 = stim34;

load ../active.mat
f_name = 'active';
eeg_final_destination()
act12 = stim12;
act34 = stim34;