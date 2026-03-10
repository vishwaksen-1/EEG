% for ch1 = 1:nChannels
%             for ch2 = ch1:nChannels
%                 tic
%                 X = bootData(ch1, :)';
%                 Y = bootData(ch2, :)';
% 
%                 % Compute (biased) MIcorr
%                 [MI_vals, ~] = MIcorr(X, Y, k, maxLagSamples);
% 
%                 % Estimate bias via surrogate data
%                 biasVals = zeros(nBias, nLags);
%                 for bb = 1:nBias
%                     Ys = Y(randperm(length(Y))); % scramble Y to break dependence
%                     [biasTmp, ~] = MIcorr(X, Ys, k, maxLagSamples);
%                     biasVals(bb, :) = biasTmp;
%                 end
%                 meanBias = mean(biasVals, 1, 'omitnan');
% 
%                 % Unbiased MI
%                 MIcorrAll(b, ch1, ch2, :) = MI_vals - meanBias;
%                 MIcorrAll(b, ch2, ch1, :) = flip(MI_vals - meanBias);
%                 toc
%             end
%         end
addpath ../../../../../FileExchange/progressbar-1.2.0.0/

Fs = 256;                                  % Sampling rate (Hz)
maxLagSec = 0.5;
maxLagSamples = round(maxLagSec * Fs);     % Convert seconds → samples
nBoot = 100;                               % Bootstrap iterations
nBias = 100;                               % Number of random scrambles per MI estimate
k = 3;
%% --- Extract signal ---
validSubjects = squeeze(all(all(~isnan(signal), 2), 3));   % [nSubjects × 1]
signal = signal(validSubjects, :, :);

[nSubjects, nChannels, ~] = size(signal);

lags = (-maxLagSamples:maxLagSamples) / Fs;  % in seconds
nLags = numel(lags);


% x = randsample(nSubjects, 5);
n = 1;
progressbar(0,0)
for p=1:5
    progressbar([], 0);
    i = x(p);  % Select the subject index for bootstrapping
    bootData = squeeze(mean(signal(i, :, :), 1));  % [channels × samples]
    % Further processing of the selected signal can be added here
    u = randsample(nChannels, 2);
    % Extract the two channels for analysis
    ch1 = u(1);
    ch2 = u(2);
    tic
    X = bootData(ch1, :)';
    Y = bootData(ch2, :)';

    % Compute (biased) MIcorr
    [MI_vals, ~] = MIcorr(X, Y, k, maxLagSamples);

    % Estimate bias via surrogate data
    biasVals = zeros(nBias, nLags);
    for bb = 1:nBias
        progressbar([], 0)
        Ys = Y(randperm(length(Y))); % scramble Y to break dependence
        [biasTmp, ~] = MIcorr(X, Ys, k, maxLagSamples);
        biasVals(bb, :) = biasTmp;
        progressbar([], bb/nBias)
    end
    meanBias = mean(biasVals, 1, 'omitnan');

    % Unbiased MI
    MIcorrAll(n,1,:) = MI_vals - meanBias;
    MIcorrAll(n,2,:) = flip(MI_vals - meanBias);
    n = n+1;
    toc
    progressbar(p/5);  % Update progress for each subject
end

for i=1:5
    figure;
    subplot(1,2,1)
    plot(squeeze(MIcorrAll(i,1,:)));
    subplot(1,2,2)
    plot(squeeze(MIcorrAll(i,2,:)));
    xlabel('Lags (s)');
    ylabel('Unbiased MI');
    title(['Channel Pair: ' num2str(ch1) ' and ' num2str(ch2)]);
    pause;
end
