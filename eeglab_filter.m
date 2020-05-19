% EEGLAB_FILTER - script to group filtering of all subjects to 0.1hz (highpass)

%% setup
freq = 0.1;
filenames = {}; % fill with real filenames later
dir = 'D:\\eeg\\CIIRK\\AEdist\\'; %folder where the data are
%% run the cycle over filenames
%nactu soubor
for f = 1:numel(filenames)
disp([ '****** ' filenames{f} ' *********' ]); 
[filepath,name,ext] = fileparts(filenames{f});

EEG = pop_loadset('filename',filenames{f},'filepath',dir);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 ); %#ok<*ASGLU>
EEG = eeg_checkset( EEG );

%filtr
EEG = pop_eegfiltnew(EEG, [],freq,[],1,[],0); %16896
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',[EEG.setname '01Hz'],'gui','off'); 
EEG = eeg_checkset( EEG );

%save the file with new filename (01Hz added to the original name)
EEG = pop_saveset( EEG, 'filename',[name ' 01Hz' ext],'filepath',dir);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

end