function flow_results = trace_info_flow(target_corr, bias_corr, varargin)
% TRACE_INFO_FLOW Maps directed information transfer through brain regions.
% This version handles dimension mismatches and filters for physiological lags.
%
% Usage:
%   % For Task Flow:
%   task_flow = trace_info_flow(data_corr, bias_corr, 'mode', 'task');
%
%   % For Baseline Flow:
%   base_flow = trace_info_flow(base_corr, bias_corr, 'mode', 'baseline');
%
% Inputs:
%   target_corr : Struct with .mean, .std, .lags (either Data or Baseline)
%   bias_corr   : Struct with .mean, .std, .lags (the larger bias dataset)
%
% Parameters:
%   'mode'            : 'task' or 'baseline' (affects logging/logic)
%   'corr_thresh'     : Magnitude threshold for "valid" flow (default: 0.1)
%   'max_depth'       : Maximum chain length (default: 7)
%   'min_lag_samples' : Minimum samples for a "hop" (default: 10)
%   'use_autocorr'    : Start flow from t=0 peak of region (default: true)
%   'alpha'           : Significance level for CI (default: 0.05, i.e., 1.96 * std)

    %% 1. Input Parsing & Setup
    p = inputParser;
    addParameter(p, 'mode', 'task');
    addParameter(p, 'corr_thresh', 0.1);
    addParameter(p, 'max_depth', 7);
    addParameter(p, 'min_lag_samples', 10); % New parameterlll
    addParameter(p, 'use_autocorr', true);
    addParameter(p, 'alpha', 0.05);
    parse(p, varargin{:});
    
    cfg = p.Results;
    z_score = 1.96; % For 95% CI
    Fs = 256;      % Hardcoded based on project specs
    min_lag_sec = cfg.min_lag_samples / Fs;
    
    region_labels = target_corr.params.region_labels;
    nReg = numel(region_labels);
    target_lags = target_corr.lags;
    nTargetSamples = numel(target_lags);
    
    fprintf('\n>>> INITIALIZING INFO FLOW MAPPER [%s Mode] <<<\n', upper(cfg.mode));
    fprintf('Target Samples: %d | Threshold: %.2f | Min Lag: %.3fs (%d samples)\n', ...
            nTargetSamples, cfg.corr_thresh, min_lag_sec, cfg.min_lag_samples);
    
    %% 2. Align Bias to Target
    nBiasSamples = numel(bias_corr.lags);
    
    if nBiasSamples < nTargetSamples
        error('Bias signal (%d) is shorter than Target signal (%d). Cannot align.', ...
            nBiasSamples, nTargetSamples);
    elseif nBiasSamples > nTargetSamples
        startIdx = floor((nBiasSamples - nTargetSamples)/2) + 1;
        endIdx   = startIdx + nTargetSamples - 1;
        
        b_mu_aligned = bias_corr.mean(:, :, startIdx:endIdx);
        b_sd_aligned = bias_corr.std(:, :, startIdx:endIdx);
        fprintf('Bias aligned by cropping central %d samples.\n', nTargetSamples);
    else
        b_mu_aligned = bias_corr.mean;
        b_sd_aligned = bias_corr.std;
    end

    %% 3. Adjacency Matrix Construction
    adj_list = cell(nReg, 1);
    
    for r1 = 1:nReg
        for r2 = 1:nReg
            if r1 == r2, continue; end
            
            d_mu = squeeze(target_corr.mean(r1, r2, :));
            d_sd = squeeze(target_corr.std(r1, r2, :));
            
            b_mu = squeeze(b_mu_aligned(r1, r2, :));
            b_sd = squeeze(b_sd_aligned(r1, r2, :));
            
            % --- SIGNIFICANCE CRITERIA ---
            % 1. Data CI does not contain 0
            sig_vs_zero = (abs(d_mu) - z_score * d_sd) > 0;
            
            % 2. Data CI does not overlap Bias CI
            sig_vs_bias = (d_mu - z_score*d_sd > b_mu + z_score*b_sd) | ...
                          (d_mu + z_score*d_sd < b_mu - z_score*b_sd);
            
            % 3. Magnitude threshold
            over_thresh = abs(d_mu) >= cfg.corr_thresh;
            
            % 4. Directed Flow: Positive Lags AND >= min_lag_sec
            valid_idx = sig_vs_zero & sig_vs_bias & over_thresh & (target_lags' >= min_lag_sec);
            
            if any(valid_idx)
                % Find strongest peak in valid range
                [max_val, peak_idx] = max(abs(d_mu .* valid_idx));
                if max_val >= cfg.corr_thresh
                    actual_corr = d_mu(peak_idx);
                    peak_lag = target_lags(peak_idx);
                    adj_list{r1} = [adj_list{r1}; r2, actual_corr, peak_lag];
                end
            end
        end
    end

    %% 4. Recursive Path Finding (DFS)
    all_paths = {};
    for startNode = 1:nReg
        init_path = struct('nodes', startNode, 'corrs', [], 'lags', 0);
        found = find_paths_recursive(startNode, init_path, adj_list, cfg.max_depth, 0);
        all_paths = [all_paths; found];
    end

    %% 5. Formatting Results
    fprintf('\n======================================================\n');
    fprintf('DETECTED %s FLOW CHAINS\n', upper(cfg.mode));
    fprintf('======================================================\n');
    
    unique_paths_count = 0;
    for i = 1:numel(all_paths)
        p = all_paths{i};
        if numel(p.nodes) < 2, continue; end 
        unique_paths_count = unique_paths_count + 1;
        
        str = "";
        for n = 1:numel(p.nodes)
            name = region_labels{p.nodes(n)};
            if n == 1
                str = sprintf('[%s]', name);
            else
                c = p.corrs(n-1);
                l = p.lags(n);
                str = sprintf('%s --(%.2f @ +%.3fs)--> [%s]', str, c, l, name);
            end
        end
        fprintf('%s\n', str);
    end
    
    if unique_paths_count == 0, fprintf('No significant flow chains detected with current lag constraints.\n'); end
    
    flow_results.paths = all_paths;
    flow_results.adj_list = adj_list;
    fprintf('\n✅ %s analysis complete.\n', cfg.mode);
end

function paths = find_paths_recursive(currNode, path_so_far, adj_list, max_depth, current_depth)
    if current_depth >= max_depth || isempty(adj_list{currNode})
        paths = {path_so_far};
        return;
    end
    
    paths = {};
    edges = adj_list{currNode};
    for i = 1:size(edges, 1)
        nextNode = edges(i, 1);
        % Cycle prevention
        if ismember(nextNode, path_so_far.nodes), continue; end
        
        new_path = path_so_far;
        new_path.nodes = [new_path.nodes, nextNode];
        new_path.corrs = [new_path.corrs, edges(i, 2)];
        new_path.lags  = [new_path.lags, edges(i, 3)]; 
        
        child_paths = find_paths_recursive(nextNode, new_path, adj_list, max_depth, current_depth + 1);
        paths = [paths; child_paths];
    end
    if isempty(paths), paths = {path_so_far}; end
end