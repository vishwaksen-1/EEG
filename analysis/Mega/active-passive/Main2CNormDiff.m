% bootstrap_plot_eachChannel_allVars_subplots_ms.m
% One figure per channel
% Each figure has subplots for stim1–4 × varNames (raw, subNorm, subNormByGlobalBaseline)
% Bootstrap mean ± 95% CI (filled area)
% Time axis in milliseconds (fs = 256 Hz)

%clearvars -except actnorm passnorm
close all
rng('default')

%% Parameters
nBoot = 2000;      % bootstrap iterations
alpha = 0.05;      % 95% CI
fs = 256;          % sampling frequency (Hz)
saveFigs = false;  % set true to save each channel figure
saveDir = 'ChannelFigs_AllVars_Subplots';
channels = {'AF3','F7','F3','FC5','T7','P7','O1','O2','P8','T8','FC6','F4','F8','AF4'};

stimNames = {'stim1','stim2','stim3','stim4'};
varNames  = {'raw','subNorm','subTrialNorm'};

colors = lines(numel(stimNames));

%% Checks
if ~exist('actnorm','var') || ~exist('passnorm','var')
    error('Please load actnorm and passnorm structs first.');
end
if ~isfield(actnorm,'Out12') || ~isfield(passnorm,'Out12') ...
   || ~isfield(actnorm,'Out34') || ~isfield(passnorm,'Out34')
    error('actnorm/passnorm missing Out12 or Out34 fields.');
end

%% Create difference structure dynamically (handling stim3/stim4 mapping)
for s = 1:numel(stimNames)
    for v = 1:numel(varNames)
        stim = stimNames{s};
        var  = varNames{v};
        if s <= 2
            % stim1 and stim2 from Out12
            A = actnorm.Out12; P = passnorm.Out12;
            stimField = stim;  % same name
        else
            % stim3, stim4 from Out34 but stored as stim1, stim2
            A = actnorm.Out34; P = passnorm.Out34;
            stimField = sprintf('stim%d', s-2); % map stim3->stim1, stim4->stim2
        end
        Diff.(stim).(var) = A.([stimField '_' var]) - P.([stimField '_' var]);
    end
end

%% Bootstrap helper
function [bootMean, ciLow, ciHigh] = bootstrapOverSubjects(data, nBoot, alpha)
    % data: subj x time
    [ns, nt] = size(data);
    mBoot = zeros(nBoot, nt);
    for b = 1:nBoot
        idx = randi(ns, ns, 1);
        mBoot(b,:) = mean(data(idx,:), 1);
    end
    bootMean = mean(mBoot, 1);
    ciLow = prctile(mBoot, 100*alpha/2, 1);
    ciHigh = prctile(mBoot, 100*(1-alpha/2), 1);
end

%% Bootstrap and plot per channel
fprintf('Running bootstrap (%d samples) for each channel, stim, and variable...\n', nBoot);

nChan = numel(channels);
[~,~,nt] = size(Diff.stim1.raw);
timeAxis = ((0:nt-1) / fs) * 1000;  % convert to ms

if saveFigs && ~exist(saveDir,'dir')
    mkdir(saveDir);
end

for c = 1:nChan
    fig = figure('Name',sprintf('Channel %s',channels{c}), ...
                 'Units','normalized','Position',[0.05 0.05 0.85 0.85]);
    
    plotIndex = 0;
    for s = 1:numel(stimNames)
        figure;
        for v = 1:numel(varNames)
            plotIndex = plotIndex + 1;
            % subplot(numel(stimNames), numel(varNames), plotIndex)
            hold on
            
            data = squeeze(Diff.(stimNames{s}).(varNames{v})(:,c,:)); % subj x time
            [m, lo, hi] = bootstrapOverSubjects(data, nBoot, alpha);
            
               m = (m - min(m))/(max(m) -  min(m));

            % Plot shaded CI
            % fill([timeAxis fliplr(timeAxis)], [lo fliplr(hi)], ...
                % colors(s,:), 'FaceAlpha', 0.25, 'EdgeColor','none');
            plot(timeAxis, m, 'Color', colors(v,:), 'LineWidth', 1.5);
            
            title(sprintf('%s – %s', stimNames{s}, varNames{v}), 'Interpreter','none');
            xlabel('Time (ms)');
            ylabel('Amplitude (a.u.)');
            grid on; box on;
            xlim([timeAxis(1) timeAxis(end)]);
            yline(0);
            legend show
        end
        hold off
    end
    
    % sgtitle(sprintf('Channel: %s — Bootstrap mean ± 95%% CI', channels{c}));
    
    if saveFigs
        saveas(fig, fullfile(saveDir, sprintf('Channel_%s.png', channels{c})));
    end
    
    fprintf('Showing channel %s (%d/%d). Press any key for next...\n', ...
        channels{c}, c, nChan);
    pause;
end

fprintf('All channel subplots done.\n');
