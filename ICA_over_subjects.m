% ICA over all subjects

amica = 0; % whether to use amica for ICA; if 0, uses runica (infomax algorithm) 

disp('Please specify directory with preprocessed data')
path_data = uigetdir(path,'Select file directory.');
cd(path_data)

allFiles = dir(path_data); % all files in that directoty
folderNames = {allFiles([allFiles.isdir]).name}; % to get folder names  
folderNames = folderNames(3:end); % without first 2 system folders

eeglab; % Start eeglab
  
% For each of the subjects
parfor s = 1:length(folderNames)
    SubjectPath = [path_data '\' folderNames{s} '\'];  
    file=dir([SubjectPath '*epochs.set']); % all datasets after preprocessing and epoching
    EEG = pop_loadset('filename', file.name, 'filepath', SubjectPath);
    subject_name = regexp(file.name,'\.', 'split');  % split filename to separate subject's name and extension
    subject_name = subject_name{1};

 % perform ICA
    dataRank = EEG.nbchan - length(find(~EEG.etc.clean_channel_mask)); % datarank = decreased by the number of rejected channels
    
    if amica == 1       
        % to perform AMICA
        %  Run AMICA using calculated data rank with 'pcakeep' option
        outdir = [fullFileName '\\amicaout'];
        
        runamica15(EEG.data, 'num_chans', EEG.nbchan,...
            'outdir', outdir,...
            'pcakeep', dataRank, 'num_models', 1,...
            'do_reject', 1, 'numrej', 15, 'rejsig', 3, 'rejint', 1);
        EEG.etc.amica  = loadmodout15(outdir);
        EEG.etc.amica.S = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs, :); % Weirdly, I saw size(S,1) be larger than rank. This process does not hurt anyway.
        EEG.icaweights = EEG.etc.amica.W;
        EEG.icasphere  = EEG.etc.amica.S;
        EEG = eeg_checkset(EEG, 'ica');
    else
        % to perform ICA using infomax algorithm
        EEG = pop_runica(EEG, 'icatype','runica','concatcond','on','options',{'extended', 1, 'pca', dataRank, 'stop', 1E-7});
    end

    % label components by IClabel
    EEG = pop_iclabel(EEG, 'default');
    
    % save new set
    pop_saveset(EEG, 'filename', [subject_name '_runica.set'], 'filepath', SubjectPath);
    
    pop_topoplot(EEG, 0, [1:35] ,'scalp maps of ICs runica',[5 7] ,0,'iclabel','on'); % plot first 35 components and save
    print('-djpeg', [subject_name '_runica.jpg']);
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[]; % delete datasets
 
%     EEG = pop_icflag(EEG, [NaN NaN;0.8 1;0.8 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]); % mark only eye and muscle components with 80 % probability
%     [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%     rejectICIdx = find(EEG.reject.gcompreject); % store marked bad IC
%     EEG.comments = pop_comments(EEG.comments,'', strcat('independent components for rejection:  ', ...
%         strjoin(string(rejectICIdx),', ')),1);
%     
%     % remove incorrect trials
%     EEG = pop_selectevent( EEG, 'type','correct','deleteevents','off','deleteepochs','on','invertepochs','off'); % leave only correct
%     EEG.comments = pop_comments(EEG.comments,'','ICA performed, epochs with incorrect trials removed',1);
%     
%     [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'setname',[subject_name '_ICA'],'savenew',[new_path '_ICA.set'],'gui','off');
%     EEG = eeg_checkset( EEG );
%     EEG = pop_subcomp( EEG, [], 0);  % reject marked components
%     EEG.comments = pop_comments(EEG.comments,'','bad IC removed',1);
%     [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'setname',[subject_name '_bad_IC_removed'],'savenew',[new_path '_bad_IC_removed.set'],'gui','off');
%     EEG = eeg_checkset( EEG );
     
end 