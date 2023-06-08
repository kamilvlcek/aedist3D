% Sofia 2023

%%% script for initial preprocessing from a raw file over all subjects (importing BDf file, selection of channels, resampling, filtering, loading channel locations,
%%% removing bad channels, rejecting bad segments of data, interpolation of removed channels and re-referencing, extracting epochs, removing training epochs)
%%% ICA and post-ICA processing like marking bad components and rejecting them, removing incorrect epochs are done in a separate script as very computations operations, which can be done through NSG portal
%%% apart from new processed datasets, returns the xls table with all rejected channels and events

% variables, which can be set earlier (in preprocessing_batch)
if ~exist('individChanLoc','var'), individChanLoc = 0; end % to import standard biosemi channel locations file or individual digitized channel locations for each subject
if ~exist('rejectBadEpochs','var'), rejectBadEpochs = 0; end
if ~exist('rejectWindowData','var'), rejectWindowData = 0; end

Ns = 16; % number of subjects

disp('Please specify directory for preprocessed data (where folders are created).')
path_data = uigetdir(path,'Select file directory.');

disp('Please specify data directory with raw data')
rawDir = uigetdir(path,'Select file directory.');
cd(rawDir)
files=dir('*.bdf');   % to get information about all files in this directory
cd(path_data)
eeglab; % Start eeglab

% initialize cell array to export info about all channels and trials rejected for each subject
output = cell(length(files), 8);
colNames = {'subject', 'N_chan_rj', 'chan_name_rj', 'N_sec_rj_by_clean_rawdata', 'N_events_rj_by_clean_rawdata', 'idx_events_rj_by_clean_rawdata', 'N_bad_epochs_rj', 'idx_events_rj'};

% For each subject
for s=1:length(files)
    eeg_filename = files(s).name; % name of raw eeg file
    full_filename = fullfile(rawDir, eeg_filename); % full name with a path
    subject_name = regexp(eeg_filename,'\.', 'split');  % split filename to separate subject's name and extension
    subject_name = subject_name{1};
    eval(['!mkdir ' subject_name]); % create a new folder for each subject
    new_path = [path_data '\' subject_name '\' subject_name];
    
    output{s,1} = subject_name; % save subject name to the output table
    
    % read a bdf file
    EEG = pop_biosig(full_filename, 'channels',[1:132] ,'ref',1); % leave 132 channels and mark channel 1 (A1) as a reference
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');
    EEG = eeg_checkset( EEG );
    
    % resample to 256 hz
    EEG = pop_resample( EEG, 256);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'savenew',[new_path '_resampled.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    
    % import channel locations
    if individChanLoc == 0
        EEG = pop_chanedit(EEG, 'load',{'E:\\CIIRK\\new_data\\biosemi_132.ced','filetype','autodetect'},'changefield',{129 'type' 'EOG'},'changefield',{130 'type' 'EOG'},'changefield',{131 'type' 'EOG'},'changefield',{132 'type' 'EOG'});
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = eeg_checkset( EEG );
    else  % import individual digitized channel locations
        chanLocPath = 'E:\CIIRK\new_data\Krios channel loc\from_Myrousz\transformed to eeglab format\';
        chanLocFile=dir([chanLocPath 'subject_name*.txt']); % find chan loc file of this subject
        
        EEG=pop_chanedit(EEG, 'load', {chanLocFile.name,'filetype','xyz'}, ...
            'delete', [136], 'changefield',{129 'type' 'EOG'},'changefield',{130 'type' 'EOG'},'changefield',{131 'type' 'EOG'},'changefield',{132 'type' 'EOG'});
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = eeg_checkset( EEG );
    end
    
    % filtering
    EEG = pop_eegfiltnew(EEG, 1, 0, 1650, 0, [], 0); % High-pass filter the data at 1-Hz. Note that EEGLAB uses pass-band edge, therefore 1/2 = 0.5 Hz
    %EEG = pop_eegfiltnew(EEG, 'hicutoff',120); % low pass filter 120 hz
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname',[subject_name '_filtered'],'savenew',[new_path '_filtered.set'],'gui','off');
    
    % remove line noise at 50 and 100 Hz using plugin cleanline
    EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:132] ,'computepower',1,'linefreqs',[50 100] ,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype','Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',1);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3, 'setname',[subject_name '_filtered_linenoise'],'savenew',[new_path '_filtered_linenoise.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    
    % reject bad channels using clean_rawdata plugin
    originalEEG = EEG;
    EEG = clean_artifacts(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    removedChansIdx = ~ismember({originalEEG.chanlocs(:).labels},{EEG.chanlocs(:).labels}); % indexes of removed chan
    if ~isempty(find(removedChansIdx))
        removedChans = strjoin({originalEEG.chanlocs(removedChansIdx).labels},', ');
        EEG.comments = pop_comments(EEG.comments,'',['Removed channels ', removedChans, '_by clean_rawdata plugin']);
    end
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'setname',[subject_name '_bad_channels_rj'],'savenew',[new_path '_bad_channels_rj.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    
    % save rejected channels to the output table
    output{s,2} = length(find(removedChansIdx)); % the number
    output{s,3} = removedChans; % their names
    
    % then correct bad portions of data using clean_rawdata plugin (clean_artifacts is the same), uses ASR algorhitm
    originalEEG2 = EEG;
    eventsOrig = [EEG.event(:).urevent]; % all events in data before artifacts rejection
    if rejectWindowData == 1
        EEG = clean_artifacts(EEG, 'ChannelCriterion','off','LineNoiseCriterion', 'off','FlatlineCriterion', 'off', 'Highpass','off','BurstCriterion', 10,'WindowCriterion', 0.25); % BurstCriterion - SD=10, can be changed
    else
        EEG = clean_artifacts(EEG, 'ChannelCriterion','off','LineNoiseCriterion', 'off','FlatlineCriterion', 'off', 'Highpass','off','BurstCriterion', 10,'WindowCriterion', 'off');
    end
    %vis_artifacts(EEG,originalEEG2) % to compare visually cleaned and raw eeg - only in case of one subject, for all - not relevant
    
    % check also whether the length of EEG data remained the same after cleaning
    if EEG.pnts == originalEEG2.pnts
        disp('the same number of data points in cleaned and original dataset');
        output{s,4} = 0;
    else
        disp('inconsistency in the number of data points in cleaned and original dataset'); % if also some time windows of bad data were rejected
        
        % save the lenghth of rejected timepoints in sec to the output table
        output{s,4} = length(find(~EEG.etc.clean_sample_mask))/EEG.srate;
        eventsAfterRj = [EEG.event(:).urevent]; % events remaining after rejection
        output{s,5} = length(eventsOrig) - length(eventsAfterRj); % save number of events rj by clean_rawdata
        output{s,6} = char(strjoin(string(find(~ismember(eventsOrig, eventsAfterRj))),', ')); % and their indexes
    end
    
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
    
    % save new cleaned set
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'setname',[subject_name '_clean_ASR'],'savenew',[new_path '_clean_ASR.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    
    %  Interpolate all the removed channels
    EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');
    
    % Re-reference the data to average
    EEG.nbchan = EEG.nbchan+1;
    EEG.data(end+1,:) = zeros(1, EEG.pnts);  % restore electrode A1 as it was initially used as reference
    EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
    if EEG.nbchan > 129
        EEG = pop_reref(EEG, [], 'exclude',[129:132]); % exclude EOG channels from average re-reference
    else
        EEG = pop_reref(EEG, []);
    end
    EEG = pop_select( EEG,'nochannel',{'initialReference'});
    % save new  set
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'setname',[subject_name '_clean_ASR_avg_ref'],'savenew',[new_path '_clean_ASR_avg_ref.set'],'gui','off');
    
    % extract epochs
    EEG = pop_epoch( EEG, {'control2D' 'control3D'  'ego2D' 'ego3D' 'allo2D' 'allo3D'}, [-1  2], 'newname', [subject_name '_epochs'], 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7, 'setname',[subject_name '_epochs'],'savenew',[new_path '_epochs.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    if rejectBadEpochs == 1
        % remove bad epochs
        events1 = [EEG.event(:).urevent]; % all events in epochs before rejection
        chan_EEG_ind = find(strcmp({EEG.chanlocs.type}, 'EEG')); % find only EEG channels without EOG
        [EEG, Indexes] = pop_eegthresh(EEG,1,chan_EEG_ind,-500,500,-1,1.998,1,1); % an amplitude threshold of -500 to 500 uV
        [EEG, ~, ~, nrej] = pop_jointprob(EEG,1,chan_EEG_ind ,6,2,1,1,0,[],0); % 6SD (standard-dev) as the criteria for the improbability test for single channels, and 2SD as the criteria for all channels
        events2 = [EEG.event(:).urevent]; % events in epochs remaining after rejection
        EEG.comments = pop_comments(EEG.comments,'',...
            strcat(num2str(nrej+length(Indexes)), " epochs rejected, ",  "Rejected epochs ", strjoin(string(find(~ismember(events1,events2))),', ')),1);
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 9, 'setname',[subject_name '_bad_epochs_rejected'],'savenew',[new_path '_bad_epochs_rejected.set'],'gui','off');
        EEG = eeg_checkset( EEG );
        % save the number of rejected epochs to the output table
        output{s,7} = nrej+length(Indexes);
        output{s,8} = char(strjoin(string(find(~ismember(events1,events2))),', '));
    end
    
    disp(['preprocessing for subject ' subject_name ' finished']);
    
    % then we need to delete all datasets from eeglab and start again for next subject
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[]; % delete datasets
end

eeglab redraw  % Update the main EEGLAB window

% export output table
xlsfilename = fullfile(path_data, 'preprocessing_over_subjects_output.xls');
xlswrite(xlsfilename, vertcat(colNames,output));
disp([ 'XLS table saved: ' xlsfilename]);