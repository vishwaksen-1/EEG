function [processedArray, P1, N1, P2] = plotN1P1P2_v3(processedArray)

    Fs = 256;

    % --- ERP component latency windows (ms) ---
    P1_win  = [40 80];
    N1_win  = [80 130];
    P2_win  = [130 200];

    numChannels = size(processedArray, 1);
    numSamples  = size(processedArray, 2);

    ms_to_sample = @(ms) round(ms * Fs / 1000) + 1;

    % Convert windows to samples
    P1_s   = max(1, ms_to_sample(P1_win(1)));
    P1_e   = min(numSamples, ms_to_sample(P1_win(2)));
    N1_s   = max(1, ms_to_sample(N1_win(1)));
    N1_e   = min(numSamples, ms_to_sample(N1_win(2)));
    P2_s   = max(1, ms_to_sample(P2_win(1)));
    P2_e   = min(numSamples, ms_to_sample(P2_win(2)));

    % Output arrays
    P1 = nan(numChannels, 3);
    N1 = nan(numChannels, 3);
    P2 = nan(numChannels, 3);

    for ch = 1:numChannels

        sig = processedArray(ch,:);

        % ============
        % 1. P1 (40–80 ms): most positive peak
        % ============
        segP1 = sig(P1_s:P1_e);
        if ~isempty(segP1)
            [p1_val, p1_idx_local] = max(segP1);
            p1_sample = p1_idx_local + P1_s - 1;
            p1_ms     = (p1_sample - 1)*1000/Fs;
            P1(ch,:)  = [p1_val, p1_sample, p1_ms];
        end

        % ============
        % 2. N1 (80–130 ms): most negative peak
        % ============
        segN1 = sig(N1_s:N1_e);
        if ~isempty(segN1)
            [n1_val, n1_idx_local] = min(segN1);   % NEGATIVE peak
            n1_sample = n1_idx_local + N1_s - 1;
            n1_ms     = (n1_sample - 1)*1000/Fs;
            N1(ch,:)  = [n1_val, n1_sample, n1_ms];
        end

        % ============
        % 3. P2 (130–200 ms): most positive peak
        % ============
        segP2 = sig(P2_s:P2_e);
        if ~isempty(segP2)
            [p2_val, p2_idx_local] = max(segP2);
            p2_sample = p2_idx_local + P2_s - 1;
            p2_ms     = (p2_sample - 1)*1000/Fs;
            P2(ch,:)  = [p2_val, p2_sample, p2_ms];
        end

    end

    % ==========================================================
    % PLOTTING (same layout as before, plus dashed 0 ms line)
    % ==========================================================
    t = (0:numSamples-1) * 1000 / Fs;

    plot_end_sample = ms_to_sample(P2_win(2));
    plot_end_sample = min(plot_end_sample, numSamples);

    channels = ["AF3","F7","F3","FC5","T7","P7","O1","O2","P8","T8","FC6","F4","F8","AF4"];

    figure;
    for k = 1:numChannels
        if k <= 7
            subplot(2, 7, k);
        else
            subplot(2, 7, 14-k+8);
        end

        plot(t(1:plot_end_sample), processedArray(k,1:plot_end_sample),'LineWidth',1.2);
        hold on;

        % dashed 0 ms line
        xline(0,'--k','LineWidth',1);

        % Plot P1
        if ~any(isnan(P1(k,:)))
            xline(P1(k,3),'--g',sprintf('P1 %.1f ms',P1(k,3)));
        end

        % Plot N1
        if ~any(isnan(N1(k,:)))
            xline(N1(k,3),'-b',sprintf('N1 %.1f ms',N1(k,3)));
        end

        % Plot P2
        if ~any(isnan(P2(k,:)))
            xline(P2(k,3),'-r',sprintf('P2 %.1f ms',P2(k,3)));
        end

        xlim([0 P2_win(2)]);
        xlabel('Time (ms)');
        ylabel('Amplitude (µV)');
        title(sprintf('Channel %s', channels(k)));
        grid on;
        hold off;
    end

end
