function plot_visual_eeg(X,fs)
% X format = subjects*trials*channels*datapoints
T = size(X,4);
t = (0:T-1) / fs;  % seconds
subjects=size(X,1);

groups = { [7 8], [1 14], [2 3 12 13], [4 11], [6 9], [5 10] };
names  = { {'O1','O2'}, {'AF3','AF4'}, {'F7','F3','F4','F8'}, {'FC5','FC6'}, {'P7','P8'}, {'T7','T8'} };
blend=4;
blstart=2;
for s = 1:subjects
    avgTC = squeeze(mean(X(s,:,:,:), 2, 'omitnan')).';   % [T x Ch], mean over trials only
    avgTC = avgTC(:, 1:14);
    for g = 1:6
        ax(g) = subplot(3,2,g); hold on
        plot(t, avgTC(:, groups{g}), 'LineWidth', 1);
        yl = ylim;
        line([blstart blstart], yl, 'LineStyle','--','Color','r');
        line([blend blend],     yl, 'LineStyle','--','Color','r');
        %     line([stimend stimend], yl, 'LineStyle','--','Color','r');
        %     xlim([t(1) t(end)]); grid on
        legend(names{g}, 'Location','northeast');
        if g <= 4, set(gca,'XTickLabel',[]); else, xlabel('Time (s)'); end
        title('Subject: %d', s);
    end
    %    suptitle(sprintf('Subject %d', s)); % <-- Add subject number as main title

    pause();
    clf;
end

end
