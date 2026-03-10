function export_integrals_to_excel(integral_struct, filename)
% export_integrals_to_excel - Export integral matrices to Excel in 2x2 grid format.
%
% Usage:
%   export_integrals_to_excel(integral_struct, 'MyResults.xlsx')
%
% Description:
%   Creates an Excel file with 5 sheets (one per integral type).
%   In each sheet, the data is organized as a (2*nCh) x (2*nCh) matrix.
%   Each (i, j) channel interaction is represented by a 2x2 block of cells:
%       [ Stim1 (Out12_s1) , Stim2 (Out12_s2) ]
%       [ Stim3 (Out34_s1) , Stim4 (Out34_s2) ]
%
%   Rows/Cols are labeled with Channel names.

    if nargin < 2
        filename = 'CrossCorr_Integrals.xlsx';
    end

    % --- Define the 5 Metric Types to export ---
    metricFields = { ...
        'full_integral', ...
        'central_active_bias_integral', ...
        'central_baseline_integral', ...
        'central_active_bias_baseline_integral', ...
        'diff_integral' ...
    };
    
    sheetNames = { ...
        'Full_Active_vs_Bias', ...
        'Central_Active_vs_Bias', ...
        'Central_Base_vs_Bias', ...
        'Central_Active_vs_All', ...
        'Difference_Active_Base' ...
    };

    % --- Locate the 4 Data Sources (Stim 1,2,3,4) ---
    % Mapping:
    % S1: Out12 -> 1st stim
    % S2: Out12 -> 2nd stim
    % S3: Out34 -> 1st stim
    % S4: Out34 -> 2nd stim
    
    [src1, src2] = get_stim_sources(integral_struct, 'Out12');
    [src3, src4] = get_stim_sources(integral_struct, 'Out34');
    
    sources = {src1, src2, src3, src4};
    
    % --- Determine Matrix Dimensions (nCh) ---
    nCh = 0;
    for k = 1:4
        if ~isempty(sources{k})
            % Check dimension of the first available metric
            fnames = fieldnames(sources{k});
            if ~isempty(fnames)
                sampleMat = sources{k}.(fnames{1});
                nCh = size(sampleMat, 1);
                break;
            end
        end
    end
    
    if nCh == 0
        error('Could not determine channel count. Check input structure.');
    end
    
    fprintf('Detected %d Channels. Exporting to "%s"...\n', nCh, filename);

    % --- Loop through each Metric and Export ---
    for m = 1:numel(metricFields)
        metric = metricFields{m};
        sheet = sheetNames{m};
        
        fprintf('  Processing sheet: %s... ', sheet);
        
        % 1. Extract the 4 matrices for this metric
        M1 = get_matrix(sources{1}, metric, nCh); % Stim 1
        M2 = get_matrix(sources{2}, metric, nCh); % Stim 2
        M3 = get_matrix(sources{3}, metric, nCh); % Stim 3
        M4 = get_matrix(sources{4}, metric, nCh); % Stim 4
        
        % 2. Construct the Interleaved Matrix (2*nCh x 2*nCh)
        % Initialize with NaNs
        BigMat = nan(2*nCh, 2*nCh);
        
        % Fill Grid:
        % Rows 1,3,5... Cols 1,3,5... -> Stim 1
        BigMat(1:2:end, 1:2:end) = M1;
        
        % Rows 1,3,5... Cols 2,4,6... -> Stim 2
        BigMat(1:2:end, 2:2:end) = M2;
        
        % Rows 2,4,6... Cols 1,3,5... -> Stim 3
        BigMat(2:2:end, 1:2:end) = M3;
        
        % Rows 2,4,6... Cols 2,4,6... -> Stim 4
        BigMat(2:2:end, 2:2:end) = M4;
        
        % 3. Prepare Labels for Excel
        % Headers: Ch1, Ch1, Ch2, Ch2...
        labels = cell(1, 2*nCh);
        for i = 1:nCh
            labels{2*i-1} = sprintf('Ch%d', i);
            labels{2*i}   = sprintf('Ch%d', i);
        end
        
        % Combine Labels and Data
        % Output cell array: [Empty, Labels; Labels', Data]
        outputCell = cell(2*nCh + 1, 2*nCh + 1);
        outputCell(1, 2:end) = labels;      % Top Header
        outputCell(2:end, 1) = labels';     % Left Header
        
        % Convert data to cell for assignment
        dataCell = num2cell(BigMat);
        outputCell(2:end, 2:end) = dataCell;
        
        % 4. Write to Excel
        writecell(outputCell, filename, 'Sheet', sheet);
        fprintf('Done.\n');
    end
    
    fprintf('✅ Export Complete.\n');
end


% ================= HELPER FUNCTIONS =================

function [sA, sB] = get_stim_sources(structIn, outName)
    % Extracts the two stim substructures from a given OutXX field
    sA = []; sB = [];
    if isfield(structIn, outName)
        % Find field names containing 'stim' or 'seg'
        fnames = fieldnames(structIn.(outName));
        mask = (contains(fnames, 'stim') | contains(fnames, 'seg')) & ~contains(fnames, 'raw');
        validNames = sort(fnames(mask)); % Sort ensures Stim1 comes before Stim2
        
        if numel(validNames) >= 1
            sA = structIn.(outName).(validNames{1});
        end
        if numel(validNames) >= 2
            sB = structIn.(outName).(validNames{2});
        end
    end
end

function M = get_matrix(sourceStruct, fieldName, nCh)
    % Extracts matrix from struct. Returns NaN matrix if missing.
    if ~isempty(sourceStruct) && isfield(sourceStruct, fieldName)
        M = sourceStruct.(fieldName);
    else
        M = nan(nCh, nCh);
    end
end