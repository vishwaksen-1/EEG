function A5_out= baselinezeroing(A5,fs )

idx200  = round(0.2*fs) + 1;         % start of baseline (>=200 ms)
idx500  = round(0.5*fs);             % end of baseline (<=500 ms)
idx_on  = idx500 + 1;                % stim start (>500 ms)
idx4100 = round(4.1*fs) + 1;         % ~4100 ms (start of offset, not used here)
idx_stim_end = round(6.5*fs)-1;     % 3.6 s after 500 ms

% Baseline mean per (Ch, Stim, Trial, Subj) using only 200–500 ms
B = mean(A5(idx200:idx500, :, :, :, :), 1, 'omitnan');   % [1 x Ch x Stim x Trial x Subj]
A5_out(1:idx_stim_end, :, :, :, :) = bsxfun(@minus, A5(1:idx_stim_end, :, :, :, :), B);

end