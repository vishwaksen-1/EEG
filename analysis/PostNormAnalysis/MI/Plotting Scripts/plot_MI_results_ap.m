function plot_MI_results_ap(active_res, passive_res)
% plot_MI_results_ap - Compare Active vs Passive MI
%
% Usage:
%   plot_MI_results_ap(active_results, passive_results)
%
% Logic:
%   1. Matches stim fields (stim1, stim2...).
%   2. Computes Median/CI for both conditions.
%   3. Plots side-by-side subplots.

    outNames = fieldnames(active_res);

    for o = 1:numel(outNames)
        outName = outNames{o};
        
        subFields = fieldnames(active_res.(outName));
        dataFields = subFields(contains(subFields, 'stim'));
        dataFields = dataFields(~contains(dataFields, 'raw'));
        
        % Labels
        if isfield(active_res.(outName), 'regionLabels')
            regLabels = active_res.(outName).regionLabels;
        elseif isfield(active_res.(outName), 'region_labels')
             regLabels = active_res.(outName).region_labels;
        else
             tempDat = active_res.(outName).(dataFields{1}).vals;
             nReg = size(tempDat, 2);
             regLabels = arrayfun(@(x) sprintf('Reg%d', x), 1:nReg, 'UniformOutput', false);
        end
        nReg = length(regLabels);

        for s = 1:numel(dataFields)
            fName = dataFields{s};
            
            % --- Extract & Stats (Active) ---
            vals_A = active_res.(outName).(fName).vals;
            lags_A = get_lags_vector(active_res.(outName).(fName).lags);
            
            med_A = squeeze(median(vals_A, 1));
            lo_A  = squeeze(prctile(vals_A, 2.5, 1));
            hi_A  = squeeze(prctile(vals_A, 97.5, 1));
            
            % --- Extract & Stats (Passive) ---
            if isfield(passive_res.(outName), fName)
                vals_P = passive_res.(outName).(fName).vals;
                
                med_P = squeeze(median(vals_P, 1));
                lo_P  = squeeze(prctile(vals_P, 2.5, 1));
                hi_P  = squeeze(prctile(vals_P, 97.5, 1));
            else
                warning('Passive missing for %s %s', outName, fName);
                continue;
            end

            % --- Plotting Loop (Per Ref Region) ---
            for i = 1:nReg
                figure('Color','w', 'Position', [100 100 1000 400]);

                % Active Plot
                subplot(1,2,1);
                plot_masked_MI(med_A, lo_A, hi_A, i, lags_A, nReg, regLabels, 'Active');

                % Passive Plot
                subplot(1,2,2);
                plot_masked_MI(med_P, lo_P, hi_P, i, lags_A, nReg, regLabels, 'Passive');

                sgtitle(sprintf('%s — %s\nRef: %s', outName, fName, regLabels{i}), 'Interpreter','none');
                fprintf('Showing %s... press key.\n', regLabels{i});
                pause;
            end
            close all;
        end
    end
end

function plot_masked_MI(med, lo, hi, refIdx, lags, nReg, names, titleStr)
    mu_c = squeeze(med(refIdx,:,:));
    l_c  = squeeze(lo(refIdx,:,:));
    h_c  = squeeze(hi(refIdx,:,:));

    % Mask where CI includes 0
    mask = (l_c <= 0) & (h_c >= 0);

    data = mu_c;
    data(mask) = 0;
    data(refIdx,:) = NaN; % Hide Auto-MI

    imagesc(lags, 1:nReg, data);
    set(gca,'YDir','normal');
    colormap(jet); colorbar; 
    clim('auto');
    title(titleStr);
    yticks(1:nReg); yticklabels(names);
    xlabel('Lag (s)');
end

function lagsVec = get_lags_vector(lagsInput)
    if isvector(lagsInput)
        lagsVec = lagsInput;
    else
        % Assume [50 x N x N x Lags] or similar, take first slice
        % Linear indexing to find non-singleton dim would be safer, 
        % but typically it's the last dim.
        sz = size(lagsInput);
        if length(sz) > 2
             lagsVec = squeeze(lagsInput(1,1,1,:));
        else
             lagsVec = lagsInput;
        end
    end
end