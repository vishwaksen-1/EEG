% ---- choose the dataset once ----
%  clear all
%  close all
%  clc
% load tehdata file of corresponding set 
fs=256;

C=data;
% e.g., set1_active_perrand / set1_passive_... / set2_...
dataCol = 4;               % the column inside each subject-row that holds the 4-D array

% 1) Average all trials for each stimulus of a single subject (index subjIdx)
subjIdx = 1;                                   % change to the subject you want
X = C{subjIdx}{dataCol};                       % [T x Ch x S x Tr]
mean_trials_one_subj = mean(X, 4, 'omitnan');  % -> [T x Ch x S]

% 2) Average all trials for each stimulus of ALL subjects
nS = numel(C);
% per-subject trial-averaged data (kept as a cell, one entry per subject)
mean_trials_all_subjects = cell(nS,1);
for s = 1:nS
    Xi = C{s}{dataCol};                            % [T x Ch x S x Tr]
    mean_trials_all_subjects{s} = mean(Xi,4,'omitnan');  % [Time x Ch x Stim]
end

% (optional) grand mean across subjects for each stimulus
[T,Ch,S,~] = size(C{1}{dataCol});
Mstack = NaN(T,Ch,S,nS);
for s = 1:nS
    Mstack(:,:,:,s) = mean_trials_all_subjects{s}; % [T x Ch x S x subj]
end
% for all subjects 
% this averages all subjects 
grand_mean_trials_per_stim = mean(Mstack, 4, 'omitnan'); % -> [T x Ch x S]

% [T x Ch x Stimx Trial x Subj]
A5 = stack_subjects_5D(C, dataCol);  % see local function below
A5_aftr_baselinezeroing= baselinezeroing(A5,fs);
clear A5;
A5=A5_aftr_baselinezeroing;

% 3) Average stimuli 1 & 2, and average all trials for ALL subjects
tmp = mean(A5(:,:,1:2,:,:), 3, 'omitnan');  % average stimuli 1 & 2
tmp = mean(tmp, 4, 'omitnan');              % average over trials
avg_stim12_allsubj = mean(tmp, 5, 'omitnan');  % average over subjects , stim 1 nan 22 
% avg acrioss all trails and all subjects 
% size: [T x Ch]


% 4) Average stimuli 3 & 4, and average all trials for ALL subjects
tmp = mean(A5(:,:,3:4,:,:), 3, 'omitnan');  % average stimuli 3 & 4
tmp = mean(tmp, 4, 'omitnan');              % average over trials
avg_stim34_allsubj = mean(tmp, 5, 'omitnan');  % average over subjects
% size: [T x Ch]

%% as subplot 
for i = 1:14 clf;
    fs = 256;                    % 256'
    idx200=round(0.2*fs);
idx500  = round(0.5*fs);        % 129
idx4100 = round(4.1*fs)+1;        % 1051


subplot(2,1,1);
plot(avg_stim12_allsubj(:,i)); % average across channels
    title(sprintf('Channel %d— Stimuli 1 & 2 (mean trials + subjects)', i));
xlabel('Time');
ylabel('Amplitude');
ax = gca; yL = get(ax,'YLim'); hold on
plot([idx500  idx500 ], yL, '--k', 'LineWidth',1);
plot([idx4100 idx4100], yL, '--k', 'LineWidth',1);
plot([idx200 idx200 ], yL, '--r', 'LineWidth',1);


subplot(2,1,2);
plot(avg_stim34_allsubj(:,i)); % average across channels
title('Average Stimuli 3 & 4 (All Subjects, All Trials)');
xlabel('Time');
ylabel('Amplitude');
ax = gca; yL = get(ax,'YLim'); hold on
plot([idx500  idx500 ], yL, '--k', 'LineWidth',1);
plot([idx4100 idx4100], yL, '--k', 'LineWidth',1); 
plot([idx200  idx200], yL, '--r', 'LineWidth',1);

pause()

end



