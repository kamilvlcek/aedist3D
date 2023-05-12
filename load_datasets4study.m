% Sofia March 2023
% Obtain all .set files for creating a study
% After loading all the .set files, use EEGLAB GUI 'Using all loaded dataset' to create a STUDY.

disp('Please specify data directory with pre-processed data')
targetDir = uigetdir(path,'Select file directory.');
cd(targetDir)

%targetFolder = 'F:\\CIIRK\\new_data\\EEG data\\New_with_all_IC\\';
allFiles = dir(targetDir);
folderNames = {allFiles([allFiles.isdir]).name}; % to get folder names  
folderNames = folderNames(3:end); % without first 2 system folders
% numchars   = cellfun(@length, folderNames);  % number of characters in each folder name
% folderNames = folderNames(numchars==10); % keep only folders with subject's name (their length 10)
 
% for each subject
for s = 1:length(folderNames)
    SubjectPath = [targetDir '\' folderNames{s} '\']; % 
    %cd(SubjectPath) % set a new directory - folder for each subject
    % search for a dataset after IC rejection
    file=dir([SubjectPath '*IC_removed.set']);
    subjectName = regexp(file.name,'\_', 'split'); % take only subject's name
    subjectName = subjectName{1};

    % Load data. Note that 'loadmode', 'info' is to avoid loading .fdt file to save time and RAM
    EEG = pop_loadset('filename', file.name, 'filepath', SubjectPath, 'loadmode', 'info');
 
    % Enter EEG.subject
    EEG.subject = subjectName; % subj123
 
    % Store the current EEG to ALLEEG.
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
end
eeglab redraw % This is to update EEGLAB GUI so that you can build STUDY from GUI menu.