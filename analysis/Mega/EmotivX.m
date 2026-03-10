%% simple class to start/stop eeg recording and send markers
% Follow the instructions in '/java/Instructions.txt' for one time setup.
% No need to repeat the Instructions every time you open matlab.


% Example use case

% addpath("Emotiv\"); % path for EmotivX
% fig = uifigure;
% uiprogressdlg(fig,'Title','Connection to Emotiv', 'Indeterminate','on'); % just show a progress bar
% emotivX = EmotivX(title, recordEEG);% srart eeg recording
% delete(fig);

% markerLabel = "example Marker";
% markerValue = 1; % any positive intger
% emotivX.injectMarker(markerLabel,markerValue); % send a marker

% emotivX.close; % end recording




classdef EmotivX

    properties
        % IPLIITKGP app3 no eeg access
        client_secret = "xmnp1JH6tCGRUe1AqtVfgHkcg1rjIvmrq92wyjgFCrPzt4BcwDQwDPro14eqw7D7OEsX14aq8NkU4SoozLZsRrbp5MsdDzdlBzEMOw4Yv172363yDSfBK5mtsKlqsswt";
        client_id = "O1WSSeOr48yXXJxsAWA2LdH1FCQ6Fvjmx68xPkSN";
        title
        cortex
        enabled
    end

    methods

        function obj = EmotivX(title, enabled)
            obj.title = title;
            obj.enabled = enabled;
            if enabled
                % import mirza.rohan.ahamed.CortexApp
                % create and start recording
                obj.cortex = mirza.rohan.ahamed.CortexApp(obj.client_id, obj.client_secret,title);
            end
        end


        function injectMarker(obj, label, value)
            if obj.enabled
                fprintf("marker: %s\n",label);
                obj.cortex.injectMarker(label, value);
            end
        end

        function close(obj)
            if obj.enabled
                obj.cortex.close();
            end
        end
    end
end
