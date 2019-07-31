%nacti studii
%Clear Study
ERPTODO = 0;
STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
pop_editoptions( 'option_storedisk', 1, 'option_savetwofiles', 1, 'option_saveversion6', 1, 'option_single', 1, ...
    'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 1, 'option_scaleicarms', 1, ...
    'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, 'option_checkversion', 1, 'option_chat', 0); % nacist vsechno do pameti

%load study
if ERPTODO
    [STUDY ALLEEG] = pop_loadstudy('filename', 'ERP_study_NEW!.study', 'filepath', 'D:\eeg\CIIRK\JanaEEG\EEGnove');
else
    [STUDY ALLEEG] = pop_loadstudy('filename', 'SA_study_NEW!.study', 'filepath', 'D:\eeg\CIIRK\JanaEEG\EEGnove');
end

[STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, 'channels', 'ersp', 'on','erspparams',{'cycles', [3 0.8], 'nfreqs', 100, 'ntimesout', 200});