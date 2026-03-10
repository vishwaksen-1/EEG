function matching_files = fileGlobber(file_ending_regex, folder)
% FILEGLOBBER Finds files in a folder that match a regular expression. Used by many scripts/functions
%
%   matching_files = fileGlobber(file_ending_regex, folder)
%   
%   Inputs:
%       file_ending_regex (string): The regular expression to match against
%                                   the filenames. For example, '.*\.csv$'
%                                   will match all files ending in .csv.
%
%       folder (optional, string): The path to the folder to search. If
%                                  this parameter is not provided, it
%                                  defaults to a specific path.
%
%   Output:
%       matching_files (cell array): A cell array containing the names of
%                                    the files that matched the regular
%                                    expression.
%
%   Examples:
%       % 1. General CSV file list
%       csv_files = fileGlobber('.*\.csv$');
%
%       % 2. Specifically for EEG Data files (e.g., 'filename.md.csv')
%       eeg_data_files = fileGlobber('.*\.md\.csv$');
%
%       % 3. For EEG Marker data files (e.g., 'filename_intervalMarker.csv')
%       eeg_marker_files = fileGlobber('.*\_intervalMarker\.csv$');
%

    % If no arguments are provided, display the help text and exit.
    if nargin < 1
        help(mfilename);
        return;
    end

    % Define a default folder path if the folder input is not provided.
    % The 'nargin' function returns the number of input arguments.
    if nargin < 2
        folder = 'D:\auditory_perrand_data_code\data\set1\';
    end
    
    % Check if the folder exists to avoid errors.
    if ~isfolder(folder)
        error('The specified folder does not exist: %s', folder);
    end

    % Get a list of all files and folders in the specified directory.
    files_info = dir(folder);
    
    % Initialize an empty cell array to store matching filenames.
    matching_files = {}; 
    
    % Loop through the list of files and folders.
    for i = 1:length(files_info)
        filename = files_info(i).name;
        
        % Exclude directories and the special '.' and '..' entries.
        if ~files_info(i).isdir && ~strcmp(filename, '.') ...
                && ~strcmp(filename, '..')
            % Apply the regular expression to the filename.
            % 'once' ensures it stops after the first match, which is more 
            % efficient.
            if ~isempty(regexp(filename, file_ending_regex, 'once'))
                matching_files{end+1} = filename;
            end
        end
    end
end

