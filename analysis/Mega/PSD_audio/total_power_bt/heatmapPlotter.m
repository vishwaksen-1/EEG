% --- Setup example data table (as before) ---
bands = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2','P8','T8','FC6','F4','F8','AF4'};

nBands = numel(bands);
nCh = numel(channels);

% --- Convert to one big numeric matrix for plotting ---
bigMat = zeros(nBands*2, nCh*2);
for i = 1:nBands
    for j = 1:nCh
        rIdx = (i-1)*2 + (1:2);
        cIdx = (j-1)*2 + (1:2);
        bigMat(rIdx, cIdx) = T{i,j}{1};
    end
end

% --- Plot as a heatmap-like image ---
figure('Color','w');
imagesc(bigMat);
axis equal tight;
colormap; % blue, gray, red for -1,0,1
caxis([-1 1]);
colorbar;

% --- Add grid lines for each 2x2 cell and each big cell ---
hold on;
% Minor grid (for 2x2 subcells)
for r = 1:size(bigMat,1)
    yline(r+0.5, 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);
end
for c = 1:size(bigMat,2)
    xline(c+0.5, 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);
end
% Major grid (for main table boundaries)
for r = 0:nBands
    yline(r*2+0.5, 'k', 'LineWidth', 1.2);
end
for c = 0:nCh
    xline(c*2+0.5, 'k', 'LineWidth', 1.2);
end

% --- Label main rows and columns ---
ax = gca;
ax.XTick = 2*(1:nCh) - 0.5;
ax.XTickLabel = channels;
ax.YTick = 2*(1:nBands) - 0.5;
ax.YTickLabel = bands;
ax.XTickLabelRotation = 45;
set(ax, 'TickLength',[0 0]);

title('2x2 Matrix Heatmap per EEG Channel and Frequency Band');
