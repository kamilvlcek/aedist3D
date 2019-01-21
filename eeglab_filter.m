% skript na hromadne filtrovani lidi na 0.1hz
%% uvodni nastaveni
freq = 0.1;
filenames = {};
dir = 'D:\\eeg\\CIIRK\\AEdist\\';
%% spustim cyklus
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

%ulozim soubor
EEG = pop_saveset( EEG, 'filename',[name ' 01Hz' ext],'filepath',dir);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

end