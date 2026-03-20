function A5_out = dcOffsetFull(A5, fs)
    idx_stim_end = round(6.5 * fs) - 1;    % Full epoch end (~6.5 s)

    % DC offset: mean over ENTIRE epoch (1 to idx_stim_end) per (Ch, Stim, Trial, Subj)
    full_range = 1 : idx_stim_end;
    B = mean(A5(full_range, :, :, :, :), 1, 'omitnan');  % [1 x Ch x Stim x Trial x Subj]

    % Subtract full-epoch mean from EVERY data point
    A5_out = A5(full_range, :, :, :, :) - B;  % Output matches input time dimension
end