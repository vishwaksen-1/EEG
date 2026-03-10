% runing script
clear 
clc
%% load
load actnormBaseline.mat
act_baseline = baseline_results;

load passnormBaseline.mat
pass_baseline = baseline_results;
clear baseline_results

load actnormCorrAcrr_results.mat
act_corr = results;

load datanormCorrAcrr_results.mat
vis_corr = results;

load passnormCorrAcrr_results.mat
pass_corr = results;
clear results;

%% Plotting -- Autocorr

%       Channel Chan
%  per Act       per Pass
% aper Act      aper Pass
plot_autocorr_periodic_ap(act_corr, pass_corr, act_baseline, pass_baseline);


%       Active / Passive 
%  per Chan       per Chan'
% aper Chan      aper Chan'
plot_autocorr_periodic_vs_aperiodic(act_corr, act_baseline);


%         Out Stim 
%   Act Chan      Act Chan'
%  Pass Chan     Pass Chan'
plot_autocorr_results_ap(act_corr, pass_corr, act_baseline, pass_baseline);


%% Plotting -- Crosscorr

%       Channel Chan
%  per           aper 
%  per Baseline  aper Baseline
plot_crosscorr_periodic_vs_aperiodic(act_corr, act_baseline, 1, 0); % (~,~,~,1) for pre-experiment Baseline


%         Out Stim
%  act           pass
%  act Baseline  pass Baseline
plot_crosscorr_results_ap(act_corr, pass_corr, act_baseline, pass_baseline, 0);


%% Plotting Visual 
plot_autocorr_results_visual(vis_corr);