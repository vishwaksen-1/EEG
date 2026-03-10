function plot_MI_Experiment(results, ch1, ch2)
% plot_MI_Experiment - Plot MI with CI for a specific pair (ch1, ch2)
%
% Usage:
%   plot_MI_Experiment(active_res, 1, 2)
%   plot_MI_Experiment(visual_res, 3, 5)
%
% Inputs:
%   results : MI Data Structure (active, passive, or visual)
%   ch1     : Index of Source Channel/Region
%   ch2     : Index of Target Channel/Region

    outNames = fieldnames(results);
    % Usually we want to iterate over all Out fields (e.g. Out12, Out34)
    
    for o = 1:numel(outNames)
        outName = outNames{o};
        
        subFields = fieldnames(results.(outName));
        dataFields = subFields(contains(subFields, 'stim') | contains(subFields, 'seg'));
        dataFields = dataFields(~contains(dataFields, 'raw'));
        
        if isempty(dataFields)
            continue; 
        end

        % Get Labels for title
        if isfield(results.(outName), 'regionLabels')
            labels = results.(outName).regionLabels;
        elseif isfield(results.(outName), 'region_labels')
             labels = results.(outName).region_labels;
        else
             % Extract from first available
             tempDat = results.(outName).(dataFields{1}).vals;
             nReg = size(tempDat, 2);
             labels = arrayfun(@(x) sprintf('Reg%d', x), 1:nReg, 'UniformOutput', false);
        end
        
        label1 = labels{ch1};
        label2 = labels{ch2};
        
        numPlots = numel(dataFields);
        
        % Create Figure
        figure('Name', sprintf('%s: %s vs %s', outName, label1, label2), 'Color', 'w', 'Position', [100 100 400*numPlots 300]);
        
        for s = 1:numPlots
            fName = dataFields{s};
            
            % Extract Data
            % vals: [50 x nReg x nReg x nLags]
            boot_vals = results.(outName).(fName).vals;
            lagsRaw   = results.(outName).(fName).lags;
            
            if numel(lagsRaw) > size(boot_vals, 4)
                lags = squeeze(lagsRaw(1,1,1,:));
            else
                lags = lagsRaw;
            end
            
            % Extract Pair Traces [50 x nLags]
            % Dimensions are (Boot, Source, Target, Lag)
            pair_boot = squeeze(boot_vals(:, ch1, ch2, :));
            
            % Compute Stats
            med_trace = median(pair_boot, 1, 'omitnan');
            lo_trace  = prctile(pair_boot, 2.5, 1);
            hi_trace  = prctile(pair_boot, 97.5, 1);
            
            % Plot
            subplot(1, numPlots, s);
            hold on;
            
            % Shaded Error Bar (CI)
            fill([lags, fliplr(lags)], [lo_trace, fliplr(hi_trace)], ...
                 [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
             
            % Median Line
            plot(lags, med_trace, 'k', 'LineWidth', 1.5);
            
            % Zero Lines
            xline(0, '--k', 'Alpha', 0.3);
            yline(0, '--k', 'Alpha', 0.3);
            
            title(fName, 'Interpreter', 'none');
            xlabel('Lag (s)');
            ylabel('Mutual Information');
            grid on;
            axis tight;
        end
        
        sgtitle(sprintf('%s Connectivity: %s -> %s', outName, label1, label2), 'Interpreter', 'none');
    end
end