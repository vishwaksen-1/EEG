% PARAMETERS
nBoot = 500;
bands = {'delta','theta','alpha','beta','gamma'}; % 5 EEG bands
stimFields = fieldnames(PSD_Spect_Struct_actnorm);
channels = fieldnames(PSD_Spect_Struct_actnorm.(stimFields{1})(1)); % e.g. ch_AF3, ch_F7, ...

for sIdx = 1:numel(stimFields)
    stim = stimFields{sIdx};
    fprintf('Processing %s...\n', stim);

    figure('Name', stim, 'Color', 'w', 'Position', [100 100 1200 700]);
    t = tiledlayout(length(bands), 1, 'TileSpacing','compact','Padding','compact');
    title(t, [stim ' | Channel-wise Band Powers (Active vs Passive, Bootstrap ' num2str(nBoot) ')']);

    % Loop over each band
    for bIdx = 1:length(bands)
        band = bands{bIdx};

        % -------------------------------------------------------------
        % 1️⃣ Extract Active bandpower data (subjects × channels)
        % -------------------------------------------------------------
        nSubjects = numel(PSD_Spect_Struct_actnorm.(stim));
        nChannels = numel(channels);
        activeBandMat = nan(nSubjects, nChannels);
        passiveBandMat = nan(nSubjects, nChannels);

        for s = 1:nSubjects
            for c = 1:nChannels
                % From bandPowerMatrix: rows correspond to delta→gamma
                activeBandMat(s,c) = PSD_Spect_Struct_actnorm.(stim)(s).(channels{c}).bandPowerMatrix(bIdx);
                passiveBandMat(s,c) = PSD_Spect_Struct_passive.(stim)(s).(channels{c}).bandPowerMatrix(bIdx);
            end
        end

        % -------------------------------------------------------------
        % 2️⃣ Bootstrap across subjects
        % -------------------------------------------------------------
        bootMeanActive = zeros(nChannels, nBoot);
        bootMeanPassive = zeros(nChannels, nBoot);

        for b = 1:nBoot
            idx = randi(nSubjects, [nSubjects, 1]);
            bootMeanActive(:,b) = mean(activeBandMat(idx,:), 1);
            bootMeanPassive(:,b) = mean(passiveBandMat(idx,:), 1);
        end

        meanA = mean(bootMeanActive, 2);
        meanP = mean(bootMeanPassive, 2);
        ciA = prctile(bootMeanActive, [5 95], 2);
        ciP = prctile(bootMeanPassive, [5 95], 2);

        % -------------------------------------------------------------
        % 3️⃣ Plot (subplot per band)
        % -------------------------------------------------------------
        nexttile; hold on;

        x = 1:nChannels;

        % Shaded CI areas
    % Shaded CI areas
        fill([x fliplr(x)], [ciP(:,1)' fliplr(ciP(:,2)')], [0.8 0.8 1], ...
            'EdgeColor','none','FaceAlpha',0.4);
        plot(x, meanP, 'b', 'LineWidth', 1.5);

        fill([x fliplr(x)], [ciA(:,1)' fliplr(ciA(:,2)')], [1 0.8 0.8], ...
            'EdgeColor','none','FaceAlpha',0.4);
        plot(x, meanA, 'r', 'LineWidth', 1.5);


        % Labels and appearance
        ylabel([upper(band(1)) band(2:end)]);
        if bIdx == length(bands)
            xlabel('Channels');
        end
        set(gca, 'XTick', x, 'XTickLabel', channels, 'XTickLabelRotation', 45);
        legend({'Passive CI','Passive Mean','Active CI','Active Mean'}, 'Location','northeastoutside');
        grid on; box on;
    end
            pause;


            
end