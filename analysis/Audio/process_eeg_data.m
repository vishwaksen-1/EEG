function process_eeg_data()
% process_eeg_data - A function to automate EEG data segmentation and averaging.
%   This script prompts the user to select a data file, extracts processing
%   parameters from the filename, and then segments, averages, and saves
%   the results into a new folder.

clc; % Clear the console for a clean run

% 1. Open a GUI to select the data file
[file, path] = uigetfile('*.mat', 'Select the cleaned EEG data file');
if isequal(file, 0)
   disp('User canceled the operation. Exiting.');
   return;
end

fullPath = fullfile(path, file);

% 2. Parse the filename to determine experiment type and set number
fileNameWithoutExt = file(1:end-4);
splitName = strsplit(fileNameWithoutExt, '_');
folderName = [splitName{1} '_' splitName{2}];

% Determine experiment type
if contains(fileNameWithoutExt, 'act', 'IgnoreCase', true)
    experimentType = 'active';
elseif contains(fileNameWithoutExt, 'pas', 'IgnoreCase', true)
    experimentType = 'passive';
else
    error('Could not determine experiment type from filename. Expected ''act'' or ''pas''.');
end

% Determine set number
if contains(fileNameWithoutExt, 'set1', 'IgnoreCase', true)
    setno = 1;
elseif contains(fileNameWithoutExt, 'set2', 'IgnoreCase', true)
    setno = 2;
else
    setno = 0;
end

disp(['Processing file: ' file]);
disp(['Detected experiment type: ' experimentType]);
disp(['Detected set number: ' num2str(setno)]);

% 3. Ask for the subject number via console
sub = input('Please enter the subject number: ');

% 4. Load the selected file
try
    load(fullPath, 'T_data_cleaned');
catch ME
    error('Failed to load file. Error: %s', ME.message);
end

% 5. Call the unified segmentation function
disp('Starting data segmentation...');
db = segmentEEGData(sub, setno, T_data_cleaned, experimentType);
disp('Segmentation complete.');

% Get the segmented data from the database cell
data = db{1,4};

% 6. Calculate the average for each stimulus
disp('Averaging data by stimulus...');

% Dynamically get the number of stimuli from the 4D matrix dimensions
numStimuli = size(data, 3);
averageDataByStimulus = zeros(size(data, 1), size(data, 2), numStimuli);

for i = 1:numStimuli
    % Select all trials for the current stimulus
    dataForStimulus = data(:,:,i,:);

    % Squeeze removes singleton dimensions (the trial dimension in this case)
    % and then we take the mean across the trials (the new 3rd dimension)
    averageDataByStimulus(:,:,i) = mean(squeeze(dataForStimulus), 3);
end

disp('Averaging complete.');

% 7. Save the averaged data
disp('Saving averaged data...');

% Create a new folder in the current directory
outputFolder = folderName;
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
    disp(['Created new folder: ' outputFolder]);
end

% Save each averaged stimulus as a separate .mat file
for i = 1:numStimuli
    filename = fullfile(outputFolder, ['averageOfStim' num2str(i) '.mat']);
    currentAverage = averageDataByStimulus(:,:,i);
    save(filename, 'currentAverage');
    disp(['Saved ' filename]);
end

disp('All files saved successfully!');

end