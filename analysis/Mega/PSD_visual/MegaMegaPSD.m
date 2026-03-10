% %% === LOAD DATA ===
% load('PSD_Spect_Struct_visual.mat');
% 
% %% === PARAMETERS ===
% nBoot = 500;
% segNames = {'seg1','seg2','seg3'};
% colors = {'r','g','b'}; % seg1=red, seg2=green, seg3=blue
% bands = {'psd','delta_psd','theta_psd','alpha_psd','beta_psd','gamma_psd'};
% varTypes = {'raw','subNorm'};
% ciPercent = [5 95]; % 90% CI
% 
% channels = fieldnames(PSD_Spect_Struct_visual.seg1_raw(1));
% 
% %% === MAIN LOOP: Each channel → one figure ===
% for cIdx = 1:numel(channels)
%     chan = channels{cIdx};
%     fprintf('Processing channel: %s\n', chan);
% 
%     figure('Name', chan, 'Color', 'w', 'Position', [100 100 1400 900]);
%     t = tiledlayout(length(bands), length(varTypes), ...
%         'TileSpacing','compact','Padding','compact');
%     sgtitle(t, [chan ' | Visual (Bootstrap ' num2str(nBoot) ', 90% CI)'], 'FontWeight','bold');
% 
%     % === For each band × varType ===
%     for bIdx = 1:length(bands)
%         band = bands{bIdx};
% 
%         for vIdx = 1:length(varTypes)
%             varType = varTypes{vIdx};
%             nexttile; hold on;
% 
%             % Overlay all 3 segments (seg1–seg3)
%             for sIdx = 1:length(segNames)
%                 seg = segNames{sIdx};
%                 segField = [seg '_' varType];
%                 fprintf('  %s | %s | %s\n', segField, chan, band);
% 
%                 % === Bootstrap PSD ===
%              % inside your plotting loop, after calling bootstrap_psd:
% [bootMean, bootCI, freq] = bootstrap_psd(PSD_Spect_Struct_visual, segField, chan, band, nBoot, ciPercent);
% 
% % enforce column orientation
% bootMean = bootMean(:);
% ciLower = bootCI(:,1);
% ciUpper = bootCI(:,2);
% freq = freq(:);
% 
% errLow  = bootMean - ciLower;   % positive vector
% errHigh = ciUpper - bootMean;   % positive vector
% 
% % plot errorbar (mean with asymmetric error)
% errorbar(freq, bootMean, errLow, errHigh, 'Color', colors{sIdx}, ...
%          'LineWidth', 1.2, 'CapSize', 3);
% 
%             end
% 
%             % === Labels and titles ===
%             if bIdx == length(bands)
%                 xlabel('Frequency (Hz)');
%             end
%             if vIdx == 1
%                 ylabel([upper(band(1)) band(2:end)], 'Interpreter','none');
%             end
%             title(varType, 'Interpreter','none');
%             grid on; box on;
%         end
%     end
% 
%     % === Legend (once per figure) ===
%     lg = legend(segNames, 'Location','northeastoutside');
%     lg.Title.String = 'Segments';
%     lg.Box = 'off';
% 
%     pause; % inspect before next channel
%     close(gcf);
% end
% 
% fprintf('✅ All channels processed.\n');
% 
% 


%% === LOAD DATA ===
load('PSD_Spect_Struct_visual.mat');

%% === PARAMETERS ===
nBoot = 500;
segNames = {'seg1','seg2','seg3'};
colors = {'r','g','b'}; % seg1=red, seg2=green, seg3=blue
bands = {'psd','delta_psd','theta_psd','alpha_psd','beta_psd','gamma_psd'};
varTypes = {'raw','subNorm'};
ciPercent = [5 95]; % 90% CI

channels = fieldnames(PSD_Spect_Struct_visual.seg1_raw(1));

%% === MAIN LOOP: Each channel → one figure ===
for cIdx = 1:numel(channels)
    chan = channels{cIdx};
    fprintf('Processing channel: %s\n', chan);

    figure('Name', chan, 'Color', 'w', 'Position', [100 100 1400 900]);
    t = tiledlayout(length(bands), length(varTypes), ...
        'TileSpacing','compact','Padding','compact');
    sgtitle(t, [chan ' | Visual (Bootstrap ' num2str(nBoot) ', 90% CI)'], 'FontWeight','bold');

    for bIdx = 1:length(bands)
        band = bands{bIdx};
        for vIdx = 1:length(varTypes)
            varType = varTypes{vIdx};
            nexttile; hold on;
    
            % === Compute seg1 total spectral power (for normalisation) ===
            seg1Field = ['seg1_' varType];
            
            % Use the same bootstrap function to obtain PSD seg1
            [seg1_mean, seg1_CI, freq] = bootstrap_psd( ...
                PSD_Spect_Struct_visual, seg1Field, chan, band, nBoot, ciPercent);
    
            freq = freq(:);
            seg1_mean = seg1_mean(:);
    
            % Total power of seg1 = area under its PSD curve
            seg1_total_power = trapz(freq, seg1_mean);

            % storage for later mask computation
            segData = struct();

            % ----------------------------------------
            %     Loop through segments 1–3
            % ----------------------------------------
            for sIdx = 1:length(segNames)
                seg = segNames{sIdx};
                segField = [seg '_' varType];
                fprintf('  %s | %s | %s\n', segField, chan, band);
    
                % === Bootstrap PSD ===
                [bootMean, bootCI, freq] = bootstrap_psd(PSD_Spect_Struct_visual, ...
                    segField, chan, band, nBoot, ciPercent);
    
                % enforce column orientation
                bootMean = bootMean(:);
                ciLower = bootCI(:,1);
                ciUpper = bootCI(:,2);
                freq = freq(:);
    
                % === NORMALISE ALL SEGMENTS USING TOTAL POWER OF SEG1 ===
                bootMean = bootMean ./ seg1_total_power;
                ciLower = ciLower ./ seg1_total_power;
                ciUpper = ciUpper ./ seg1_total_power;
    
                % === Convert to dB ===
                bootMean_dB = 10*log10(bootMean);
                ciLower_dB = 10*log10(ciLower);
                ciUpper_dB = 10*log10(ciUpper);
    
                % recompute asymmetric errors after dB conversion
                errLow  = bootMean_dB - ciLower_dB;
                errHigh = ciUpper_dB - bootMean_dB;
    
                % === Store for later comparison ===
                segData(sIdx).name   = seg;
                segData(sIdx).freq   = freq;
                segData(sIdx).mean   = bootMean_dB;
                segData(sIdx).ciLow  = ciLower_dB;
                segData(sIdx).ciHigh = ciUpper_dB;
                
                % === Plot errorbar ===
                errorbar(freq, bootMean_dB, errLow, errHigh, ...
                    'Color', colors{sIdx}, 'LineWidth', 1.2, 'CapSize', 3);

            end
            % =========================================
            %   NON-OVERLAP MASKS (pairwise, visible)
            % =========================================
            yl = ylim;
            yMask = yl(1) + 0.07 * range(yl);   % single baseline, easy to scan
            maskHeight = 0.02 * range(yl);     % thickness of mask bars

            pairIdx     = [1 2; 2 3; 3 1];
            pairMarkers = {'.', 'x', 'o'};      % dot, cross, circle
            pairColors  = {'r', 'b', 'g'};      % red, blue, green
            pairSizes   = [18, 10, 8];          % tuned for visibility
            
            for p = 1:size(pairIdx,1)
                i = pairIdx(p,1);
                j = pairIdx(p,2);
            
                % compute non-overlap mask
                nonOverlap = (segData(i).ciLow > segData(j).ciHigh) | ...
                             (segData(j).ciLow > segData(i).ciHigh);
                
                xMask = segData(i).freq(nonOverlap);

                if any(nonOverlap)
                    plot(xMask, ...
                         yMask + (p-1)*maskHeight*ones(size(xMask)), ...
                         pairMarkers{p}, ...
                         'Color', pairColors{p}, ...
                         'MarkerSize', pairSizes(p), ...
                         'LineWidth', 1.5);
                end
            end


            % labels and titles
            if bIdx == length(bands)
                xlabel('Frequency (Hz)');
            end
            if vIdx == 1
                ylabel([upper(band(1)) band(2:end) ' (dB)'], 'Interpreter','none');
            end
            title(varType, 'Interpreter','none');
            grid on; box on;
        end
    end



    % === Legend (once per figure) ===
    lg = legend(segNames, 'Location','northeastoutside');
    lg.Title.String = 'Segments';
    lg.Box = 'off';
    
    % =========================================
    %   MARKER LEGEND OVERLAY (subplot 5,2)
    % =========================================
    tileIdx = (5-1)*length(varTypes) + 2;  % (row 5, col 2)
    ax = nexttile(t, tileIdx);
    hold(ax, 'on');
    
    h1 = plot(ax, nan, nan, '.', 'Color','r', 'MarkerSize',18, 'LineWidth',1.5);
    h2 = plot(ax, nan, nan, 'x', 'Color','b', 'MarkerSize',10, 'LineWidth',1.5);
    h3 = plot(ax, nan, nan, 'o', 'Color','g', 'MarkerSize',8,  'LineWidth',1.5);
    
    lgMask = legend(ax, [h1 h2 h3], ...
        {'seg1 vs seg2 (no CI overlap)', ...
         'seg2 vs seg3 (no CI overlap)', ...
         'seg3 vs seg1 (no CI overlap)'}, ...
        'Location','bestoutside');
    
    lgMask.Box = 'off'; 
    lgMask.Color = 'none';   % transparent background

    pause; % inspect before next channel
    % close(gcf);
end

fprintf('✅ All channels processed.\n');