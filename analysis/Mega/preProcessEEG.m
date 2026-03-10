%% preprocess eeg data
% fCutOff : lower cutof of high pass filter

% flow = highpass filter > decompose ICA > label ICA > remove unwanted ICA(manually) >  automated artifact rejection

% returns processed EEG
% processing history is recorded in  EEG.processHistory variable.

function EEG = preProcessEEG(EEG, fCutOff)
    addPathFromEEGlab();
    filteredEEG = pop_eegfiltnew(EEG, fCutOff);
    eegplot( EEG.data, 'srate', EEG.srate, 'title', 'filteredEEG: Black = raw; red = filtered','limits', [EEG.xmin EEG.xmax]*1000, 'data2', filteredEEG.data); % show differences
    EEG = filteredEEG;
    EEG.processHistory{end+1} = sprintf("EEG = pop_eegfiltnew(EEG, %0.2f)",fCutOff);

    % ICA
    EEG = pop_runica(EEG,'icatype', 'runica', 'dataset', 1, 'options', {'extended',	1,	'rndreset',	'yes'}, 'reorder', 'on');
    EEG.processHistory{end+1} = "EEG = pop_runica(EEG,'icatype', 'runica', 'dataset', 1, 'options', {'extended',	1,	'rndreset',	'yes'}, 'reorder', 'on')";
    EEG = iclabel(EEG); % analyse ica labels
    EEG.processHistory{end+1} = "EEG = iclabel(EEG)";
    % % % % pop_topoplot(EEG, 0); % show ica
    pop_viewprops( EEG, 0, 1:14, {'freqrange', [2 64]}, {}, 1,'ICLabel'); % show ica, with label
    
    % Remove ICs
    removeComponents = 'Yes';
    while strcmp(removeComponents, 'Yes')
        removeComponents = questdlg('Remove any independant componets from EEG?', 'Question', 'Yes', 'No', 'Yes');
        if strcmp(removeComponents, 'Yes')
            [EEG, com] = pop_subcomp(EEG); % remove ic
            if ~isempty(com)
                EEG.processHistory{end+1} = com;% 1,2,4
                break
            end
        end
    end
    
    % automated artifact rejection
    % % % % input: Standard deviation cutoff, most aggressive  3.  aggressive value is 5, conservative value is 20. Default: 5.
    cleanEEG = clean_asr(EEG,5); % Clean raw data:
    % vis_artifacts(cleanEEG,EEG);
    eegplot( EEG.data, 'srate', EEG.srate, 'title', 'CleanedEEG: Black = old; red = new','limits', [EEG.xmin EEG.xmax]*1000, 'data2', cleanEEG.data); % show differences
    EEG = cleanEEG;
    EEG.processHistory{end+1} = "EEG = clean_asr(EEG,5)";

end