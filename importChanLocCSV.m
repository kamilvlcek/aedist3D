function subject = importChanLocCSV(filename)
%    db20190128 = importChanLocCSV(FILENAME) reads channel location data from csv file (obtained from Myrousz)
%    and adapts it to format suitable for EEGLAB
%    saves it in txt file in the following format:
%       chanIndex   X  Y  Z  label
%
% Example:
%   as_20200224 = importChanLocCSV('e:\CIIRK\scripts\kvstuff-eeg-ransac\target\as_20200224-163823.labeled.csv')

% first read table
dataTable = readtable(filename, 'Delimiter', ',');
% then convert to cell array
dataCell = table2cell(dataTable);

% choose only important columns with the nessesary info
data = dataCell(:,[12:14 8]); %  x_trans  y_trans	z_trans,  Standard Label
data(end-3:end, 4) = dataCell(end-3:end,7); % take last 4 names (of fiducials) in Special Sensor and put in label column

% 6 channels are not labeled: 4 EOG, and 2 on the head - CMS and DRL - special sensors of BIOSEMI for reference
% 2 on the head -  CMS and DRL, have positive Z coordinate, so try to find them among non-labeled channels:
ind_addiotinal_chan = find(cellfun(@isempty,data(:,4)) & cell2mat(data(:,3))>0);
% in the EEG data we don't have them, so they should be deleted from the channel locations file
data(ind_addiotinal_chan,:) = [];

% data{ind_addiotinal_chan(1), 4} = {'RCMS'};
% data{ind_addiotinal_chan(2), 4} = {'RDRL'};

% find all other empty channels and labeled them as EOG1, EOG2...
% data(find(cellfun(@isempty,data(:,4))), 4) = {'EOG'};
EOG_indexes = find(cellfun(@isempty,data(:,4)));
for ind=1:length(EOG_indexes)
    data{EOG_indexes(ind), 4} = {['EOG' num2str(ind)]};
end

%% sort data on label column simultaneously in alphabetical order and numbers in ascending order

% convert all elements to single character arrays
data(:, 4) = cellfun(@(x) char(x), data(:, 4), 'UniformOutput', false);
col = data(:, 4);

% check if all cells are strings
if ~iscellstr(col)
    error('All elements of the input cell array must be strings');
end

% split the strings into letters and numbers
letters = regexp(col, '[a-zA-Z]*', 'match', 'once');
numbers = regexp(col, '\d*', 'match', 'once');

% convert the numbers to doubles
numbers = str2double(numbers);

% combine the letters and numbers into a cell array
combined = cellfun(@(l,n) [l num2str(n, '%03d')], letters, num2cell(numbers), 'UniformOutput', false);

% sort the combined cell array and return sorted indexes
[~, indexes] = sort(combined);

% sort data based on new indexes
sorted_data = data(indexes,:);

% rename fiducials to the standard names in eeglab
sorted_data{end-3, 4} = {'LPA'}; % left pre-auricular point
sorted_data{end-2, 4} = {'Nz'}; % nasion
sorted_data{end-1, 4} = {'RPA'}; % right pre-auricular point
sorted_data{end, 4} = {'inion'}; % inion 

%% Create output variable
subject = table;
subject.index = linspace(1, size(sorted_data,1),size(sorted_data,1))';
% in eeglab format .xyz stands for X = -Y, Y = X, Z = Z; here transformation:
subject.X = -1.*cell2mat(sorted_data(:, 2));
subject.Y = cell2mat(sorted_data(:, 1)); 
subject.Z = cell2mat(sorted_data(:, 3));
subject.label = sorted_data(:, 4);

% Save in txt file
subjectName = regexp(filename,'\.', 'split');  % split filename to separate subject's name and extension
% subjectName = regexp(filename,'.csv', 'split');
subjectName = subjectName{1};
writetable(subject,[subjectName '.txt'],  'Delimiter', ' ','WriteVariableNames', 0);
end