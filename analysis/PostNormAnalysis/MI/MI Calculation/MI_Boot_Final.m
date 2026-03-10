%% MI_Boot_Final.m
addpath ..
%%% Passive
%%
%% Stim 1
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 1.8;
load("../passnorm.mat");

signal = passnorm.Out12.stim1_subTrialNorm;
[passiveStim1_MI, ps1] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('passiveStim1_MI', 'passiveStim1_MI');
save('ps1', 'ps1');

%% Stim 2
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 1.8;
load("../passnorm.mat");

signal = passnorm.Out12.stim2_subTrialNorm;
[passiveStim2_MI, ps2] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('passiveStim2_MI', 'passiveStim2_MI');
save('ps2', 'ps2');

%% Stim 3
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 1.8;
load("../passnorm.mat");

signal = passnorm.Out34.stim1_subTrialNorm;
[passiveStim3_MI, ps3] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('passiveStim3_MI', 'passiveStim3_MI');
save('ps3', 'ps3');
%% Stim 4
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 1.8;
load("../passnorm.mat");

signal = passnorm.Out34.stim2_subTrialNorm;
[passiveStim4_MI, ps4] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('passiveStim4_MI', 'passiveStim4_MI');
save('ps4', 'ps4');

%%
%%% Active
%%
%% Stim 1
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 1.8;
load("../actnorm.mat");

signal = actnorm.Out12.stim1_subTrialNorm;
[activeStim1_MI, as1] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('activeStim1_MI', 'activeStim1_MI');
save('as1', 'as1')

%% Stim 2
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 1.8;
load("../actnorm.mat");

signal = actnorm.Out12.stim2_subTrialNorm;
[activeStim2_MI, as2] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('activeStim2_MI', 'activeStim2_MI');
save('as2', 'as2');

%% Stim 3
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 1.8;
load("../actnorm.mat");

signal = actnorm.Out34.stim1_subTrialNorm;
[activeStim3_MI, as3] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('activeStim3_MI', 'activeStim3_MI');
save('as3', 'as3');

%% Stim 4
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 1.8;
load("../actnorm.mat");

signal = actnorm.Out34.stim2_subTrialNorm;
[activeStim4_MI, as4] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('activeStim4_MI', 'activeStim4_MI');
save('as4', 'as4');

%%
%%% Visual
%%
%% Seg 1
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 2;
load("../datanorm.mat");

signal = datanorm.Out.seg1_subNorm;
[VisSeg1_MI, vs1] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('VisSeg1_MI', 'VisSeg1_MI');
save('vs1', 'vs1');

%% Seg 2
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 2;
load("../datanorm.mat");

signal = datanorm.Out.seg2_subNorm;
[VisSeg2_MI, vs2] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('VisSeg2_MI', 'VisSeg2_MI');
save('vs2', 'vs2');

%% Seg 3
clear; clc;

k = 3;
nBoot = 50;
maxLagSec = 2;
load("../datanorm.mat");

signal = datanorm.Out.seg3_subNorm;
[VisSeg3_MI, vs3] = MI_Calculate(signal, maxLagSec, k, nBoot);
save('VisSeg3_MI', 'VisSeg3_MI');
save('vs3', 'vs3');