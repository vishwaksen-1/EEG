% normalize_and_save_MI.m
% Run this script in the workspace where 'active', 'passive', and 'visual' are loaded.
% It normalizes every MI bootstrap value by its value at lag = 0.

fprintf('Starting normalization process...\n');

% 1. Process 'active' data
if exist('active', 'var')
    active_norm = normalize_MI_struct(active);
    save('active_MI_normalized.mat', 'active_norm', '-v7.3');
    fprintf('✅ Normalized and saved: active_MI_normalized.mat\n');
else
    fprintf('⚠️ Variable "active" not found in workspace.\n');
end

% 2. Process 'passive' data
if exist('passive', 'var')
    passive_norm = normalize_MI_struct(passive);
    save('passive_MI_normalized.mat', 'passive_norm', '-v7.3');
    fprintf('✅ Normalized and saved: passive_MI_normalized.mat\n');
else
    fprintf('⚠️ Variable "passive" not found in workspace.\n');
end

% 3. Process 'visual' data
if exist('visual', 'var')
    visual_norm = normalize_MI_struct(visual);
    save('visual_MI_normalized.mat', 'visual_norm', '-v7.3');
    fprintf('✅ Normalized and saved: visual_MI_normalized.mat\n');
else
    fprintf('⚠️ Variable "visual" not found in workspace.\n');
end

fprintf('Done!\n');

% ================= HELPER FUNCTION =================
function norm_res = normalize_MI_struct(res)
    % Creates a copy of the structure and normalizes the 'vals'
    norm_res = res; 
    outNames = fieldnames(res);
    
    for o = 1:numel(outNames)
        outName = outNames{o};
        subFields = fieldnames(res.(outName));
        dataFields = subFields(contains(subFields, 'stim') | contains(subFields, 'seg'));
        dataFields = dataFields(~contains(dataFields, 'raw'));
        
        for s = 1:numel(dataFields)
            fName = dataFields{s};
            
            % Extract data [50 x 8 x 8 x Lags]
            vals = res.(outName).(fName).vals;
            lagsRaw = res.(outName).(fName).lags;
            
            % Resolve the lags vector
            if numel(lagsRaw) > size(vals, 4)
                lags = squeeze(lagsRaw(1,1,1,:));
            else
                lags = lagsRaw;
            end
            
            % Find the index of lag 0
            [~, zeroIdx] = min(abs(lags));
            
            % Extract the 0-lag slice: [50 x 8 x 8 x 1]
            val_at_0 = vals(:, :, :, zeroIdx);
            
            % Prevent Division by Zero (if MI is perfectly 0, leave it alone by dividing by 1)
            val_at_0(abs(val_at_0) < 1e-12) = 1; 
            
            % Normalize everything by the 0-lag slice
            norm_vals = vals ./ val_at_0;
            
            % Store it back into the copied structure
            norm_res.(outName).(fName).vals = norm_vals;
        end
    end
end