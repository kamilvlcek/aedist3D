% Sofia March 2023

% script for initial preprocessing from a raw file over all subjects (importing BDf file, selection of channels, resampling, loading channel locations,
% removing bad channels, interpolation of removed channels and re-referencing, filtering, extracting epochs, removing training epochs,
% ICA, marking bad components and rejecting them, removing incorrect epochs, saving all datasets)

% disp('Please specify working directory (where your pipeline scripts are stored).')
% workingDir = uigetdir(path,'Select working directory.');
% addpath(workingDir)
% addpath(workingDir,filesep,'altmany-export_fig-4703a84')
  
Ns = 16; % number of subjects 

disp('Please specify directory for preprocessed data (where folders are created).')
path_data = uigetdir(path,'Select file directory.');

disp('Please specify data directory with raw data')
rawDir = uigetdir(path,'Select file directory.');
cd(rawDir)
%path_data = 'E:\CIIRK\new_data\EEG_data\pre-processed data';
%cd  path_data   % folder with raw data
files=dir('*.bdf');   % to get information about all files in this directory
cd(path_data)
eeglab; % Start eeglab

% For each subject
for s=1:length(files)
    eeg_filename = files(s).name; % name of raw eeg file
    full_filename = fullfile(rawDir, eeg_filename); % full name with a path
    subject_name = regexp(eeg_filename,'\.', 'split');  % split filename to separate subject's name and extension
    subject_name = subject_name{1};
    eval(['!mkdir ' subject_name]); % create a new folder for each subject
    new_path = [path_data '\' subject_name '\' subject_name];
    
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
    % read a bdf file
    EEG = pop_biosig(full_filename, 'channels',[1:132] ,'ref',1); % leave 132 channels and mark channel 1 (A1) as a reference
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
    EEG = eeg_checkset( EEG );
    
    % resample to 512 hz
    EEG = pop_resample( EEG, 512); 
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'savenew',[new_path '_resampled.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    
    % rename all conditions into words for convineince
    EEG = pop_selectevent( EEG, 'type',{'condition 1'},'renametype','correct','deleteevents','off');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    EEG = pop_selectevent( EEG, 'type',{'condition 2'},'renametype','wrong','deleteevents','off');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    EEG = pop_selectevent( EEG, 'type',{'condition 10'},'renametype','control2D','deleteevents','off');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    EEG = pop_selectevent( EEG, 'type',{'condition 11'},'renametype','control3D','deleteevents','off');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    EEG = pop_selectevent( EEG, 'type',{'condition 20'},'renametype','ego2D','deleteevents','off');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    EEG = pop_selectevent( EEG, 'type',{'condition 21'},'renametype','ego3D','deleteevents','off');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    EEG = pop_selectevent( EEG, 'type',30,'renametype','allo2D','deleteevents','off');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    EEG = pop_selectevent( EEG, 'type',31,'renametype','allo3D','deleteevents','off');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    % import channel locations
    EEG = pop_chanedit(EEG, 'load',{'E:\\CIIRK\\new_data\\biosemi_132.ced','filetype','autodetect'},'changefield',{129 'type' 'EOG'},'changefield',{130 'type' 'EOG'},'changefield',{131 'type' 'EOG'},'changefield',{132 'type' 'EOG'}); 
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    
    % filtering
%     EEG = pop_eegfiltnew( EEG,'locutoff',0.5); % high pass filter 0.5 hz
    EEG = pop_eegfiltnew(EEG, 'locutoff',1); % high pass filter 1 hz
    EEG = pop_eegfiltnew(EEG, 'hicutoff',120); % low pass filter 120 hz
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[subject_name '_filtered'],'savenew',[new_path '_filtered.set'],'gui','off');
    EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:132] ,'computepower',1,'linefreqs',[50 100] ,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype','Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',1); % remove line noise at 50 and 100 Hz using plugin cleanline
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3, 'setname',[subject_name '_filtered_linenoise'],'savenew',[new_path '_filtered_linenoise.set'],'gui','off');
    EEG = eeg_checkset( EEG );
 
    % reject bad channels using clean_rawdata plugin
    originalEEG = EEG;
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian'); 
    removedChansIdx = ~ismember({originalEEG.chanlocs(:).labels},{EEG.chanlocs(:).labels}); % indexes of removed chan 
    if ~isempty(find(removedChansIdx))
        removedChans = strjoin({originalEEG.chanlocs(removedChansIdx).labels},', ');
        EEG.comments = pop_comments(EEG.comments,'',['Removed channels ', removedChans, '_by clean_rawdata plugin']);
    end
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname',[subject_name '_bad_channels_rj'],'savenew',[new_path '_bad_channels_rj.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    
    % re-reference
    EEG = pop_reref( EEG, [],'interpchan',[]); % average reference and interpolation of removed channels
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'overwrite','on','gui','off');
   
    % extract epochs
    EEG = pop_epoch( EEG, {'control2D' 'control3D'  'ego2D' 'ego3D' 'allo2D' 'allo3D'}, [-1  2], 'newname', [subject_name '_epochs'], 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5, 'setname',[subject_name '_epochs'],'savenew',[new_path '_epochs.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
  
    % remove training epochs
    EEG = pop_select( EEG, 'notrial',[1:18] ); 
    EEG.comments = pop_comments(EEG.comments,'','training trials removed',1);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6, 'setname',[subject_name '_epochs_without_training'],'savenew',[new_path '_epochs_without_training.set'],'gui','off');
    EEG = eeg_checkset( EEG );

    % remove bad epochs
    events1 = [EEG.event(:).urevent]; % all events in epochs before rejection
    chan_EEG_ind = find(strcmp({EEG.chanlocs.type}, 'EEG')); % find only EEG channels without EOG
    [EEG, Indexes] = pop_eegthresh(EEG,1,chan_EEG_ind,-500,500,-1,1.998,1,1); % an amplitude threshold of -500 to 500 uV
    [EEG, ~, ~, nrej] = pop_jointprob(EEG,1,chan_EEG_ind ,6,2,1,1,0,[],0); % 6SD (standard-dev) as the criteria for the improbability test for single channels, and 2SD as the criteria for all channels
    events2 = [EEG.event(:).urevent]; % events in epochs remaining after rejection
    EEG.comments = pop_comments(EEG.comments,'',...
    strcat(num2str(nrej+length(Indexes)), " epochs rejected, ",  "Rejected epochs ", strjoin(string(find(~ismember(events1,events2))),', ')),1);
      
    % perform ICA
    EEG = pop_runica(EEG, 'icatype','runica','concatcond','on','options',{'pca', -1});
    EEG = pop_iclabel(EEG, 'default'); % label IC
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    EEG = pop_icflag(EEG, [NaN NaN;0.8 1;0.8 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]); % mark only eye and muscle components with 80 % probability
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    rejectICIdx = find(EEG.reject.gcompreject); % store marked bad IC
    EEG.comments = pop_comments(EEG.comments,'', strcat('independent components for rejection:  ', ...
        strjoin(string(rejectICIdx),', ')),1);
    
    % remove incorrect trials
    EEG = pop_selectevent( EEG, 'type','correct','deleteevents','off','deleteepochs','on','invertepochs','off'); % leave only correct
    EEG.comments = pop_comments(EEG.comments,'','ICA performed, epochs with incorrect trials removed',1);
  
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'setname',[subject_name '_ICA'],'savenew',[new_path '_ICA.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    EEG = pop_subcomp( EEG, [], 0);  % reject marked components
    EEG.comments = pop_comments(EEG.comments,'','bad IC removed',1);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'setname',[subject_name '_bad_IC_removed'],'savenew',[new_path '_bad_IC_removed.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    
    disp(['preprocessing for subject ' subject_name ' finished']);
    
    % then we need to delete all datasets from eeglab and start again for next subject
    ALLEEG = pop_delset(ALLEEG, 1:9); % delete datasets   
end

eeglab redraw  % Update the main EEGLAB window