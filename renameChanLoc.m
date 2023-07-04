function renameChanLoc(filename, biosemi)

% Sofia 2023
% function for mapping labels from one CSV file (biosemi132.ced) or digitized channel location file to the coordinates of
% channels in another CSV file (10-5 system) - standard_1005.csv - the channel location file associated with a model used in dipfit
% and renames the labels in the first file according to 10-5 system

%%% Example:
%  renameChanLoc('E:\CIIRK\new_data\Krios channel loc\from_Myrousz\transformed to eeglab format\as_20200224-163823.txt', 0)
%  biosemi = 1 or 0; % which cvs file to use - standard biosemi 128 or digitized channel location file from each subject

if ~exist('biosemi','var'), biosemi = 0; end

if biosemi == 1
    % Read the first CSV file - from standard biosemi 128 file
    data1 = readtable('e:\CIIRK\new_data\biosemi_128.csv');
    coordinates1 = data1{:, 5:7}; % the x,y,z coordinates
    labels1 = data1{:, 2}; % labels
else
    data1 = readtable(filename);
    coordinates1 = data1{1:128, 2:4}; % the x,y,z coordinates
    labels1 = data1{1:128, 5}; % labels
end

% the coordinates of biosemi or digitized chan loc should be scaled by 100 to match the second file
coordinates1 = coordinates1 * 100;

% Read the second CSV file
data2 = readtable('E:\CIIRK\new_data\for dipfit\adjusting_channel_locations_to_the_template\standard_1005.csv');
coordinates2 = data2{:, 5:7}; % the x,y,z coordinates

if biosemi == 0
    % in eeglab format .xyz stands for X = -Y, Y = X, Z = Z; which was already applied to digitized channel location file, here transformation for standard_1005.csv file to match each other:
    coordinates2_transf(:,1) = -1.*coordinates2(:,2);
    coordinates2_transf(:,2) = coordinates2(:,1);
    coordinates2_transf(:,3) = coordinates2(:,3);
    coordinates2 = coordinates2_transf;
end

labels2 = data2{:, 2}; %  labels in standard_1005.csv

% Create a cell array to store the mapping between the coordinates in the first file and the corresponding labels in the second file
mapping = cell(size(coordinates1, 1), 2);

% Iterate over the coordinates in the first file
for i = 1:size(coordinates1, 1)
    coord = coordinates1(i, :);
    % Find the index of the closest coordinate in the second file
    [~, index] = min(vecnorm(coordinates2 - coord, 2, 2));
    % Store the coordinate and the corresponding label in the mapping cell array
    mapping{i, 1} = coord;
    mapping{i, 2} = labels2{index};
end

if biosemi == 1
    % replace original labels in biosemi file by the new mapped ones from 10-5 system
    data1{:, 2} = mapping(:, 2);
    % save in a new csv file
    % writetable(data1,['e:\CIIRK\new_data\biosemi_128_new_labels' '.txt'],  'Delimiter', ' ','WriteVariableNames', 0);
    writetable(data1,'e:\CIIRK\new_data\biosemi_128_new_labels_without_rotat.csv', 'WriteVariableNames', 1);
else
    % Find duplicate labels
    [~, idxUnique] = unique(mapping(:, 2), 'stable');
    duplicate_indices = setdiff(1:numel(mapping(:, 2)), idxUnique);
    
    % replace original labels in digitized chan loc file by the new mapped ones from 10-5 system except duplicates
    idxGoodValues = setdiff(1:numel(mapping(:, 2)), duplicate_indices); % indices without duplicates (only one instance of duplicate)
    labels1(idxGoodValues) = mapping(idxGoodValues, 2);
    %     data1{1:128, 6} = labels1; % new column with new labels to compare with the old ones
    data1{1:128, 5} = labels1;
    
    % save in a new txt file
    subjectName = regexp(filename,'\.', 'split');  % split filename to separate subject's name and extension
    subjectName = subjectName{1};
    writetable(data1,[subjectName '_renamed.txt'],  'Delimiter', ' ','WriteVariableNames', 0);
end
end