function batchProcessRestingState(input_folder)
    % batchProcessRestingState Processes all subjects in a folder.
    % Used to Process Resting State Data
    % Resting State is the collected pre-experiment EEG data where the subjects close their 
    % eyes for ~60 sec and then open their eyes for ~60 sec.
    %
    % Calls:
    %   fileGlobber
    %   processRestingStateEEG
    % Inputs:
    %   input_folder: String path to the directory containing .mat files.
    %                 If not provided, it will prompt for a folder.
    %

    if nargin < 1 || isempty(input_folder)
        input_folder = uigetdir(pwd, 'Select the folder containing EEG .mat files');
        if input_folder == 0, return; end
    end

    % 1. Find all data files and marker files using fileGlobber
    % Data files: RestingState - [SubID]_... .mat
    % Marker files: RestingState - [SubID]_... _marker.mat
    
    % Note: The regex avoids picking up marker files in the data_files list 
    % by ensuring the string ends with .mat but doesn't have _marker.
    data_files = fileGlobber('RestingState - .*(?<!_marker)\.mat$', input_folder);
    marker_files = fileGlobber('RestingState - .*_marker\.mat$', input_folder);
    
    if isempty(data_files)
        fprintf('No valid data files found in: %s\n', input_folder);
        return;
    end

    % 2. Initialize storage for all subjects
    % We will store this as a struct or a map to keep track of Subject IDs
    all_subjects_results = struct();
    subjects_processed = 0;

    fprintf('Found %d data files. Starting processing...\n', length(data_files));

    % 3. Iterate through data files and find matching marker files
    for i = 1:length(data_files)
        data_filename = data_files{i};
        
        % Extract Subject ID (ns1, ns2, etc.) 
        % Pattern: "RestingState - " followed by the ID until the first underscore
        tokens = regexp(data_filename, 'RestingState - ([^_]+)_', 'tokens');
        if isempty(tokens)
            continue; 
        end
        subID = tokens{1}{1};
        
        % Find the corresponding marker file for this specific subID
        % We look for the marker file that contains the same subID
        match_idx = contains(marker_files, ['RestingState - ' subID '_']);
        
        if ~any(match_idx)
            warning('No matching marker file found for subject: %s. Skipping.', subID);
            continue;
        end
        
        marker_filename = marker_files{match_idx};
        
        % 4. Load the files
        % Loading data file creates 'T_data_cleaned'
        % Loading marker file creates 'T_markers_data'
        try
            data_path = fullfile(input_folder, data_filename);
            marker_path = fullfile(input_folder, marker_filename);
            
            d_load = load(data_path);
            m_load = load(marker_path);
            
            % Check if variables exist in the loaded structures
            if isfield(d_load, 'T_data_cleaned') && isfield(m_load, 'T_markers_data')
                
                % 5. Process using the function
                % resting_state_cell is 1x2 {EyesClosed, EyesOpen}
                resting_state_cell = processRestingStateEEG(d_load.T_data_cleaned, m_load.T_markers_data);
                
                % Store in result structure
                all_subjects_results.(subID) = resting_state_cell;
                subjects_processed = subjects_processed + 1;
                fprintf('Successfully processed: %s\n', subID);
            else
                warning('Variable names mismatch in files for %s', subID);
            end
            
        catch ME
            fprintf('Error processing subject %s: %s\n', subID, ME.message);
        end
    end

    % 6. Save the final aggregated cell array
    % We convert the struct values to a single cell array if preferred, 
    % but keeping it as a struct or a cell of cells is safer.
    final_output_name = fullfile(input_folder, 'All_Subjects_Resting_State.mat');
    
    % Converting struct to a cell array of subjects for easy indexing
    % Each row: {SubID, {EyesClosed, EyesOpen}}
    all_data_cell = [fieldnames(all_subjects_results), struct2cell(all_subjects_results)];
    
    save(final_output_name, 'all_data_cell');
    fprintf('\nProcessing complete. %d subjects saved to:\n%s\n', subjects_processed, final_output_name);
end