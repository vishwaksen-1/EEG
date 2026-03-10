function plot_shifted_channels(A5, fs)
blstart=0.2;
blend=0.5;
channels=1:14;
stimend=4.1;
T = size(A5,1);
t = (0:T-1) / fs;  % seconds
subjects=size(A5,5);

groups = { [7 8], [1 14], [2 3 12 13], [4 11], [6 9], [5 10] };
names  = { {'O1','O2'}, {'AF3','AF4'}, {'F7','F3','F4','F8'}, {'FC5','FC6'}, {'P7','P8'}, {'T7','T8'} };

for s = 1:subjects
     %Average across Stim and Trials
     avgTC = squeeze(mean(mean(A5(:,:,:, :, s), 3, 'omitnan'), 4, 'omitnan'));  % [T x Ch]
    % avgTC = squeeze(mean(mean(mean(A5(:,:,:, :, :), 3, 'omitnan'), 4, 'omitnan'), 5, 'omitnan'));
     avgTC = avgTC(:, 1:14);                   
    % 
for g = 1:6
    ax(g) = subplot(3,2,g); hold on
    plot(t, avgTC(:, groups{g}), 'LineWidth', 1);
    yl = ylim;
    line([blstart blstart], yl, 'LineStyle','--','Color','r');
    line([blend blend],     yl, 'LineStyle','--','Color','r');
    line([stimend stimend], yl, 'LineStyle','--','Color','r');
    xlim([t(1) t(end)]); grid on
    legend(names{g}, 'Location','northeast');
    if g <= 4, set(gca,'XTickLabel',[]); else, xlabel('Time (s)'); end
end
    sgtitle(sprintf('Subject %d', s)); % <-- Add subject number as main title

    pause();
    clf;
end
end
