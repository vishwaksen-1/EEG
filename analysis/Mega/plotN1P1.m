function [processedArray, n1, p1] = plotN1P1(processedArray)
    Fs = 256;
    minI = 80;  % search from
    maxI = 150; % till

    numChannels = size(processedArray, 1);
    numSamples  = size(processedArray, 2);
    
    % convert times -> sample indices (sample 1 corresponds to 0 ms)
    ms_to_sample = @(ms) round(ms * Fs / 1000) + 1;
    
    % search window: 60 ms to 250 ms (inclusive), clipped to available samples
    search_start_samp = max(1, ms_to_sample(minI));
    search_end_samp   = min(numSamples, ms_to_sample(maxI));
    
    % prepare outputs: [amplitude, sampleIndex, latency_ms]
    n1 = nan(numChannels, 3);
    p1 = nan(numChannels, 3);
    
    for ch = 1:numChannels
    
        segment = processedArray(ch, search_start_samp:search_end_samp);
    
        if isempty(segment)
            continue;
        end
    
        % =======================================
        % 1. Find P1 (max) first
        % =======================================
        [p1_val, p1_local_idx] = max(segment);
        p1_sample = p1_local_idx + search_start_samp - 1;
        p1_ms     = (p1_sample - 1) * 1000 / Fs;
    
        % =======================================
        % 2. N1 PRIMARY SEARCH — before P1
        % =======================================
        seg_primary = processedArray(ch, search_start_samp : p1_sample);
    
        n1_found = false;
        localMinIdx = [];
    
        if numel(seg_primary) >= 3
            [~, localMinIdx] = findpeaks(-seg_primary);
            if ~isempty(localMinIdx)
                n1_local = localMinIdx(end);
                n1_found = true;
            end
        end
    
        % =======================================
        % 3. N1 FALLBACK SEARCH — from 60 ms to P1
        % =======================================
        if ~n1_found
            search50 = ms_to_sample(50);   % convert 60 ms to sample
    
            seg_fallback = processedArray(ch, search50 : p1_sample);
    
            if numel(seg_fallback) >= 3
                [~, localMinIdx] = findpeaks(-seg_fallback);
                if ~isempty(localMinIdx)
                    n1_local = localMinIdx(end);
                    n1_sample = n1_local + search50 - 1;
                    n1_val    = processedArray(ch, n1_sample);
                    n1_ms     = (n1_sample - 1) * 1000 / Fs;
                    n1(ch,:)  = [n1_val, n1_sample, n1_ms];
                    n1_found  = true;
                end
            end
        end
    
        % =======================================
        % 4. If found in primary search: compute N1
        % =======================================
        if n1_found && ~exist('n1_sample','var')
            n1_sample = n1_local + search_start_samp - 1;
            n1_val    = processedArray(ch, n1_sample);
            n1_ms     = (n1_sample - 1) * 1000 / Fs;
            n1(ch,:)  = [n1_val, n1_sample, n1_ms];
        end
    
        % =======================================
        % 5. If still not found → NaN
        % =======================================
        if ~n1_found
            n1(ch,:) = [NaN NaN NaN];
        end
    
        % store P1
        p1(ch,:) = [p1_val, p1_sample, p1_ms];
    
        clear n1_sample n1_local n1_val n1_ms
    end

    % Handle cases where N1 occurs after P1 (N1 after P1), and search for N1'
    for ch = 1:numChannels
        if n1(ch, 2) > p1(ch, 2)  % N1 occurs after P1
            % Search for N1' before P1 (local minimum just before P1)
            segment_before_p1 = processedArray(ch, search_start_samp:p1(ch, 2));
            [~, n1_prime_local_min_idx] = findpeaks(-segment_before_p1);
            if ~isempty(n1_prime_local_min_idx)
                n1_prime_local_idx = n1_prime_local_min_idx(end);
                n1_prime_sample = n1_prime_local_idx + search_start_samp - 1;
                n1_prime_val = processedArray(ch, n1_prime_sample);
                n1_prime_ms = (n1_prime_sample - 1) * 1000 / Fs;
                n1(ch, :) = [n1_prime_val, n1_prime_sample, n1_prime_ms];
            end
        end
        
        % Handle case when N1 or P1 is at the endpoint of the signal
        if p1(ch, 2) == numSamples  % P1 is at the end of the signal
            [latest_p1_val, latest_p1_local_idx] = max(processedArray(ch, p1(ch, 2)-10:end));
            latest_p1_sample = latest_p1_local_idx + p1(ch, 2) - 10 - 1;
            latest_p1_ms = (latest_p1_sample - 1) * 1000 / Fs;
            p1(ch, :) = [latest_p1_val, latest_p1_sample, latest_p1_ms];
        end
        
        if n1(ch, 2) == numSamples  % N1 is at the end of the signal
            [latest_n1_val, latest_n1_local_idx] = min(processedArray(ch, n1(ch, 2)-10:end));
            latest_n1_sample = latest_n1_local_idx + n1(ch, 2) - 10 - 1;
            latest_n1_ms = (latest_n1_sample - 1) * 1000 / Fs;
            n1(ch, :) = [latest_n1_val, latest_n1_sample, latest_n1_ms];
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
    
        % get N1/P1 times (if present) and plot vertical lines
        if ~any(isnan(n1(k,:)))
            xline(n1(k,3), '-b', sprintf('N1 %.1f ms', n1(k,3)));
        end
        if ~any(isnan(p1(k,:)))
            xline(p1(k,3), '-r', sprintf('P1 %.1f ms', p1(k,3)));
        end

        % If N1 occurs after P1, mark it with dashed line
        if n1(k, 2) > p1(k, 2)  % N1 occurs after P1
            xline(n1(k,3), '--b', sprintf('N1 After P1 %.1f ms', n1(k,3)));
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
