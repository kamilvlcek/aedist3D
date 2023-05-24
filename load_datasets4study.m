% Sofia March 2023
% Obtain all .set files for creating a study
% After loading all the .set files, use EEGLAB GUI 'Using all loaded datasets' to create a STUDY or script selection_IC_in_STUDY.m

disp('Please specify data directory with pre-processed data')
targetDir = uigetdir(path,'Select file directory.');
cd(targetDir)

allFiles = dir(targetDir);
folderNames = {allFiles([allFiles.isdir]).name}; % to get folder names  
folderNames = folderNames(3:end); % without first 2 system folders
 
% for each subject
for s = 1:length(folderNames)
    SubjectPath = [targetDir '\' folderNames{s} '\']; % 
    % search for a dataset after dipoles fitting
    file=dir([SubjectPath '*dipfit.set']); 
%     file=dir([SubjectPath '*IC_removed.set']);  % search for a dataset after IC rejection
    subjectName = regexp(file.name,'\_', 'split'); % take only subject's name
    subjectName = subjectName{1};

    % Load data. Note that 'loadmode', 'info' is to avoid loading .fdt file to save time and RAM
    EEG = pop_loadset('filename', file.name, 'filepath', SubjectPath, 'loadmode', 'info');
 
    % Enter EEG.subject
    EEG.subject = subjectName; % subj123
 
    % Store the current EEG to ALLEEG.
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
end
eeglab redraw % This is to update EEGLAB GUI so that you can build STUDY from GUI menu

