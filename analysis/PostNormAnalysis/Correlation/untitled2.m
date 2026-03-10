ch1 = 2;
ch2 = 12;

mean1 = squeeze(ccorr.mean(ch1, ch2, :));
std1 = squeeze(ccorr.std(ch1, ch2, :));
CI1 = 1.96 * std1;
lags = lags';
figure;

hold on;
plot(lags, mean1+CI1, '-r');
plot(lags, mean1, 'b', 'LineWidth', 2);
plot(lags, mean1-CI1, '-r');
hold off;
xlabel('Lag (s)');
ylabel('F7 vs F4');