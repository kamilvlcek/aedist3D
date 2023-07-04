% importAllChanLoc adapts csv channel locations files to the correct format in eeglab for all subjects

cd 'E:\CIIRK\new_data\Krios channel loc\from_Myrousz'
files=dir('*.csv');   %  all csv files in this directory 

% For each subject
for s=1:length(files)
    chanLocFilename = files(s).name; % name of csv file obtained via Myrousz's code
    subject = importChanLocCSV(chanLocFilename);
    disp(['csv file for subject ' chanLocFilename ' succesfully converted to txt'])
end
