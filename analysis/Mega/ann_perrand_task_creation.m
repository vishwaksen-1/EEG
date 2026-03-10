    %% generate and play 80 periodic and aperiodic stimuli withgui and also trigering eeg recording
% stores data to : C:/Users/ipl_i/Documents/MATLAB/Sound/exp data/periodic aperiodic data <name>.mat

clc;
clear;

%% generate/load stimulli with intertoken gap 70ms
% ********generate only once and use same stimulus for all subjects**********
%ann- comment below two lines whiel acquisition happens
%[stimuli_iti, jablingOrder] = generatePeriodicAperiodicAudio();
%save("C:\Users\ipl_i\Documents\MAT LAB\Sound\stimuli_iti.mat","stimuli_iti", "jablingOrder");
load("C:\Users\ipl_i\Documents\MATLAB\Sound\stimuli_iti.mat")
%% get subject information
addpath("Sound\")
[name, age, sex] = getUserInfoUI();
%% start task
clickedOnToken = periodicAperiodicTaskGUI(stimuli_iti, name);
%% post task analysis
jablingOrder = jablingOrder';
h = zeros(1,8);
for i = 1:length(clickedOnToken)
    c = clickedOnToken{i};
    h(jablingOrder(c)) = h(jablingOrder(c)) + 1;
end
plot(h, 'marker', 'o');
save(sprintf("C:/Users/ipl_i/Documents/MATLAB/Sound/exp data/periodic aperiodic data %s.mat", name), ...
    "clickedOnToken", "name", "sex","age","jablingOrder", "h");
% acc = (sum(h(1:10)) + 30 - sum(h(10:16)))/80;
% acc = round(acc * 100);
% 
% fprintf("Accuracy : %d percent.\n", acc)

%% the end
%% the task function
function clickedOnToken = periodicAperiodicTaskGUI(stimuli_iti, name)
recordEEG = 1;% zero when device nt conencted , and 1 when acquisiition happens
fs = 44100;
t_rest = 10;%10 sec resting before every GUI on
t_stimulus = 3.6;
t_interval = 2.9;
n_tokens=80;% number  of repetitions NTRIAL*NSTIM
clickedOnToken = [];
tokenPlayed = 0;
%% Start EEG Recording
if nargin == 1, name = "testtitle"; end
title = sprintf("%s periodic_aperiodic %s", name, datestr(now, 'yyyymmdd_HHMMss'));
addpath("Emotiv\"); % path for EmotivX
fig = uifigure;
uiprogressdlg(fig,'Title','Connection to Emotiv', 'Indeterminate','on');
emotivX = EmotivX(title, recordEEG);
delete(fig);

%% GUI
display = get(0, 'ScreenSize');
w = display(3); h=display(4);

f = figure('Position', [w*.25, h*.25, w*.5, h*.5], 'MenuBar', 'none', ...
    'Name', 'Audio Task', 'NumberTitle', 'off', ...
    'CloseRequestFcn', @closeGUI,...
    'KeyPressFcn', @keyPressHandler);

w = w*.5; h=h*.5;

countdownLabel = uicontrol('Style', 'text', 'Position', [w*.1, h*.55, w*.8, h*.35], ...
    'FontSize', 32, 'String', 'Press Space Bar or Green Button to start countdown.');

startButton = uicontrol('Style', 'pushbutton', 'Position', [w*.1, h*.1, w*.35, h*.35], ...
    'String', 'Start Countdown', 'FontSize', 16,...
    'BackgroundColor', 'green',...
    'Callback', @start);

toggleButton = uicontrol('Style', 'pushbutton', 'Position', [w*.55, h*.1, w*.35, h*.35], ...
    'String', 'Press SPACE BAR', 'FontSize', 16,...
    'Enable', 'off', ...
    'Callback', @onClick);

% progressBar = uipanel('Position', [0, 0, 0, 0.05], 'BorderType', 'none', 'BackgroundColor', 'green');

player = audioplayer(stimuli_iti, fs);
player.StartFcn = @(obj, event) emotivX.injectMarker("Play Sound",1);
player.StopFcn = @(obj, event) emotivX.injectMarker("End Sound",2);

uiwait(f); % pause execution until the figure is closed % otherwise empty values will be returned


    function start(~, ~)
        set(startButton, 'Enable', 'off');
        set(startButton, 'BackgroundColor', [0.94, 0.94, 0.94])

        restingState(t_rest)

        set(toggleButton, 'Enable', 'on');
        set(countdownLabel, 'String', 'Press button when audio is PERIODIC');
        playSound()
        pause (0.5)

        tic
      while ishandle(f) 
            set(toggleButton, 'Enable', 'off');
            set(toggleButton, 'BackgroundColor', [0.94, 0.94, 0.94])
            pause(t_stimulus);
            if ishandle(f) 
                set(toggleButton, 'Enable', 'on');
                set(toggleButton, 'BackgroundColor', 'green')
                tokenPlayed = tokenPlayed +1;
                % set(progressBar, 'Position', [0, 0, tokenPlayed/n_tokens, 0.05]);
                pause(t_interval);
            end
            if tokenPlayed==n_tokens, break; end
        end
        toc % 448.133641 seconds. // should be 449-.5-.9 = 447.6

        if ishandle(f) , set(countdownLabel, 'String', 'Resting State, Keep Clam'); end
        pause(2)
        if ishandle(f) , restingState(t_rest); end
        if ishandle(f) , closeGUI(); end

    end

    function restingState(t)
        emotivX.injectMarker("RS start",3);% at teh beginning of countdown after pressing start 
        for i = t:-1:0
            set(countdownLabel, 'String', num2str(i));
            pause(1);
        end
        emotivX.injectMarker("RS end",4);% at teh end of countdown after pressing start 
    end

    function onClick(~, ~)
        emotivX.injectMarker("clicked",tokenPlayed);
        clickedOnToken{end + 1} = tokenPlayed;
        set(toggleButton, 'Enable', 'off');
        set(toggleButton, 'BackgroundColor', [0.94, 0.94, 0.94])
    end
    function keyPressHandler(~, event)
        if strcmp(event.Key, 'space')
            % emotivX.injectMarker("clicked sb",tokenPlayed);
            if strcmp(get(startButton, 'Enable'), 'on')
                start()
            elseif strcmp(get(toggleButton, 'Enable'), 'on')
                onClick()
            end
        end
    end
    function closeGUI(~, ~)
        if isplaying(player), stop(player); end

        % End EEG
        pause(2);
        emotivX.close;

        delete(f);
        clear("toggleButton");
    end

    function playSound()
        disp("play")
        play(player);
    end
end




%% generate 80 periodic aperiodic audio stimuli with intertoken gap 70ms
function [stimuli_iti, jablingOrder] = generatePeriodicAperiodicAudio()
%% Units
kHz = 1000;
ms = 0.001;
sec = 1;
n_trial_per_stim=10;%please change the trials ; so total 80 trials 
n_stim=8;
%% Params
duration = 30 * ms;
int_tokn_int_ms = [70 * ms,120 * ms,170*ms, 270*ms];
interStimuliInterval = 2.9 * sec;
durationRestingState1 = 500 * ms;
durationRestingState2 = 900 * ms;
ramp_duration = min(0.01, duration/10)*sec; % fadeIn, fadeOut time for each token
amplitude = 1;
freq1 = 1 * kHz;
freq2 = 2.5 * kHz; % Approx 1.3 octave apart from freq1
fs = 44100; % Sampling Rate audio generation
T = 3.6 * sec; % Total time

%% Token Generattion
t = 0:1/fs:(duration-1/fs); % Time bins
ramp_sample_size = round(fs*ramp_duration);
fadeIn = 0:1/ramp_sample_size:(1-1/ramp_sample_size);
fadeOut = (1-1/ramp_sample_size):-1/ramp_sample_size:0;
amp = amplitude * [fadeIn, ones(1, length(t) - 2*ramp_sample_size) , fadeOut];
tone1 = amp .* sin(2*pi*freq1*t);
tone2 = amp .* sin(2*pi*freq2*t);
interStimuliSilent = zeros(1,int64(fs * interStimuliInterval));
rest1Silent = zeros(1,int64(fs * durationRestingState1));
rest2Silent = zeros(1,int64(fs * durationRestingState2));
gap1=zeros(1,fix(int_tokn_int_ms(1)*fs));
       gap2=zeros(1,fix(int_tokn_int_ms(2)*fs));
          gap3=zeros(1,fix(int_tokn_int_ms(3)*fs));
             gap4=zeros(1,fix(int_tokn_int_ms(4)*fs));
%% Generate Stimuli for gap 70 ms
% % % % p = [];
% % % % for i=1:6, p = [p,'','112222'(randperm(6))] end
 pattern70=load('newgaps_perrand.mat');
pattern70=pattern70.newgaps_perrand;
% pattern70 = [
%     repmat('122', 1, 12);
%     '221212122212212122212212122221122212';
%     repmat('221', 1, 12);
%     '112121211121121211121121211121121121';
%     repmat('122', 1, 8),'000000000000';
%     '221212122212212122212212','000000000000';
%     repmat('221', 1, 8),'000000000000';
%     '112121211121121211121121','000000000000';
%     repmat('122', 1, 6),'000000000000000000';
%     '221212122212212122','000000000000000000';
%     repmat('221', 1, 6),'000000000000000000';
%     '112121211121121211','000000000000000000';
%     repmat('122', 1, 4),'000000000000000000000000000000000000';
%     '221212122212','000000000000000000000000000000000000';
%     repmat('221', 1, 4),'000000000000000000000000000000000000';
%     '112121211121','000000000000000000000000000000000000'];
% for i = 1:n_stim
%     row = [];
%     if ismember(i, 1:4)
%         interTokenSilent = zeros(1, int64(fs * interTokenInterval(1)));
%     elseif ismember(i, 5:8)
%         interTokenSilent = zeros(1, int64(fs * interTokenInterval(2)));
%     elseif ismember(i, 9:12)
%         interTokenSilent = zeros(1, int64(fs * interTokenInterval(3)));
%     elseif ismember(i, 13:16)
%         interTokenSilent = zeros(1, int64(fs * interTokenInterval(4)));
%     end
% 
%     for j = 1:size(pattern70,2)
%         if pattern70(i,j)=='1', row = [row, tone1, interTokenSilent];
%         elseif pattern70(i,j)=='2', row = [row, tone2, interTokenSilent];end
%     end
%     stimuli70_b(i,:) = row;
% end
% 
% %interTokenSilent = zeros(1,int64(fs * interTokenInterval));
% 
stimuli70_b=cell(n_stim,36);
% chnage teh i and j values according to teh stimulus numbersa snd set 
for i=1:2
    for j=1:36
 
        if pattern70(i,j)== 1
           stimuli70_b{i,j}=[tone1 gap1];
        else
            stimuli70_b{i,j}=[tone2 gap1];
        end
    end
end

for i=3:4
    for j=1:24
 
        if pattern70(i,j)== 1
           stimuli70_b{i,j}=[tone1 gap2];
        else
            stimuli70_b{i,j}=[tone2 gap2];
        end
    end
end

for i=5:6
    for j=1:18
 
        if pattern70(i,j)== 1
           stimuli70_b{i,j}=[tone1 gap3];
        else
            stimuli70_b{i,j}=[tone2 gap3];
        end
    end
end

for i=7:8
    for j=1:12
 
        if pattern70(i,j)== 1
           stimuli70_b{i,j}=[tone1 gap4];
        else
            stimuli70_b{i,j}=[tone2 gap4];
        end
    end
end

stimuli_iti = rest1Silent;%  trials data
jablingOrder = [];
for i = 1:n_trial_per_stim %
    jablingOrder_ = randperm(n_stim);
    jablingOrder = [jablingOrder; jablingOrder_];
    for j = jablingOrder_
        stimuli_iti = [stimuli_iti,  cell2mat(stimuli70_b(j,:)), interStimuliSilent];
    end
end
stimuli_iti = [stimuli_iti, rest2Silent];
end






