function [bootMean, bootCI, freq] = bootstrap_psd(dataStruct, stim, chan, band, nBoot)
    % Collect data across subjects
    nSubjects = numel(dataStruct.(stim));
    allSubjectsData = cell(nSubjects,1);
    for s = 1:nSubjects
        allSubjectsData{s} = dataStruct.(stim)(s).(chan).(band);
    end
    
    % Concatenate subject PSDs column-wise
    groupData = cat(2, allSubjectsData{:});
    
    % Bootstrapping across subjects
    bootMeans = zeros(size(groupData,1), nBoot);
    for b = 1:nBoot
        idx = randi(nSubjects, [nSubjects,1]);
        bootMeans(:,b) = nanmean(groupData(:,idx), 2);
    end
    
    % Compute bootstrap mean and CI
    bootMean = nanmean(bootMeans, 2);
    bootCI = prctile(bootMeans, [2.5 97.5], 2);
    
    % Extract frequency vector
    freq = dataStruct.(stim)(1).(chan).([band '_f']);
end
