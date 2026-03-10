load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/activeCorrRegion_results.mat")
active = results;
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/activeCorrBaselineRegion.mat")
activeBaseline = baseline;
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/bias_corr_results_actnorm_regionwise.mat")
activeBias = results;
clear results
clear baseline
%%
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/passiveCorrRegion_results.mat")
passive = results; clear results;
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/passiveCorrBaselineRegion.mat")
passiveBaseline = baseline; clear baseline;
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/bias_corr_results_passnorm_regionwise.mat")
passiveBias = results; clear results;

%%
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/visualCorrRegion_results.mat")
visual = results;
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/bias_corr_results_datanorm_regionwise.mat")
visualBias = results;
clear results


%%
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/pass-actCorrRegion_results.mat")
pass_Act = results;
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/bias_corr_results_pass-act_regionwise.mat")
pass_ActBias = results;
clear results;

%%
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/restingCorrRegion_results.mat")
rest = results;
load("/MATLAB Drive/EEG/Utils/analysis/PostNormAnalysis/Correlation/regrouped/bias_corr_results_resting_regionwise.mat")
restingBias = results;