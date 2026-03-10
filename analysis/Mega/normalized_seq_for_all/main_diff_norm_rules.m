%%% logic updated - ann - 231025
% load teh required file in eeg_final_destination 
% forst run final_act.. gete the baseliens ad nroamlisation across all
% trials freom that.. then use that roto normalise treh correct and
% incorrect daatsets trials spoeratel;y 



% 
% eeg_final_destination()
% change stimdata and datasetname 
% stimData=stim12; % stim34
% datasetName='stim12';
% 
% %[final_pass_norm.stim1_norm, final_pass_norm.stim2_norm] = plotNormalizedStim(stimData, datasetName);
% 
% 
% %.Out12 = normalizeStimPerSubject(stimData, datasetName);
% actnorm.Out12 = ann_normalizeStimPerSubject2(stimData, datasetName);
% % actnorm.Out12.baselineRef- this varibae as teh baseliens stored ..
% stimData=stim34; % stim34
% datasetName='stim34';
% actnorm.Out34 = ann_normalizeStimPerSubject2(stimData, datasetName);

        % %%%%%% now act norm has three condition.. raw nrmalised
                % noramlised to baseline
            % nomralised to 900ms 
%% now load load('final_t_act_faNmiss.mat') in teh eeg_final_destination 

% eeg_final_destination()
% change stimdata and datasetname 
% stimData=stim12; % stim34
% datasetName='stim12';
% actnorm_faNmiss.Out12 = normalizeStimPerSubject(stimData, datasetName);
% stimData=stim34; % stim34
% datasetName='stim34';
% actnorm_faNmiss.Out34 = normalizeStimPerSubject(stimData, datasetName);
% 
% save actnorm_faNmiss_6_5 actnorm_faNmiss

%% %% now load load('final_t_act_hitNcr.mat') in teh eeg_final_destination 

% eeg_final_destination()
% change stimdata and datasetname 
% stimData=stim12; % stim34
% datasetName='stim12';
% actnorm_hitNcr.Out12 = normalizeStimPerSubject(stimData, datasetName);
% stimData=stim34; % stim34
% datasetName='stim34';
% actnorm_hitNcr.Out34 = normalizeStimPerSubject(stimData, datasetName);

stimData=stim12; % stim34
datasetName='stim12';
passnorm.Out12 = normalizeStimPerSubject(stimData, datasetName);
stimData=stim34; % stim34
datasetName='stim34';
passnorm.Out34 = normalizeStimPerSubject(stimData, datasetName);
save passnorm_6_5 passnorm
% 
% %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% for passsive dataset s%%%%%%%%%%%%%%%%%
% 
% 
% eeg_final_destination()
% 
% stimData=stim12; % stim34
% datasetName='stim12';
% 
% %[final_pass_norm.stim1_norm, final_pass_norm.stim2_norm] = plotNormalizedStim(stimData, datasetName);
% 
% 
% %.Out12 = normalizeStimPerSubject(stimData, datasetName);
% passnorm.Out12 = ann_normalizeStimPerSubject2(stimData, datasetName);
% close all
% 
% stimData=stim34; % stim34
% datasetName='stim34';
% 
% %[final_pass_norm.stim3_norm, final_pass_norm.stim4_norm] = plotNormalizedStim(stimData, datasetName);
% %passnorm.Out34 = normalizeStimPerSubject(stimData, datasetName);
% passnorm.Out34 = ann_normalizeStimPerSubject2(stimData, datasetName);
% 
% % save commands 
% save passnorm passnorm;
% close all

