%% 
% load `data` for active  or passive
% clear;
% clc;

C=data;
fs=256;

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
A5_aftr_dcOffRm= dcOffsetFull(A5,fs);
clear A5;
A5=A5_aftr_dcOffRm;

%% --- From A5 to seg_12 / seg_34 (no cells used) ---
% A5: [T x Ch x Stim x Tr x Subj]

[T, Ch, S, Tr, Subj] = size(A5); 

% Event window: baseline 0–500 ms -> onset at sample 129; stim length 3.6 s
idx_on   = round(0.5*fs) + 1;                 % 129
L_event  = round(3.6*fs);                      % 922
i0       = idx_on;                             % 129
i1       = min(i0 + L_event - 1, T);          % 1050 (with your data)

% Segment sizes
L12   = round(0.15*fs);                        % 150 ms -> 38
N12   = floor(L_event / L12);                  % 24
L34   = round(0.30*fs)-1;                        % 300 ms -> 77
N34   = floor(L_event / (L34));                  % 12

% Preallocate: [Subj x 2 x Tr x Seg x Ch x Samples]
seg_12 = zeros(Subj, 2, Tr, N12, Ch, L12, 'like', A5);
seg_34 = zeros(Subj, 2, Tr, N34, Ch, L34, 'like', A5);

for s = 1:size(A5,5)
    % Pull event window for (stim 1,2) and (stim 3,4): [L x Ch x 2 x Tr]
    win12 = squeeze(A5(i0:i1, :, [1 2], :, s));
    win34 = squeeze(A5(i0:i1, :, [3 4], :, s));

    % ---- Stim 1&2: non-overlapping 150 ms chunks ----
    for k = 1:N12
        a = (k-1)*L12 + 1;  b = a + L12 - 1;
        % window: [L12 x Ch x 2 x Tr] -> permute to [2 x Tr x Ch x L12]
        block = permute(win12(a:b, :, :, :), [3 4 2 1]);
        % assign: [1 x 2 x Tr x 1 x Ch x L12]
        seg_12(s, :, :, k, :, :) = reshape(block, [1, 2, Tr, 1, Ch, L12]);
    end

    % ---- Stim 3&4: non-overlapping 300 ms chunks ----
    for k = 1:N34
        a = (k-1)*L34 + 1;  b = a + L34 - 1;
        block = permute(win34(a:b, :, :, :), [3 4 2 1]); % [2 x Tr x Ch x L34]
        seg_34(s, :, :, k, :, :) = reshape(block, [1, 2, Tr, 1, Ch, L34]);
    end
end

% (Optional) quick sanity:
% size(seg_12)  % -> [Subj  2  Tr  24  Ch  38]
% size(seg_34)  % -> [Subj  2  Tr  12  Ch  77]


%% 
 [T,~,~,~,~] = size(A5);

idxB = round(1):round(0.5*fs);                               % 0–500 ms -> 1:128
idxS = (round(0.5*fs)+1):min(round(4.1*fs)+1, T);     % 500–4100 ms -> 129:1051
idxO = (idxS(end)+1):T;                                % >4100 ms -> 1052:1664
seg_12 = permute(seg_12, [4 6 5 2 3 1]);
seg_34 = permute(seg_34, [4 6 5 2 3 1]);
token_12 = seg_12;% your 6-D variable if present
token_34 = seg_34;


stim12 = struct( ...
  'baseline',   A5(idxB,:,[1 2],:,:), ... % 0ms    to 500ms
  'whole_stim', A5(idxS,:,[1 2],:,:), ... % 500ms  to 4100ms
  'offset',     A5(idxO,:,[1 2],:,:), ... % 4100ms to 6500ms
  'full_trial', A5(1:T, :,[1,2],:,:), ... % 0ms    to 6500ms
  'token_12',   token_12, ...
  'channels',   ['AF3','F7','F3','FC5','T7','P7','O1','O2', ...
                'P8','T8','FC6','F4','F8','AF4'],...
  'file',       f_name...
  );

stim34 = struct( ...
  'baseline',   A5(idxB,:,[3 4],:,:), ... % 0ms    to 500ms
  'whole_stim', A5(idxS,:,[3 4],:,:), ... % 500ms  to 4100ms
  'offset',     A5(idxO,:,[3 4],:,:), ... % 4100ms to 6500ms
  'full_trial', A5(1:T, :,[3,4],:,:), ... % 0ms    to 6500ms
  'token_34',   token_34, ...
  'channels',   ['AF3','F7','F3','FC5','T7','P7','O1','O2', ...
                'P8','T8','FC6','F4','F8','AF4'],...
  'file',       f_name......
  );
%% 