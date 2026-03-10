% % clear; clc;
maxLag   = 2;              % Max lag for corr/auto corr
saveFile = 'visualCorrAcrr_results.mat'; % Output filename
%%                                                  ------------------->Run using loopy loopy
% Load your file
% datanorm = actnorm_faNmiss;   % change it for different files

%% --- Initialize result container ---
results = struct();
outNames = fieldnames(datanorm);  % e.g. {'Out12', 'Out34'}
% maxLag = 1;
%% --- Iterate through main datasets ---
for i = 1:numel(outNames)
    outName = outNames{i};
    fprintf('\nProcessing dataset: %s\n', outName);

    % List subfields and select only stim-related fields
    stimFields = fieldnames(datanorm.(outName));
    stimFields = stimFields(contains(stimFields, 'stim') | contains(stimFields, 'seg')); % filter out non-stim fields / non seg fields

    for j = 1:numel(stimFields)
        stimName = stimFields{j};
        fprintf('  > Computing correlations for %s...\n', stimName);
        signal = datanorm.(outName).(stimName);
        u = round(size(signal,3)/256);
        % Compute correlation and autocorrelation
        [corrRes, acorrRes] = corrAcrr(signal, u);

        % Store results in mirrored structure
        results.(outName).(stimName).corr  = corrRes;
        results.(outName).(stimName).acorr = acorrRes;
    end

    % Copy channel information if available
    if isfield(datanorm.(outName), 'channels')
        results.(outName).channels = datanorm.(outName).channels;
    end
end

%% --- Save results ---
fprintf('\nSaving results to %s...\n', saveFile);
save(saveFile, 'results', '-v7.3');

fprintf('\n✅ All done! Bootstrapped correlation analysis complete.\n');