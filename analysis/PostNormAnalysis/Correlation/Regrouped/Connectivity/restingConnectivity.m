%% BOOTSTRAP RESTING STATE FLOW
% Handles the n x 2 cell structure for Eyes Open/Closed resting states.

NBOOT = 200;
NSUBS = 8;
CORR_THRESH = 0.15;
FS = 256;
MAX_DEPTH = 5;

% Default Emotiv EPOC X indices (3-16 are the 14 channels)
chanIdx = 3:16; 
regions = {[1,3,4], [11,12,14], [5], [10], [6], [9], [7], [8]}; % Relative to 1:14
regLabels = {'L_Frontal','R_Frontal','L_Temporal','R_Temporal','L_Parietal','R_Parietal','L_Occipital','R_Occipital'};

nSubTotal = size(all_data_cell, 1);
restingDict = struct('eyes_closed', struct(), 'eyes_open', struct());

fprintf('Starting Resting State Bootstrap...\n');

for b = 1:NBOOT
    idxSubs = randsample(nSubTotal, NSUBS, true);
    
    for state = 1:2 % 1: Closed, 2: Open
        stateName = iff(state==1, 'eyes_closed', 'eyes_open');
        sum_sig = zeros(14, 2560); % Example length
        
        for sIdx = 1:NSUBS
            % Data is in all_data_cell{sub, 2}{1, state}
            raw = all_data_cell{idxSubs(sIdx), 2}{state}; 
            chData = raw(:, chanIdx)'; % 14 x samples
            
            % Normalize: Z-score for resting state (no trials for RMS)
            chData = zscore(chData, 0, 2);
            
            % Accumulate (trimming to match if needed)
            sum_sig = sum_sig + chData(:, 1:size(sum_sig,2));
        end
        
        avg_sig = sum_sig / NSUBS;
        
        % Region mapping
        reg_sig = zeros(8, size(avg_sig,2));
        for r=1:8, reg_sig(r,:) = mean(avg_sig(regions{r},:), 1); end
        
        % Trace
        adj = compute_simple_adj(reg_sig, FS, CORR_THRESH);
        paths = trace_simple(adj, regLabels, MAX_DEPTH);
        restingDict.(stateName) = update_dict(restingDict.(stateName), paths, 0.02, 1);
    end
end

save('resting_bootstrap_results.mat', 'restingDict');

function val = iff(cond, v1, v2), if cond, val = v1; else, val = v2; end, end
% (Other helpers compute_simple_adj, trace_simple, update_dict same as above)

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