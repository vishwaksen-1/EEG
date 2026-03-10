%ensure eeglab is loaded, only applicable to teh file format geenated for
%our task 
% nto a generic code to runa ny csv
% all cloumn numbers required are hard coded 
%% to read data file 
clear;
clc
close all;

[fname, fdir] = uigetfile( ...
{'*.csv', 'CSV Files (*.csv)'; ...
'*.xlsx', 'Excel Files (*.xlsx)'; ...
'*.txt*', 'Text Files (*.txt*)'}, ...
'Pick a file');
filename = fullfile(fdir, fname);
fprintf('Selected file: %s\n', filename);

    fileID = fopen(filename, 'r');
    fgetl(fileID); % first lin e- header diff ids 
    headerLine = fgetl(fileID); % second line only 
    fclose(fileID);
    
    originalHeaders = strsplit(headerLine, ',');
validHeaders = strrep(originalHeaders, 'EEG.', '');    
    T = readtable(filename, 'HeaderLines', 1);
    channel_names=validHeaders(5:18);
columns_to_keep_indices = [2, 3, 5:18, 22,23,24]; % Columns 2, 3, data =  5 to 18
T_data= T(:, columns_to_keep_indices);
new_headers = {'timestamp', 'counter', channel_names{:},'markerInd','markerType','markerValue'};
T_data.Properties.VariableNames = new_headers;
%% starting preprocessing 

fs= 256;
eegData_time_by_chans = T_data{:, 3:16};
eegData= eegData_time_by_chans';
[nbchan, pnts] = size(eegData);
%% into eeglab
EEG = pop_importdata('dataformat', 'array', 'data', eegData, ...
                     'setname', 'raw_data', 'srate', fs, ...
                     'nbchan', nbchan);
EEG = eeg_checkset(EEG);
fprintf('EEGLAB dataset created.\n\n');
chanLabels = T_data.Properties.VariableNames(3:16);

chanlocs_struct = struct('labels', chanLabels);

% hp filter 
EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 0);
EEG = eeg_checkset(EEG);
fprintf('Applied 1 Hz high-pass filter.\n');

% lp 

EEG = pop_eegfiltnew(EEG, 'hicutoff', 55, 'plotfreqz', 0);
EEG = eeg_checkset(EEG);
fprintf('Applied 55 Hz low-pass filter.\n\n');
% reref
EEG = pop_reref(EEG, []);
EEG = eeg_checkset(EEG);
EEG = clean_asr(EEG,5); % Clean raw data:

%run ica
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'interrupt', 'on');
EEG = eeg_checkset(EEG);
% classifier ICA label
channel_location_file_path = 'D:\auditory_perrand_data_code\analysis\emtv_ch_loc.ced';
loc_filename = channel_location_file_path;
    EEG.chanlocs = readlocs(loc_filename);
 
    EEG = iclabel(EEG);
% seen in all papers rejection - 
rejection_thresholds = [NaN NaN;  % Brain: 
                        0.8 1.0;  % Muscle: Flag if > 80%
                        0.8 1.0;  % Eye: Flag if > 80%
                        NaN NaN;  % Heart: Never flag automatically
                        NaN NaN;  % Line Noise: Never flag
                        NaN NaN;  % Channel Noise: Never flag
                        NaN NaN]; % Other: Never flag
EEG = pop_icflag(EEG, rejection_thresholds);
% removal details - logic in ic label 
%eye bliunk -  FP1, FP2, AF3, AF4
% muscle - jaw, yawn, s (T7, T8, F7, F8)- high fre compoenents 
% Brain Component: A typical visual brain component (like an alpha rhythm)
% is strongest over the occipital lobe (O1, O2).s flagged to remove 

num_flagged = sum(EEG.reject.gcompreject);% component
fprintf('%d components have been automatically flagged for rejection.\n', num_flagged);
%'Next,visually review and modify this selection
comps_to_reject = pop_selectcomps(EEG, 1:size(EEG.icawinv,2));
rejected_components = find(EEG.reject.gcompreject);
% sutract the components 
EEG = pop_subcomp(EEG, rejected_components, 0);
EEG = eeg_checkset(EEG);
  cleaned_data_matrix = EEG.data';
  clear T_data_cleaned;
  %% 
T_data_cleaned=T_data(:,1:2);
%T_data_cleaned(:,3:4)=T_data(:,17:18);
temp_table = array2table(cleaned_data_matrix); 

  T_data_cleaned(:,3:16)=temp_table;
  T_data.Properties.VariableNames = new_headers;

  
%eeglab format save 
cd('D:\auditory_perrand_data_code\cleaned_data');
    extracted_string = fname(1 : strfind(fname, '_EPOCX'));

    EEG = pop_saveset(EEG, 'filename', extracted_string);
    mat_filename = [extracted_string, '.mat'];

save(mat_filename,'T_data_cleaned');

%% preprocessing completed 
%% to read data file 
cd('D:\auditory_perrand_data_code\analysis')
clear;
clc
close all;

[fname, fdir] = uigetfile( ...
{'*.csv', 'CSV Files (*.csv)'; ...
'*.xlsx', 'Excel Files (*.xlsx)'; ...
'*.txt*', 'Text Files (*.txt*)'}, ...
'Pick a file');
filename = fullfile(fdir, fname);
fprintf('Selected file: %s\n', filename);

    fileID = fopen(filename, 'r');
    fgetl(fileID); % first lin e- header diff ids 
    headerLine = fgetl(fileID); % second line only 
    fclose(fileID);
    
  
    T = readtable(filename, 'HeaderLines', 1);
   % channel_names=validHeaders(5:18);
columns_to_keep_indices = [3,4,6,7]; % Columns 2, 3, data =  5 to 18
T_data= T(:, columns_to_keep_indices);
new_headers = {'type', 'markervalue', 'timestamp','markerid'};
T_data.Properties.VariableNames = new_headers;

cd('D:\auditory_perrand_data_code\cleaned_data');
    extracted_string = fname(1 : strfind(fname, '_EPOCX'));

    mat_filename = [extracted_string, 'marker','.mat'];

save(mat_filename,'T_data');



