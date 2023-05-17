% Sofia May 2023
% mapping labels from one CSV file (biosemi132.ced) to the coordinates of
% channels in another CSV file (10-5 system) - standard_1005.csv

% Read the first CSV file
data1 = readtable('e:\CIIRK\new_data\biosemi_128.csv');
coordinates1 = data1{:, 5:7}; % the x,y,z coordinates 
labels1 = data1{:, 2}; % labels 

% the coordinates of biosemi should be scaled by 100 to match the second file
coordinates1 = coordinates1 * 100; 

% Read the second CSV file
% data2 = readtable('e:\CIIRK\new_data\standard_1005_rotated.csv');
data2 = readtable('e:\CIIRK\new_data\standard_1005.csv');
coordinates2 = data2{:, 5:7}; % the x,y,z coordinates 
labels2 = data2{:, 2}; %  labels 

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

% replace original labels in biosemi file by the new mapped ones from 10-5 system
data1{:, 2} = mapping(:, 2);

% save in a new csv file
% writetable(data1,['e:\CIIRK\new_data\biosemi_128_new_labels' '.txt'],  'Delimiter', ' ','WriteVariableNames', 0);
writetable(data1,'e:\CIIRK\new_data\biosemi_128_new_labels_without_rotat.csv', 'WriteVariableNames', 1);
