% % load variables PSD_Spect_Struct_actnorm, PSD_Spect_Struct_passive
% % PSD_Spect_Struct_passive = load('PSD_Spectrogram_AllStim_AllSubjects_paass.mat');
% PSD_Spect_Struct_passive = PSD_Spect_Struct_passive.PSD_Spect_Struct;
% % PSD_Spect_Struct_actnorm = load('PSD_Spectrogram_AllStim_AllSubjects_act.mat');
% PSD_Spect_Struct_actnorm = PSD_Spect_Struct_actnorm.PSD_Spect_Struct;
% PARAMETERS

%%%%%%%%%% user inoput ===================rename for active and apssive 

nBoot = 500;
stimFields = {'stim1_subNorm', 'stim1_subTrialNorm', 'stim2_subNorm', 'stim2_subTrialNorm', 'stim3_subNorm', 'stim3_subTrialNorm', 'stim4_subNorm', 'stim4_subTrialNorm'};
channels = fieldnames(PSD_Spect_Struct_actnorm.(stimFields{1})(1));
bands = {'psd','delta_psd','theta_psd','alpha_psd','beta_psd','gamma_psd'};

for sIdx = 1:numel(stimFields)
    stim = stimFields{sIdx};
    
    fprintf('Now running for stim - %s\n', stim);
    for cIdx = 1:numel(channels)
        chan = channels{cIdx};
        
        figure;
        t = tiledlayout(length(bands), 1, 'TileSpacing','compact','Padding','compact');
        title(t, [stim ' | ' chan ' | Active vs Passive (Bootstrap ' num2str(nBoot) ')']);
        
        for bIdx = 1:length(bands)
            band = bands{bIdx};
            nexttile; hold on;
            
            % Bootstrap Active
            [meanA, ciA, freqA] = bootstrap_psd(PSD_Spect_Struct_actnorm, stim, chan, band, nBoot);
            
            % Bootstrap Passive
            [meanP, ciP, freqP] = bootstrap_psd(PSD_Spect_Struct_passive, stim, chan, band, nBoot);
            
            % Passive shaded CI (red)
            fill([freqP; flipud(freqP)], [ciP(:,1); flipud(ciP(:,2))], [1 0.8 0.8], ...
                'EdgeColor','none','FaceAlpha',0.3);
            plot(freqP, meanP, 'r', 'LineWidth', 1.5);
            
            % Active shaded CI (blue)
            fill([freqA; flipud(freqA)], [ciA(:,1); flipud(ciA(:,2))], [0.8 0.8 1], ...
                'EdgeColor','none','FaceAlpha',0.3);
            plot(freqA, meanA, 'b', 'LineWidth', 1.5);
            
            % Labels
            ylabel(band, 'Interpreter','none');
            if bIdx == length(bands)
                xlabel('Frequency (Hz)');
            end
            
            grid on; box on;
            legend({'Passive CI','Passive Mean','Active CI','Active Mean'}, 'Location','northeastoutside');
        end
        
        % Optional: auto-save each figure
        % outDir = fullfile('Results','ActivePassive_Plots');
        % if ~exist(outDir, 'dir'), mkdir(outDir); end
        % saveas(gcf, fullfile(outDir, [stim '_' chan '.png']));
        pause;
        % close(gcf);
    end

    fprintf('Done running for stim - %s\n\n', stim);
    pause;
end
