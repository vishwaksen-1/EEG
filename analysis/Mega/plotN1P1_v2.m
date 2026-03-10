function [processedArray, n1, p1] = plotN1P1_v2(processedArray)
    Fs = 256;
    minI = 80;  % search from
    maxI = 150; % till

    numChannels = size(processedArray, 1);
    numSamples  = size(processedArray, 2);
    
    % Convert times -> sample indices (sample 1 corresponds to 0 ms)
    ms_to_sample = @(ms) round(ms * Fs / 1000) + 1;
    
    % Search window: 60 ms to 250 ms (inclusive), clipped to available samples
    search_start_samp = max(1, ms_to_sample(minI));
    search_end_samp   = min(numSamples, ms_to_sample(maxI));
    
    % Prepare outputs: [amplitude, sampleIndex, latency_ms]
    n1 = nan(numChannels, 3);
    p1 = nan(numChannels, 3);
    
    for ch = 1:numChannels
    
        segment = processedArray(ch, search_start_samp:search_end_samp);
    
        if isempty(segment)
            continue;
        end
    
        % =======================================
        % 1. Find N1 (local minima, negative) after minI
        % =======================================
        seg_primary = processedArray(ch, search_start_samp:search_end_samp);
        n1_found = false;
        localMinIdx = [];
    
        if numel(seg_primary) >= 3
            [~, localMinIdx] = findpeaks(-seg_primary);
            if ~isempty(localMinIdx)
                n1_local = localMinIdx(1);  % First negative peak
                n1_sample = n1_local + search_start_samp - 1;
                n1_val = processedArray(ch, n1_sample);
                n1_ms = (n1_sample - 1) * 1000 / Fs;
                n1(ch,:) = [n1_val, n1_sample, n1_ms];
                n1_found = true;
            end
        end
    
        % =======================================
        % 2. Find P1 (local maxima, positive) after N1
        % =======================================
        if n1_found
            search_after_n1_start = n1_sample + 1;  % Search after N1
            search_after_n1_end = min(search_end_samp, numSamples);  % Don't go past maxI or the dataset end
            
            segment_after_n1 = processedArray(ch, search_after_n1_start:search_after_n1_end);
            p1_found = false;
            localMaxIdx = [];
    
            if numel(segment_after_n1) >= 3
                [p1_val, localMaxIdx] = max(segment_after_n1);
                p1_sample = localMaxIdx + search_after_n1_start - 1;
                p1_ms = (p1_sample - 1) * 1000 / Fs;
                p1(ch,:) = [p1_val, p1_sample, p1_ms];
                p1_found = true;
            end
        end
    
        % =======================================
        % 3. If no P1 found, mark NaN for that channel
        % =======================================
        if ~p1_found
            p1(ch,:) = [NaN NaN NaN];
        end
    
        % If no N1 found, mark NaN for that channel
        if ~n1_found
            n1(ch,:) = [NaN NaN NaN];
        end
    end

    % Plot results
    t = (0:numSamples-1) * 1000 / Fs;   % time vector in ms
    plot_end_ms = maxI;
    plot_end_sample = ms_to_sample(plot_end_ms);
    plot_end_sample = min(plot_end_sample, numSamples);  % guard
    
    channels = ["AF3","F7","F3","FC5","T7","P7","O1","O2","P8","T8","FC6","F4","F8","AF4"];
    
    figure;
    for k = 1:numChannels
        if k <= 7
            subplot(2, 7, k)
        else
            subplot(2,7,14-k+8)
        end

        plot(t(1:plot_end_sample), processedArray(k,1:plot_end_sample), 'LineWidth', 1.2);
        hold on;
    
        % Get N1/P1 times (if present) and plot vertical lines
        if ~any(isnan(n1(k,:)))
            xline(n1(k,3), '-b', sprintf('N1 %.1f ms', n1(k,3)));
        end
        if ~any(isnan(p1(k,:)))
            xline(p1(k,3), '-r', sprintf('P1 %.1f ms', p1(k,3)));
        end
    
        xlim([0 plot_end_ms]);
        yline(0,'--k','LineWidth',1);
        xlabel('Time (ms)');
        ylabel('Amplitude');
        title(sprintf('Channel %s', channels(k)));
        grid on;
        hold off;
    end
end
