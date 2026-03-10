% === fix_crosscorr_direction_all.m ===
% This script corrects the mistaken cross-correlation direction
% in all EEG results files present in the working directory.
%
% It fixes the xcorr(b,a) vs xcorr(a,b) issue by flipping along
% the lag dimension and swapping the channel indices appropriately.
%
% Files affected:
%   actnormCorrAcorr_results.mat
%   passnormCorrAcorr_results.mat
%   hitNcrCorrAcorr_results.mat
%   faNmissCorrAcorr_results.mat
%   datanormCorrAcorr_results.mat
%
% Each corrected file is saved as *_fixed.mat

clear; clc;

fileList = {
    'actnormCorrAcrr_results.mat'
    'passnormCorrAcrr_results.mat'
    'hitNcrCorrAcrr_results.mat'
    'faNmissCorrAcrr_results.mat'
    'datanormCorrAcrr_results.mat'
};

fprintf('\n=== Starting cross-correlation direction correction for all files ===\n');

for f = 1:numel(fileList)
    fname = fileList{f};
    if ~isfile(fname)
        warning('File not found: %s. Skipping.', fname);
        continue;
    end

    fprintf('\n--- Processing %s ---\n', fname);
    load(fname, 'results');

    outNames = fieldnames(results);
    for o = 1:numel(outNames)
        outName = outNames{o};
        subStructs = fieldnames(results.(outName));
        subStructs = subStructs(~contains(subStructs, 'channels'));

        for s = 1:numel(subStructs)
            segName = subStructs{s};
            if ~isfield(results.(outName).(segName), 'corr')
                continue;
            end

            corrData = results.(outName).(segName).corr;
            [nCh, ~, ~] = size(corrData.mean);
            lags = corrData.lags;

            fprintf('  Fixing %s.%s ...\n', outName, segName);

            % --- Fix direction only once per pair ---
            for ch1 = 1:nCh-1
                for ch2 = ch1+1:nCh
                    % Extract original pairs
                    ab = squeeze(corrData.mean(ch1,ch2,:));
                    ba = squeeze(corrData.mean(ch2,ch1,:));

                    % Correct both
                    % corrData.mean(ch1,ch2,:) = flip(ba,1);
                    corrData.mean(ch2,ch1,:) = flip(ab,1);

                    % Fix std as well
                    ab_std = squeeze(corrData.std(ch1,ch2,:));
                    ba_std = squeeze(corrData.std(ch2,ch1,:));
                    % corrData.std(ch1,ch2,:) = flip(ba_std,1);
                    corrData.std(ch2,ch1,:) = flip(ab_std,1);
                end
            end

            % Reverse lag direction once
            corrData.lags = -flip(lags);

            % Save back
            results.(outName).(segName).corr = corrData;
        end
    end

    % Save corrected version
    [~, base, ~] = fileparts(fname);
    outFile = sprintf('%s.mat', base);
    save(outFile, 'results', '-v7.3');
    fprintf('✅ Saved corrected file: %s\n', outFile);
end

fprintf('\n=== All files processed successfully. ===\n');
