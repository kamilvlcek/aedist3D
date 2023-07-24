% Sofia May 2023
% script for dipoles fitting of preprocessed EEG data after ICA decomposition over all subjects
disp('Please specify data directory with pre-processed data')
targetDir = uigetdir(path,'Select file directory.');
cd(targetDir)

allFiles = dir(targetDir);
folderNames = {allFiles([allFiles.isdir]).name}; % to get folder names
folderNames = folderNames(3:end); % without first 2 system folders
eeglab; % Start eeglab

% for importing digitized chan loc files
chanLocPathRenamed = 'E:\CIIRK\new_data\Krios channel loc\from_Myrousz\transformed to eeglab format\renamed_labels4dipfit';
filespec="*.txt";
chanLocFilesRenamed=dir(fullfile(chanLocPathRenamed,filespec)); % all new chan loc files - from Myrousz, but with renamed labels corresponding to standard_1005.elc labels (for coregister function)
chanLocFilesRenamed = {chanLocFilesRenamed.name}; % only names of txt files

chanLocPath = 'E:\CIIRK\new_data\Krios channel loc\from_Myrousz\transformed to eeglab format\'; % folder with digitized chan loc files (without renaming, should be imported after coregister function in dipfit)
chanLocFilesNormal=dir(fullfile(chanLocPath,filespec));
chanLocFilesNormal = {chanLocFilesNormal.name}; % only names of txt files

% for each subject
for s = 1:length(folderNames)
    SubjectPath = [targetDir '\' folderNames{s} '\'];
    
    % search for a dataset with IC weights
    file=dir([SubjectPath '*runica_incorrect_rj.set']);
    subjectName = regexp(file.name,'\_', 'split'); % take only subject's name
    subjectName = subjectName{1};
   
    if exist([SubjectPath subjectName '_dipfit_digChanLoc.set'], 'file') == 2 % if dipole fitting for this subject was already done, skip it and do the next subject
        continue
    end
    
    % Load dataset from one subject
    EEG = pop_loadset('filename', file.name, 'filepath', SubjectPath);
    
    % import a digitized chan loc file with renamed labels corresponding to standard_1005.elc labels(such as Cz, Pz...etc.)
    idxSubjectChalLoc = find(contains(chanLocFilesRenamed, subjectName)); % find index of chan loc file for this subject
    if ~isempty(idxSubjectChalLoc) % in some subjects, chan loc file is missing, then not to import new chan loc file and just use the old standard biosemi file
        fullChanLocFilename = fullfile(chanLocPathRenamed,  chanLocFilesRenamed{idxSubjectChalLoc}); % full name with a path
        EEG=pop_chanedit(EEG, 'load', {fullChanLocFilename,'filetype','xyz'}, ... % import only 132 channels without fiducials
            'delete', [133:136], 'changefield',{129 'type' 'EOG'},'changefield',{130 'type' 'EOG'},'changefield',{131 'type' 'EOG'},'changefield',{132 'type' 'EOG'});
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = eeg_checkset( EEG );
    end
    
    % Estimate single equivalent current dipoles
    % all files used for the standard BEM head model
    hdmFilePath = 'D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.2\\standard_BEM\\standard_vol.mat';
    mriFilePath = 'D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.2\\standard_BEM\\standard_mri.mat';
    templateChannelFilePath = 'D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.2\\standard_BEM\\elec\\standard_1005.elc';
    
    if ~isempty(idxSubjectChalLoc)
        % find coordinateTransformParameters for digitized chan loc file for this particular subject if it exists
        [~,coordinateTransformParameters] = coregister(EEG.chanlocs, templateChannelFilePath, 'warp', 'auto', 'manual', 'off');
    else
        % if the subject's chan loc file is missing, these coordinateTransform Parameters are used with standard biosemi file:
        coordinateTransformParameters = [0.52588 -8.4007 -1.9173 0.037341 -0.0068294 -1.5684 98.2903 93.4194 97.4829]; % these numbers were obtained when adjusted biosemi channels to the standard template of electrodes associated with the BEM model for one subject, but can be used for all subjects with biosemi channel loc file
    end
    
    % then import normal digitized chan loc file (with old labels like in EEG data - A1, A2...etc.) if exists
    idxSubjectChalLoc = find(contains(chanLocFilesNormal, subjectName)); % find index of chan loc file for this subject
    if ~isempty(idxSubjectChalLoc)
        fullChanLocFilename = fullfile(chanLocPath,  chanLocFilesNormal{idxSubjectChalLoc}); % full name with a path
        EEG=pop_chanedit(EEG, 'load', {fullChanLocFilename,'filetype','xyz'}, ... % import only 132 channels without fiducials
            'delete', [133:136], 'changefield',{129 'type' 'EOG'},'changefield',{130 'type' 'EOG'},'changefield',{131 'type' 'EOG'},'changefield',{132 'type' 'EOG'});
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = eeg_checkset( EEG );
    end
    
    % Co-registration of head model and electrode locations
    chan2fit = 1:EEG.nbchan-4; % last 4 channels are EOG in all subjects, should be excluded from dipole fitting   
    EEG = pop_dipfit_settings( EEG, 'hdmfile', hdmFilePath,'mrifile', mriFilePath ,'chanfile', templateChannelFilePath,'coordformat','MNI','coord_transform', coordinateTransformParameters,'chansel',chan2fit);
    
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    % Search for and estimate dipoles
    %     EEG = pop_multifit(EEG, 1:EEG.nbchan ,'threshold',100,'dipoles',2,'dipplot','off','plotopt',{'normlen','on'}); % symmetrically constrained bilateral dipoles
    EEG = pop_multifit(EEG, 1:EEG.nbchan ,'threshold',100,'dipoles',1,'dipplot','off','plotopt',{'normlen','on'}); % uses one dipole constrain in symmetry (default); finding symmetrically constrained bilateral dipoles in the next step
    
    % Search for and estimate symmetrically constrained bilateral dipoles
    EEG = fitTwoDipoles(EEG, 'LRR', 35); % default parameters: LRR = Large rectangular region, 35 = threshold value for "true" peak selection
    
    % Run ICLabel
    EEG = iclabel(EEG, 'default');
    
    % Save the dataset
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'setname',[subjectName '_dipfit_digChanLoc'],'savenew',[SubjectPath subjectName '_dipfit_digChanLoc.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    
end
eeglab redraw % This is to update EEGLAB GUI
