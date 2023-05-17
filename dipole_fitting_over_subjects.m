% Sofia May 2023
% script for dipoles fitting of preprocessed EEG data after ICA decomposition over all subjects 
disp('Please specify data directory with pre-processed data')
targetDir = uigetdir(path,'Select file directory.');
cd(targetDir)

allFiles = dir(targetDir);
folderNames = {allFiles([allFiles.isdir]).name}; % to get folder names  
folderNames = folderNames(3:end); % without first 2 system folders
eeglab; % Start eeglab

% for each subject
for s = 1:length(folderNames)
    SubjectPath = [targetDir '\' folderNames{s} '\'];  
    
    % search for a dataset with IC weights
    file=dir([SubjectPath '*ICA.set']);
    subjectName = regexp(file.name,'\_', 'split'); % take only subject's name
    subjectName = subjectName{1}; 
    
    % Load dataset from one subject
    EEG = pop_loadset('filename', file.name, 'filepath', SubjectPath);
 
   % Estimate single equivalent current dipoles
   % all files used for the standard BEM head model 
    hdmFilePath = 'D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.1\\standard_BEM\\standard_vol.mat';
    mriFilePath = 'D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.1\\standard_BEM\\standard_mri.mat';
    templateChannelFilePath = 'D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.1\\standard_BEM\\elec\\standard_1005.elc';
    coordinateTransformParameters = [0.52588 -8.4007 -1.9173 0.037341 -0.0068294 -1.5684 98.2903 93.4194 97.4829]; % these numbers were obtained when adjusted biosemi channels to the standard template of electrodes associated with the BEM model for one subject, but can be used for all subjects with biosemi channel loc file
    chan2fit = 1:EEG.nbchan-3; % last 4 channels are EOG in all subjects, should be excluded from fitting
    
    % Co-registration of head model and electrode locations
    EEG = pop_dipfit_settings( EEG, 'hdmfile', hdmFilePath,'mrifile', mriFilePath ,'chanfile', templateChannelFilePath,'coordformat','MNI','coord_transform', coordinateTransformParameters,'chansel',chan2fit);
    
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    % Search for and estimate dipoles
%     EEG = pop_multifit(EEG, 1:EEG.nbchan ,'threshold',100,'dipoles',2,'dipplot','off','plotopt',{'normlen','on'}); % symmetrically constrained bilateral dipoles
    EEG = pop_multifit(EEG, 1:EEG.nbchan ,'threshold',100,'dipoles',1,'dipplot','off','plotopt',{'normlen','on'}); % uses one dipole
    
    % Run ICLabel 
    EEG = iclabel(EEG, 'default');
 
    % Save the dataset  
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'setname',[subjectName '_dipfit'],'savenew',[SubjectPath subjectName '_dipfit.set'],'gui','off');
    EEG = eeg_checkset( EEG );
   
end
eeglab redraw % This is to update EEGLAB GUI 
