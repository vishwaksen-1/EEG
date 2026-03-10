%% BOOTSTRAP EXPERIMENT FLOW
% This script implements trial-wise RMS normalization, stimulus grouping,
% and bootstrapped connectivity frequency mapping.

% --- CONFIGURATION & MACROS ---
NBOOT = 200;            % Number of bootstrap iterations
NSUBS = 8;              % Number of subjects to resample per boot
CORR_THRESH = 0.15;     % Macro for significance
TIME_TOLERANCE = 0.02;  % 20ms tolerance for "same" connection
MAX_DEPTH = 5;
COMPARISON_TYPE = 0;    % 0: Sep, 1: (1,2) (3,4), 2: (1,3) (2,4)
FS = 256;
BASELINE_SAMPLES = round(0.5 * FS); % 0.5s for RMS calc

% --- CHANNEL & REGION SETUP ---
chanNames = {'AF3','F7','F3','FC5','T7','P7','O1','O2','P8','T8','FC6','F4','F8','AF4'};
regions = {[1,3,4], [11,12,14], [5], [10], [6], [9], [7], [8]};
regLabels = {'L_Frontal','R_Frontal','L_Temporal','R_Temporal','L_Parietal','R_Parietal','L_Occipital','R_Occipital'};

named_data = final_act;

nSubTotal = numel(named_data);
connDict = struct(); % To store frequency of chains

fprintf('Starting Experiment Bootstrap (CompType: %d)...\n', COMPARISON_TYPE);

for b = 1:NBOOT
    % 1. Resample Subjects
    idxSubs = randsample(nSubTotal, NSUBS, true);
    
    % 2. Grouping & Normalizing
    % Logic to handle comparison types
    if COMPARISON_TYPE == 0, nG = 4; else, nG = 2; end
    
    for g = 1:nG
        group_data_sum = zeros(14, 1664); % Assuming 1664 samples
        
        for sIdx = 1:NSUBS
            sData = named_data{idxSubs(sIdx)}{4}; % samples x 14 x stim x trials
            
            % Select stims based on COMPARISON_TYPE
            if COMPARISON_TYPE == 0, sIndices = g;
            elseif COMPARISON_TYPE == 1, sIndices = (g==1)*[1,2] + (g==2)*[3,4];
            else, sIndices = (g==1)*[1,3] + (g==2)*[2,4];
            end
            
            % Average across selected stims and all trials
            stimAvg = mean(sData(:,:,sIndices,:), 3); % samples x 14 x 1 x trials
            trialAvg = squeeze(mean(stimAvg, 4));     % samples x 14
            
            % --- RMS NORMALIZATION (Step 5.d) ---
            % We need trial-wise baseline RMS
            ws_trials = sData(:,:,sIndices(1),:); % simplified to first stim in group for RMS
            [nT, nC, ~, nTr] = size(ws_trials);
            trialwise_rms = zeros(nC, nTr);
            for tr = 1:nTr
                baseline_win = ws_trials(1:BASELINE_SAMPLES, :, 1, tr);
                trialwise_rms(:, tr) = rms(baseline_win, 1, 'omitnan')';
            end
            baseline_rms_avg = mean(trialwise_rms, 2, 'omitnan');
            norm_sub = trialAvg ./ baseline_rms_avg'; % Normalizing the avg waveform
            
            group_data_sum = group_data_sum + norm_sub'; % channels x samples
        end
        
        % Final Group Mean Signal
        group_signal = group_data_sum / NSUBS;
        
        % 3. Region Regrouping
        reg_signal = zeros(8, size(group_signal, 2));
        for r = 1:8
            reg_signal(r, :) = mean(group_signal(regions{r}, :), 1);
        end
        
        % 4. Correlation & Info Tracing (Using your updated logic)
        % Note: Using a simplified internal call to xcorr logic here
        adj = compute_simple_adj(reg_signal, FS, CORR_THRESH);
        
        % Trace and Update Dict
        paths = trace_simple(adj, regLabels, MAX_DEPTH);
        connDict = update_dict(connDict, paths, TIME_TOLERANCE, g);
    end
    
    if mod(b, 10) == 0, fprintf('Boot %d/%d...\n', b, NBOOT); end
end

save('exp_bootstrap_results.mat', 'connDict');
fprintf('Experiment Bootstrap Complete.\n');

% --- HELPER FUNCTIONS ---
function adj = compute_simple_adj(sig, fs, thresh)
    nReg = size(sig,1);
    adj = cell(nReg,1);
    maxL = round(0.5 * fs); 
    for i=1:nReg
        for j=1:nReg
            if i==j, continue; end
            [c, lags] = xcorr(sig(i,:), sig(j,:), maxL, 'coeff');
            % Only look at positive lags > 10 samples
            mask = lags > 10;
            [mv, mi] = max(c(mask));
            if mv > thresh
                actual_lag = lags(find(mask, 1, 'first') + mi - 1) / fs;
                adj{i} = [adj{i}; j, mv, actual_lag];
            end
        end
    end
end

function dict = update_dict(dict, paths, tol, group)
    fld = sprintf('group_%d', group);
    if ~isfield(dict, fld), dict.(fld) = struct(); end
    for i=1:numel(paths)
        p = paths{i}; if numel(p.nodes) < 2, continue; end
        key = strjoin(cellstr(num2str(p.nodes')), '->');
        % Simplify key by rounding lags for tolerance
        lagKey = sprintf('_L%s', strjoin(cellstr(num2str(round(p.lags/tol)*tol)), '_'));
        fullKey = [key lagKey];
        if isfield(dict.(fld), fullKey)
            dict.(fld).(fullKey).freq = dict.(fld).(fullKey).freq + 1;
        else
            dict.(fld).(fullKey).freq = 1;
            dict.(fld).(fullKey).path = p;
        end
    end
end

function paths = trace_simple(adj, labels, depth)
    paths = {};
    for s=1:numel(labels)
        p.nodes = s; p.lags = [];
        found = recurse(s, p, adj, depth);
        paths = [paths; found];
    end
end

function res = recurse(curr, p, adj, depth)
    if numel(p.nodes) >= depth || isempty(adj{curr})
        res = {p}; return;
    end
    res = {}; edges = adj{curr};
    for i=1:size(edges,1)
        nxt = edges(i,1); if ismember(nxt, p.nodes), continue; end
        np = p; np.nodes = [p.nodes, nxt]; np.lags = [p.lags, edges(i,3)];
        res = [res; recurse(nxt, np, adj, depth)];
    end
    if isempty(res), res = {p}; end
end