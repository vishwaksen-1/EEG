function all_data = segmentAllEEG(folder)
% segment_all_eeg - Segments and processes all EEG data files in a given folder.
%   This function uses fileGlobber to find all valid data files, then
%   iterates through them, calling segment_eeg_data for each file and
%   storing the results in a single large cell array.
%
%   Args:
%       folder (string): The path to the folder containing the data files.
%
%   Returns:
%       all_data (cell): A cell array where each row contains the db
%                        output for a single subject.

% 1. Find all valid data files using fileGlobber
% The regex pattern excludes files with '_marker.mat' or '_cleaning_stats.txt'
addpath 'D:\auditory_perrand_data_code\eeg_perrand_analysis_5725\Utils'

file_ending_regex = '.*(?<!_marker|_cleaning_stats)\.mat$';
files = fileGlobber(file_ending_regex, folder);

if isempty(files)
    error('No valid .mat files found in the specified folder.');
end

disp(['Found ' num2str(numel(files)) ' valid files to process.']);

% 2. Get parameters from the first valid file
firstFile = files{1};
fileNameWithoutExt = firstFile(1:end-4);

% Determine experiment type (active or passive)
if contains(fileNameWithoutExt, 'act', 'IgnoreCase', true)
    experimentType = 'active';
elseif contains(fileNameWithoutExt, 'pas', 'IgnoreCase', true)
    experimentType = 'passive';
else
    error('Could not determine experiment type from filename. Expected ''act'' or ''pas''.');
end

% Determine set number (set0, set1, or set2)
if contains(fileNameWithoutExt, 'set1', 'IgnoreCase', true)
    setno = 1;
elseif contains(fileNameWithoutExt, 'set2', 'IgnoreCase', true)
    setno = 2;
else
    setno = 0;
end

disp(' '); % Add a newline for better readability
disp(['Using experiment type: ' experimentType]);
disp(['Using set number: ' num2str(setno)]);
disp(' ');

% 3. Initialize a cell array to store the segmented data for all subjects
numSubjects = numel(files);
all_data = cell(numSubjects, 1);

% 4. Process each file sequentially
for sub = 1:numSubjects
    fileName = files{sub};
    fullPath = fullfile(folder, fileName);

    disp(['Processing file ' num2str(sub) '/' num2str(numSubjects) ': ' fileName]);

    % Load the data file
    try
        load(fullPath, 'T_data_cleaned');
    catch ME
        warning('Failed to load file %s. Skipping. Error: %s', fileName, ME.message);
        continue; % Skip to the next file
    end

    % Call the unified segmentation function
    db_act = segmentEEGData(sub, setno, T_data_cleaned, experimentType);
    
    % Store the result in the main output matrix. 
    % The subject number (sub) becomes its index.
    all_data{sub} = db_act;
    
end

disp(' '); % Add a newline
disp('All files processed. Final data stored in the ''all_data'' cell array.');
end