% Sofia 2023
% renameAllChanLoc renames labels in channel locations file according to standard_1005.csv file associated with a model used in dipfit for all subjects

cd 'E:\CIIRK\new_data\Krios channel loc\from_Myrousz\transformed to eeglab format'
files=dir('*.txt');   %  all txt files in this directory 

% For each subject
for s=1:length(files)
    chanLocFilename = files(s).name; % name of txt chan loc file 
    renameChanLoc(chanLocFilename);
    disp(['labels in chan loc file for subject ' chanLocFilename ' were succesfully renamed'])
end
