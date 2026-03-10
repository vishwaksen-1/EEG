%% ---- Params & time axis ----
fs = 256;                                   % Hz
[T, Ch, S, Tr, Subj] = size(A5);
t_ms = (0:T-1)/fs*1000;                      % 0 .. 6500 ms
vx = [500 4100];                             % vertical markers (ms)

%% ---- Per-stimulus, per-subject trial means ----
% Msub{k} is [T x Ch x Subj], one cell per stimulus
Msub = cell(S,1);
for k = 1:S
    tmp = mean(A5(:,:,k,:,:), 4, 'omitnan');   % [T x Ch x 1 x 1 x Subj]
    Msub{k} = squeeze(tmp);                    % [T x Ch x Subj]
end

%% ---- Loop all channels; show 4 imagesc (subjects × time) and pause ----
f = figure('Name','Stimulus-wise imagesc per channel'); set(f,'Color','w');

for ch = 1:Ch
    clf(f);

    % Build per-stimulus matrices A{k}: [Subj x T] for this channel
    A = cell(1, min(S,4));
    mins = inf(1, min(S,4));
    maxs = -inf(1, min(S,4));
    for k = 1:min(S,4)
        Ak = squeeze(Msub{k}(:, ch, :))';     % [Subj x T]
        A{k} = Ak;
        % gather color limits (NaN-safe)
        mins(k) = nanmin(Ak(:));
        maxs(k) = nanmax(Ak(:));
    end
    clim = [nanmin(mins), nanmax(maxs)];

    % Draw the 2x2 heatmaps
    for k = 1:min(S,4)
        subplot(2,2,k);
        imagesc(t_ms, 1:Subj, A{k});
        axis xy tight;
        colormap(parula);
        caxis(clim);
        colorbar;
        hold on;
        yl = ylim;
        % vertical markers at 500 and 4100 ms (use 'w' or 'k' to taste)
        plot([vx(1) vx(1)], yl, '--w', 'LineWidth', 1);
        plot([vx(2) vx(2)], yl, '--w', 'LineWidth', 1);
        hold off;
        title(sprintf('Stimulus %d — Channel %d/%d', k, ch, Ch));
        xlabel('Time (ms)'); ylabel('Subject');
    end

    drawnow;
    pause();   % step to next channel
end
