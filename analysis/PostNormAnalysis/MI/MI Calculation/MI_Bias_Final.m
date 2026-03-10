%% MI_Bias_Final.m
addpath ..
%%% Passive
%%
%% Stim 1
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 1.8;
load("../passnorm.mat");
load('ps1.mat');

signal = passnorm.Out12.stim1_subTrialNorm;
passiveStim1_Bias = MI_EstimateBias(signal, ps1, maxLagSec, k, nBoot);
save('passiveStim1_Bias', 'passiveStim1_Bias');

%% Stim 2
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 1.8;
load("../passnorm.mat");
load('ps2.mat')

signal = passnorm.Out12.stim2_subTrialNorm;
passiveStim2_Bias = MI_EstimateBias(signal, ps2, maxLagSec, k, nBoot);
save('passiveStim2_Bias', 'passiveStim2_Bias');

%% Stim 3
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 1.8;
load("../passnorm.mat");
load('ps3.mat');

signal = passnorm.Out34.stim1_subTrialNorm;
passiveStim3_Bias = MI_EstimateBias(signal, ps3, maxLagSec, k, nBoot);
save('passiveStim3_Bias', 'passiveStim3_Bias');

%% Stim 4
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 1.8;
load("../passnorm.mat");
load("ps4.mat");

signal = passnorm.Out34.stim2_subTrialNorm;
passiveStim4_Bias = MI_EstimateBias(signal, ps4, maxLagSec, k, nBoot);
save('passiveStim4_Bias', 'passiveStim4_Bias');

%%
%%% Active
%%
%% Stim 1
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 1.8;
load("../actnorm.mat");
load('as1.mat');
signal = actnorm.Out12.stim1_subTrialNorm;
activeStim1_Bias = MI_EstimateBias(signal, as1, maxLagSec, k, nBoot);
save('activeStim1_Bias', 'activeStim1_Bias');

%% Stim 2
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 1.8;
load("../actnorm.mat");
load('as2.mat');
signal = actnorm.Out12.stim2_subTrialNorm;
activeStim2_Bias = MI_EstimateBias(signal, as2, maxLagSec, k, nBoot);
save('activeStim2_Bias', 'activeStim2_Bias');

%% Stim 3
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 1.8;
load("../actnorm.mat");
load('as3.mat')

signal = actnorm.Out34.stim1_subTrialNorm;
activeStim3_Bias = MI_EstimateBias(signal, as3, maxLagSec, k, nBoot);
save('activeStim3_Bias', 'activeStim3_Bias');

%% Stim 4
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 1.8;
load("../actnorm.mat");
load('as4.mat');

signal = actnorm.Out34.stim2_subTrialNorm;
activeStim4_Bias = MI_EstimateBias(signal, as4, maxLagSec, k, nBoot);
save('activeStim4_Bias', 'activeStim4_Bias');

%%
%%% Visual
%%
%% Seg 1
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 2;
load("../datanorm.mat");
load('vs1.mat');

signal = datanorm.Out.seg1_subNorm;
VisSeg1_Bias = MI_EstimateBias(signal, vs1, maxLagSec, k, nBoot);
save('VisSeg1_Bias', 'VisSeg1_Bias');

%% Seg 2
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 2;
load("../datanorm.mat");
load('vs2.mat');

signal = datanorm.Out.seg2_subNorm;
VisSeg2_Bias = MI_EstimateBias(signal, vs2, maxLagSec, k, nBoot);
save('VisSeg2_Bias', 'VisSeg2_Bias');

%% Seg 3
clear; clc;

k = 3;
nBoot = 20;
maxLagSec = 2;
load("../datanorm.mat");
load('vs3.mat');

signal = datanorm.Out.seg3_subNorm;
VisSeg3_Bias  = MI_EstimateBias(signal, vs3, maxLagSec, k, nBoot);
save('VisSeg3_Bias', 'VisSeg3_Bias');
