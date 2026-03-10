% clear; clc;

maxLag   = 1.8;   % Max lag (seconds)
saveFile = 'pass-actCorrRegion_results.mat';  % Output filename

datanorm = pass_actNorm;          %--------------------------> change this accordingly before running
%% --- Initialize result container ---
results = struct();
outNames = fieldnames(datanorm);   % e.g. {'Out12','Out34'} 

%% --- Iterate through main datasets ---
for i = 1:numel(outNames)
    outName = outNames{i};
    fprintf('\nProcessing dataset: %s\n', outName);

    % List subfields and select only stim / seg fields
    stimFields = fieldnames(datanorm.(outName));
    % stimFields = stimFields( ...
    %     contains(stimFields,'Norm'));

    for j = 1:numel(stimFields)
        stimName = stimFields{j};
        fprintf('  > Computing REGION correlations for %s...\n', stimName);

        signal = datanorm.(outName).(stimName);   % subjects × channels × samples

        % Duration-based lag (same logic you used)
        % u = round(size(signal,3) / 256);

        % --- Region-level bootstrapped correlation ---
        corrRes = corrRegionBoot(signal, maxLag);

        % Store results
        results.(outName).(stimName).corr = corrRes;
    end

    % Optional: preserve channel info if present
    if isfield(datanorm.(outName), 'channels')
        results.(outName).channels = datanorm.(outName).channels;
    end
end

%% --- Save results ---
fprintf('\nSaving results to %s...\n', saveFile);
save(saveFile, 'results', '-v7.3');

fprintf('\n✅ All done! Region-level bootstrapped correlation analysis complete.\n');
