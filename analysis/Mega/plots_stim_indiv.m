%%% ---- Params & time axis ----
fs = 256;                                   % Hz
[T, Ch, S, Tr, Subj] = size(A5);
t_ms = (0:T-1)/fs*1000;                      % 0 .. 6500 ms
vx = [500 4100];                             % vertical markers (ms)

%% ---- Per-stimulus, per-subject trial means + mean & SEM across subjects ----
Msub  = cell(S,1);   % [T x Ch x Subj]
Mmean = cell(S,1);   % [T x Ch]
Msem  = cell(S,1);   % [T x Ch]

for k = 1:S
    % Avg trials within subject, keep subjects
    tmp = mean(A5(:,:,k,:,:), 4, 'omitnan');     % [T x Ch x 1 x 1 x Subj]
    X   = squeeze(tmp);                          % [T x Ch x Subj]
    Msub{k} = X;

    % NaN-safe mean & SEM across subjects
    mask = ~isnan(X);
    N    = sum(mask, 3);
    X0   = X; X0(~mask) = 0;

    S1   = sum(X0, 3);                           % sum x
    M    = S1 ./ max(N,1);  M(N==0) = NaN;       % mean

    S2   = sum(X0.^2, 3);                        % sum x^2
    V    = (S2 - (S1.^2)./max(N,1)) ./ max(N-1,1);  % unbiased var
    V(N<=1) = NaN;
    SEM  = sqrt(V) ./ sqrt(max(N,1));  SEM(N==0) = NaN;

    Mmean{k} = M;
    Msem{k}  = SEM;
end

%% ---- Plot all channels, pausing between each ----
f = figure('Name','Stimulus-wise mean±SEM per channel'); set(f,'Color','w');

for ch = 1:Ch
    clf(f);

    for k = 1:min(S,4)      % 4 subplots (1 per stimulus)
        subplot(2,2,k); hold on; grid on;

        % faint per-subject lines
        for s = 1:Subj
            y = Msub{k}(:, ch, s);
            if all(isnan(y)), continue; end
            plot(t_ms, y, 'Color', [0.75 0.85 1], 'LineWidth', 0.5);
        end

        % mean ± SEM across subjects
        y  = Mmean{k}(:, ch);
        se = Msem{k}(:, ch);
        if ~all(isnan(y))
            fill([t_ms, fliplr(t_ms)], [ (y-se).', fliplr((y+se).') ], [0.3 0.5 1], ...
                 'FaceAlpha', 0.20, 'EdgeColor','none');
            plot(t_ms, y, 'b', 'LineWidth', 1.8);
        end

        % vertical markers (R2016)
        yl = ylim;
        plot([vx(1) vx(1)], yl, '--k');
        plot([vx(2) vx(2)], yl, '--k');

        title(sprintf('Stimulus %d — Channel %d/%d', k, ch, Ch));
        xlabel('Time (ms)'); ylabel('Amplitude');
        hold off;
    end

    drawnow;
    pause();   % <-- step through channels
end

%% ---- Plot four subplots (one per stimulus) for channel 'ch' ----
figure('Name', sprintf('Channel %d/%d — Stimulus-wise mean±SEM', ch, Ch));

for k = 1:min(S,4)                 % show up to 4 stims
    subplot(2,2,k); hold on; grid on;

    % faint per-subject lines
    base = 0.70;                    % lighten toward white
    pcol = base + (1-base)*lines(1); % simple light blue-ish; change if you want
    for s = 1:Subj
        plot(t_ms, Msub{k}(:,ch,s), 'Color', [0.6 0.7 1], 'LineWidth', 0.5);
    end

    % mean ± SEM
    y  = Mmean{k}(:, ch);
    se = Msem{k}(:, ch);
    fill([t_ms, fliplr(t_ms)], [ (y-se).', fliplr((y+se).') ], [0.3 0.5 1], ...
         'FaceAlpha', 0.20, 'EdgeColor', 'none');
    plot(t_ms, y, 'b', 'LineWidth', 1.8);

    % vertical markers (R2016: use plot, not xline)
    yl = ylim;
    plot([vx(1) vx(1)], yl, '--k');
    plot([vx(2) vx(2)], yl, '--k');

    title(sprintf('Stimulus %d — Channel %d/%d', k, ch, Ch));
    xlabel('Time (ms)'); ylabel('Amplitude'); hold off;
end
