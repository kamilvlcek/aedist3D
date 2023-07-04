% script for rejection of training epochs (in original data = 18), epochs with missing behavoral and incorrect responses over all subjects

disp('Please specify directory with preprocessed data')
path_data = uigetdir(path,'Select file directory.');
cd(path_data)

allFiles = dir(path_data); % all files in that directoty
folderNames = {allFiles([allFiles.isdir]).name}; % to get folder names
folderNames = folderNames(3:end); % without first 2 system folders

% initialize cell array to export info about all trials rejected for each subject
output = cell(length(folderNames), 6);
colNames = {'subject', 'N_trials_orig', 'N_rj_training_trials', 'N_rj_incorrect', 'N_rj_3events_trials', 'N_trials_left'};

eeglab; % Start eeglab

% For each of the subjects
for s = 1:length(folderNames)
    SubjectPath = [path_data '\' folderNames{s} '\'];
    file=dir([SubjectPath '*runica.set']); % dataset after preprocessing, epoching, and ICA decomposition
    EEG = pop_loadset('filename', file.name, 'filepath', SubjectPath);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);  % Store the current EEG to ALLEEG
    subject_name = regexp(file.name,'\.', 'split');  % split filename to separate subject's name and extension
    subject_name = subject_name{1};
    output{s,1} = subject_name; % save subject name to the output table
    nTrialsOrig = EEG.trials;
    output{s,2} = nTrialsOrig; %  save the number of all epochs after cleaning with clean_rawdata
    
    % remove training epochs
    if EEG.trials == 594 % if no windows of data were rejected by clean_rawdata, then in total should be 594 epochs, and first 18 are training
        EEG = pop_select( EEG, 'notrial',[1:18]);
    else % if some events were lost after window rejection of data by clean_rawdata
        trainingInd = ismember([EEG.event.urevent], 1:36); % first original 36 events correspond to 18 training epochs
        allEpochs = [EEG.event.epoch];
        trainingEpochs = allEpochs(trainingInd); % find training epochs
        EEG = pop_selectevent(EEG,'epoch',trainingEpochs,'deleteevents','off','deleteepochs','on','invertepochs','on'); % delete training epochs
    end
    EEG.comments = pop_comments(EEG.comments,'','training trials removed',1);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname',[subject_name '_without_training'],'savenew',[SubjectPath subject_name '_without_training.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    nTrialsAfterRjTraining = EEG.trials;
    output{s,3} = nTrialsOrig - nTrialsAfterRjTraining; %  save the number of rejected training epochs
    
    % remove incorrect trials
    EEG = pop_selectevent( EEG, 'type','correct','deleteevents','off','deleteepochs','on','invertepochs','off'); % leave only trials with correct reponse (incorrect and missed are deleted)
    nTrialsAfterRjIncorr = EEG.trials;
    output{s,4} = nTrialsAfterRjTraining - nTrialsAfterRjIncorr; %  save the number of rejected trials with incorrect and missed reponses
    
    % but it leaves also epochs with three events - such as 'correct','ego2D','correct'
    % contaminated by the event of long RT from previous trial with a latency e.g.  -584 ms before the stimulus (ego2D) (meaning real latency of that RT ~ 2,5 s)
    % in my view, such epochs also should be deleted as activity associated with RT contaminate the baseline activity in such trial
    ind3eventEpochs = find(cellfun(@(x) isequal(size(x), [1 3]), {EEG.epoch.event})); % find epochs which contain 3 events ('correct','ego2D','correct') instead of 2
    if ~isempty(ind3eventEpochs) % if there are any, delete them
        EEG = pop_selectevent(EEG,'epoch',ind3eventEpochs,'deleteevents','off','deleteepochs','on','invertepochs','on'); 
        output{s,5} = nTrialsAfterRjIncorr - EEG.trials; %  save the number of rejected trials with 3 events
    end
    output{s,6} = EEG.trials; %  save the number of left trials
    EEG.comments = pop_comments(EEG.comments,'','trials with incorrect and missed responses and trials with 3 events removed',1);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2, 'setname',[subject_name '_incorrect_rj'],'savenew',[SubjectPath subject_name '_incorrect_rj.set'],'gui','off');
    EEG = eeg_checkset( EEG );
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[]; % delete datasets from eeglab
end

eeglab redraw  % Update the main EEGLAB window

% export output table
xlsfilename = fullfile(path_data, 'rjepochs_over_subjects_output.xls');
xlswrite(xlsfilename, vertcat(colNames,output));
disp([ 'XLS table saved: ' xlsfilename]);
