% %% === LOAD DATA ===
% load('PSD_Spect_Struct_visual.mat');
% 
% %% === PARAMETERS ===
% nBoot = 500;
% bands = {'delta','theta','alpha','beta','gamma'};  % 5 EEG bands
% segNames = {'seg1','seg2','seg3'};
% colors = {'r','b','g'}; % seg1=red, seg2=blue, seg3=green
% 
% % Only use normalized data
% varType = 'subNorm';
% 
% % Segments pairs (rows)
% segPairs = {
%     {'seg1','seg2'}
%     {'seg2','seg3'}
%     {'seg3','seg1'}
% };
% 
% %% === EXTRACT CHANNEL INFO ===
% channels = fieldnames(PSD_Spect_Struct_visual.seg1_subNorm(1));
% nChannels = numel(channels);
% nBands   = numel(bands);
% 
% %% === FIGURE LAYOUT: 3 rows (pairs) × 5 columns (bands) ===
% figure('Color','w','Position',[200 100 1600 950]);
% t = tiledlayout(3, 5, 'TileSpacing', 'compact', 'Padding', 'compact');
% sgtitle('Bootstrap Normalized Band Powers (Mean ± 90% CI)', 'FontWeight', 'bold');
% 
% %% =========================
% %      MAIN LOOP
% % =========================
% for pIdx = 1:3
%     pair = segPairs{pIdx};
% 
%     for bIdx = 1:nBands
%         band = bands{bIdx};
% 
%         nexttile; hold on;
% 
%         %% PLOT BOTH SEGMENTS IN THIS PAIR
%         for sIdx = 1:2
%             seg = pair{sIdx};
%             segField = [seg '_' varType];
% 
%             % fixed colors: seg1=red, seg2=blue, seg3=green
%             segNum = str2double(seg(end));
%             col = colors{segNum};
% 
%             % ---------------------------------------
%             % Extract band-power matrix for all subjects
%             % ---------------------------------------
%             nSubjects = numel(PSD_Spect_Struct_visual.(segField));
% 
%             bandMat = nan(nSubjects, nChannels);
% 
%             for subj = 1:nSubjects
%                 for c = 1:nChannels
%                     bandMat(subj, c) = PSD_Spect_Struct_visual.(segField)(subj).(channels{c}).bandPowerMatrix(bIdx);
%                 end
%             end
% 
%             % ---------------------------------------
%             % Bootstrap mean across subjects
%             % ---------------------------------------
%             bootMean = zeros(nChannels, nBoot);
%             for b = 1:nBoot
%                 idx = randi(nSubjects, [nSubjects, 1]);
%                 bootMean(:, b) = mean(bandMat(idx, :), 1);
%             end
% 
%             meanVals = mean(bootMean, 2);
%             ciVals   = prctile(bootMean, [5 95], 2);
% 
%             errLower = meanVals - ciVals(:,1);
%             errUpper = ciVals(:,2) - meanVals;
% 
%             % ---------------------------------------
%             % PLOT
%             % ---------------------------------------
%             x = 1:nChannels;
% 
%             errorbar(x, meanVals, errLower, errUpper, ...
%                 'Color', col, 'LineWidth', 1.5, ...
%                 'Marker', 'o', 'MarkerSize', 4, ...
%                 'MarkerFaceColor', col);
%         end
% 
%         % ---------------------------------------
%         % Formatting
%         % ---------------------------------------
%         title(upper(band), 'Interpreter', 'none');
%         ylabel(sprintf('%s–%s', pair{1}, pair{2}), 'Interpreter', 'none');
% 
%         set(gca, 'XTick', 1:nChannels, ...
%                  'XTickLabel', channels, ...
%                  'XTickLabelRotation', 45);
% 
%         xlim([0.5, nChannels+0.5]);
%         grid on; box on;
% 
%         % ---------------------------------------
%         % Add legend ONLY in last column (gamma)
%         % ---------------------------------------
%         if bIdx == nBands  % gamma column
%             switch pIdx
%                 case 1
%                     legend({'seg1','seg2'}, 'Location','best');%, 'Title','Segments');
%                 case 2
%                     legend({'seg2','seg3'}, 'Location','best');%, 'Title','Segments');
%                 case 3
%                     legend({'seg3','seg1'}, 'Location','best');%, 'Title','Segments');
%             end
%         end
%     end
% end

%% === LOAD DATA ===
load('PSD_Spect_Struct_visual.mat');

%% === PARAMETERS ===
nBoot = 500;
bands = {'delta','theta','alpha','beta','gamma'};  % 5 EEG bands
segNames = {'seg1','seg2','seg3'};
colors = {'r','b','g'}; % seg1=red, seg2=blue, seg3=green

% Only use normalized data
varType = 'subNorm';

% Segments pairs (rows)
segPairs = {
    {'seg1','seg2'}
    {'seg2','seg3'}
    {'seg3','seg1'}
};

%% === EXTRACT CHANNEL INFO ===
channels = fieldnames(PSD_Spect_Struct_visual.seg1_subNorm(1));
nChannels = numel(channels);
nBands   = numel(bands);

%% === FIGURE LAYOUT: 3 rows × 5 columns ===
figure('Color','w','Position',[200 100 1600 950]);
t = tiledlayout(3, 5, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle('Bootstrap Normalized Band Powers (Mean ± 90% CI)', 'FontWeight', 'bold');

%% =========================
%      MAIN LOOP
% =========================
for pIdx = 1:3
    pair = segPairs{pIdx};

    for bIdx = 1:nBands
        band = bands{bIdx};

        ax = nexttile; hold(ax,'on');

        % storage for CI comparison
        pairData = struct();

        %% === PLOT BOTH SEGMENTS ===
        for sIdx = 1:2
            seg = pair{sIdx};
            segField = [seg '_' varType];

            segNum = str2double(seg(end));
            col = colors{segNum};

            % ---------------------------------------
            % Extract band-power matrix
            % ---------------------------------------
            nSubjects = numel(PSD_Spect_Struct_visual.(segField));
            bandMat = nan(nSubjects, nChannels);

            for subj = 1:nSubjects
                for c = 1:nChannels
                    bandMat(subj, c) = ...
                        PSD_Spect_Struct_visual.(segField)(subj).(channels{c}).bandPowerMatrix(bIdx);
                end
            end

            % ---------------------------------------
            % Bootstrap
            % ---------------------------------------
            bootMean = zeros(nChannels, nBoot);
            for b = 1:nBoot
                idx = randi(nSubjects, [nSubjects, 1]);
                bootMean(:, b) = mean(bandMat(idx,:), 1);
            end

            meanVals = mean(bootMean, 2);
            ciVals   = prctile(bootMean, [5 95], 2);

            errLow  = meanVals - ciVals(:,1);
            errHigh = ciVals(:,2) - meanVals;

            x = 1:nChannels;

            % store for non-overlap test
            pairData(sIdx).mean   = meanVals;
            pairData(sIdx).ciLow  = ciVals(:,1);
            pairData(sIdx).ciHigh = ciVals(:,2);
            pairData(sIdx).x      = x;

            % plot
            errorbar(x, meanVals, errLow, errHigh, ...
                'Color', col, 'LineWidth', 1.5, ...
                'Marker','o','MarkerSize',4, ...
                'MarkerFaceColor', col);
        end

        %% =========================================
        %   NON-OVERLAP MASK (pairwise)
        % =========================================
        yl = ylim;
        yBase = yl(1) + 0.07 * range(yl);
        maskHeight = 0.03 * range(yl);

        nonOverlap = (pairData(1).ciLow > pairData(2).ciHigh) | ...
                     (pairData(2).ciLow > pairData(1).ciHigh);

        xMask = pairData(1).x(nonOverlap);

        if any(nonOverlap)
            switch pIdx
                case 1   % seg1 vs seg2
                    mk = '.'; col = 'r'; sz = 18;
                case 2   % seg2 vs seg3
                    mk = 'x'; col = 'b'; sz = 10;
                case 3   % seg3 vs seg1
                    mk = 'o'; col = 'g'; sz = 8;
            end

            plot(xMask, ...
                 yBase * ones(size(xMask)), ...
                 mk, ...
                 'Color', col, ...
                 'MarkerSize', sz, ...
                 'LineWidth', 1.5);
        end

        %% === Formatting ===
        title(upper(band), 'Interpreter','none');
        ylabel(sprintf('%s–%s', pair{1}, pair{2}), 'Interpreter','none');

        set(gca,'XTick',1:nChannels, ...
                'XTickLabel',channels, ...
                'XTickLabelRotation',45);

        xlim([0.5 nChannels+0.5]);
        grid on; box on;

        %% === Segment legend (last column only) ===
        if bIdx == nBands
            legend(pair, 'Location','best');
        end
    end
end

%% =========================================
%   MARKER LEGEND OVERLAY (center-right)
% =========================================
tileIdx = (2-1)*nBands + 5;   % row 2, col 5
axL = nexttile(t, tileIdx);
hold(axL,'on');

h1 = plot(axL, nan, nan, '.', 'Color','r', 'MarkerSize',18, 'LineWidth',1.5);
h2 = plot(axL, nan, nan, 'x', 'Color','b', 'MarkerSize',10, 'LineWidth',1.5);
h3 = plot(axL, nan, nan, 'o', 'Color','g', 'MarkerSize',8,  'LineWidth',1.5);

lgMask = legend(axL, [h1 h2 h3], ...
    {'seg1 vs seg2 (no CI overlap)', ...
     'seg2 vs seg3 (no CI overlap)', ...
     'seg3 vs seg1 (no CI overlap)'}, ...
    'Location','bestoutside');

lgMask.Box = 'off';
lgMask.Color = 'none';
