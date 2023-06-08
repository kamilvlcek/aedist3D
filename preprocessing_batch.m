% can call preprocessing_over_subjects_last.m script repeatedly with a different setup
% setup
individChanLoc = 0; % parametr to choose between standard location file biosemi or individual digitized channel locations for each subject
rejectBadEpochs = 0; % to reject additionally bad epochs with an amplitude greater than threshold of -500 to 500 uV (function pop_eegthresh)
% and 6SD (standard-dev) as the criteria for the improbability test for single channels, and 2SD as the criteria for all channels (function pop_jointprob)
rejectWindowData = 0;   % to control behavior of clean_artifacts function, if = 1, addtionally reject bad portions of data, where ASR didn't correct them
preprocessing_over_subjects_last;
