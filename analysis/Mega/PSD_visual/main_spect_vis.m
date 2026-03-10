% ===============================================================
% Plot averaged spectrograms (raw and normalized)
% Restrict first column (total spectrogram) to <= 50 Hz
% ===============================================================

channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2','P8','T8','FC6','F4','F8','AF4'};
segments = {'seg1_raw','seg2_raw','seg3_raw'};
segmentsNorm = {'seg1_subNorm','seg2_subNorm','seg3_subNorm'};

bands = {'spectrogram','delta_spectrogram','theta_spectrogram',...
         'alpha_spectrogram','beta_spectrogram','gamma_spectrogram'};

num_channels = numel(channels);
num_segments = numel(segments);
num_bands = numel(bands);

% % ----------- Plot NORMALIZED Spectrograms ----------
% for ch = 1:num_channels
%     ch_name = ['ch_' channels{ch}];
%     figure('Name',['Normalized Spectrogram - ' channels{ch}],'NumberTitle','off');
%     t = tiledlayout(num_segments, num_bands, 'TileSpacing','compact','Padding','compact');
% 
%     for s = 1:num_segments
%         seg_name = segmentsNorm{s};
%         subjects = PSD_Spect_Struct_visual.(seg_name);
% 
%         for b = 1:num_bands
%             band_name = bands{b};
%             S_all = arrayfun(@(x) x.(ch_name).(band_name), subjects, 'UniformOutput', false);
%             f = subjects(1).(ch_name).([band_name '_f']);
%             tvals = subjects(1).(ch_name).spectrogram_t;
%             S_all = cat(3, S_all{:});
%             S_avg = mean(abs(S_all), 3, 'omitnan');
% 
%             % === Restrict to <=50Hz only for the total spectrogram ===
%             if strcmp(band_name, 'spectrogram')
%                 mask = f <= 50;
%                 f = f(mask);
%                 S_avg = S_avg(mask, :);
%             end
% 
%             % Normalize
%        %     S_avg = (S_avg - min(S_avg(:))) / (max(S_avg(:)) - min(S_avg(:)));
% 
%             nexttile((s-1)*num_bands + b);
%             imagesc(tvals, f, S_avg);
%             axis xy;
%             xlabel('Time (s)'); ylabel('Frequency (Hz)');
%             title([segmentsNorm{s} ' - ' strrep(band_name,'_',' ')]);
%             colormap jet; colorbar;
%         end
%     end
%     pause
%     title(t, ['Average NORMALIZED Spectrograms - ' channels{ch}], 'FontWeight','bold');
% end

for ch = 1:num_channels

    ch_name = ['ch_' channels{ch}];
    figure('Name',['Normalized Spectrogram - ' channels{ch}],'NumberTitle','off');
    t = tiledlayout(num_segments, num_bands, 'TileSpacing','compact','Padding','compact');

    % ==========================================================
    % 1) PRECOMPUTE COLOR SCALES PER BAND (NOT per segment)
    % ==========================================================
    band_min = inf(1, num_bands);
    band_max = -inf(1, num_bands);

    for b = 1:num_bands
        band_name = bands{b};

        % Loop through all segments to accumulate global min/max per band
        for s = 1:num_segments
            seg_name = segmentsNorm{s};
            subjects = PSD_Spect_Struct_visual.(seg_name);

            S_all = arrayfun(@(x) x.(ch_name).(band_name), subjects, 'UniformOutput', false);
            f = subjects(1).(ch_name).([band_name '_f']);
            S_all = cat(3, S_all{:});
            S_avg = mean(abs(S_all), 3, 'omitnan');

            % Restrict <=50Hz only for full spectrogram
            if strcmp(band_name, 'spectrogram')
                mask = f <= 50;
                S_avg = S_avg(mask, :);
            end

            % Update band-level min/max (across ALL segments)
            band_min(b) = min(band_min(b), min(S_avg(:)));
            band_max(b) = max(band_max(b), max(S_avg(:)));
        end
    end

    % ==========================================================
    % 2) PLOT using SAME CLIM for all segments within each band
    % ==========================================================
    for s = 1:num_segments
        seg_name = segmentsNorm{s};
        subjects = PSD_Spect_Struct_visual.(seg_name);

        for b = 1:num_bands
            band_name = bands{b};

            S_all = arrayfun(@(x) x.(ch_name).(band_name), subjects, 'UniformOutput', false);
            f = subjects(1).(ch_name).([band_name '_f']);
            tvals = subjects(1).(ch_name).spectrogram_t;
            S_all = cat(3, S_all{:});
            S_avg = mean(abs(S_all), 3, 'omitnan');

            if strcmp(band_name, 'spectrogram')
                mask = f <= 50;
                f = f(mask);
                S_avg = S_avg(mask, :);
            end

            nexttile((s-1)*num_bands + b);
            imagesc(tvals, f, S_avg);
            axis xy;
            xlabel('Time (s)');
            ylabel('Frequency (Hz)');
            title([segmentsNorm{s} ' - ' strrep(band_name,'_',' ')]);

            colormap jet; colorbar;

            % 🔥 Apply SAME CLIM across segments but DIFFERENT for each band
            if b <= 4
                clim([band_min(b), band_max(b)]);
            else 
                % clim([0 8]);
            end
        end
    end

    title(t, ['Average NORMALIZED Spectrograms - ' channels{ch}], 'FontWeight','bold');
    pause
end

