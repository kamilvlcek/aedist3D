% can call preprocessing_over_subjects_last.m script repeatedly with a different setup
% setup
individChanLoc = 0; % parametr to choose between standard location file biosemi or individual digitized channel locations for each subject
rejectTrainingEpochs = 0; % to reject first training 18 trials from the data
rejectBadEpochs = 0; % to reject additionally bad epochs with an amplitude greater than threshold of -500 to 500 uV (function pop_eegthresh)
% and 6SD (standard-dev) as the criteria for the improbability test for single channels, and 2SD as the criteria for all channels (function pop_jointprob)

preprocessing_over_subjects_last;
