function partitionFiles(input_directory)
% partitionFiles Partitions files in a directory into 'active' and 'passive'.
%
%   partitionFiles(input_directory)
%
%   This function scans all files within the specified input_directory.
%   If a filename contains the substring 'act', the file is copied to a new
%   subdirectory named 'active'. If a filename contains 'pass', it's
%   copied to a new subdirectory named 'passive'.
%
%   Input:
%       input_directory (string): The full path to the directory containing
%                                 the files you want to partition.
%
%   Example:
%       % Create a dummy directory and some files for testing
%       mkdir('my_test_folder');
%       fclose(fopen('my_test_folder/data_act_01.txt', 'w'));
%       fclose(fopen('my_test_folder/data_pass_01.txt', 'w'));
%       fclose(fopen('my_test_folder/report_active.csv', 'w'));
%       fclose(fopen('my_test_folder/summary_passive.doc', 'w'));
%       fclose(fopen('my_test_folder/another_file.txt', 'w'));
%
%       % Run the function on the test folder
%       partitionFiles('my_test_folder');
%
%       % After running, 'my_test_folder' will contain two new folders:
%       % 'active' with 'data_act_01.txt' and 'report_active.csv'
%       % 'passive' with 'data_pass_01.txt' and 'summary_passive.doc'

    % --- 1. Input Validation ---
    % Check if the user has provided an input directory.
    if nargin < 1
        error('Please provide the path to the directory.');
    end

    % Check if the provided path is actually a directory.
    if ~isfolder(input_directory)
        error('The specified path is not a valid directory: %s', input_directory);
    end

    % --- 2. Create Destination Folders ---
    % Define the paths for the new 'active' and 'passive' folders.
    active_folder = fullfile(input_directory, 'active');
    passive_folder = fullfile(input_directory, 'passive');

    % Create the 'active' directory if it doesn't already exist.
    % The 'exist' function returns 7 if the path is a directory.
    if ~exist(active_folder, 'dir')
        mkdir(active_folder);
        fprintf('Created directory: %s\n', active_folder);
    end

    % Create the 'passive' directory if it doesn't already exist.
    if ~exist(passive_folder, 'dir')
        mkdir(passive_folder);
        fprintf('Created directory: %s\n', passive_folder);
    end

    % --- 3. Get File List ---
    % Get a list of all files and folders in the input directory.
    files_info = dir(input_directory);

    % --- 4. Process and Copy Files ---
    fprintf('Starting to partition files...\n');
    % Loop through each item in the directory.
    for i = 1:length(files_info)
        % Get the name of the current item.
        current_name = files_info(i).name;

        % Check if the current item is a file (not a directory).
        if ~files_info(i).isdir
            % Construct the full path for the source file.
            source_file = fullfile(input_directory, current_name);

            % Check if filename contains 'act' (case-insensitive).
            if contains(lower(current_name), 'act')
                % Construct the destination path.
                destination_file = fullfile(active_folder, current_name);
                % Copy the file.
                copyfile(source_file, destination_file);
                fprintf('Copied "%s" to active folder.\n', current_name);

            % Check if filename contains 'pass' (case-insensitive).
            elseif contains(lower(current_name), 'pass')
                % Construct the destination path.
                destination_file = fullfile(passive_folder, current_name);
                % Copy the file.
                copyfile(source_file, destination_file);
                fprintf('Copied "%s" to passive folder.\n', current_name);
            end
        end
    end

    fprintf('File partitioning complete.\n');
end