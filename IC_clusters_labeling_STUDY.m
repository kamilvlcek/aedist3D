%%% How to obtain anatomical labels using Fieldtrip for clusters of ICs in STUDY
%%% adapted from Makoto's code:
%%% https://sccn.ucsd.edu/wiki/Makoto%27s_useful_EEGLAB_code#How_to_obtain_anatomical_labels_using_Fieldtrip_.2807.2F08.2F2022_added.29 

% Set path to Fieldtrip's AAL library.
addpath('D:\instalace\eeglab2023.0\plugins\Fieldtrip-lite20230606')
ft_defaults
 
% Obtain the Automated Anatomical Label (AAL) library (Tzourio-Mazoyer et al., 2002)
aal = ft_read_atlas('D:\instalace\eeglab2023.0\plugins\Fieldtrip-lite20230606\template\atlas\aal\ROI_MNI_V4.nii');
 
% Obtain the current IC-dipole xyz for individual eeg dataset
% currentXyz = EEG(1).dipfit.model(1).posxyz; % For the IC1.
% inputData = currentXyz;

% initialize cell array to store all info about clusters
clustersLabels = cell(length(STUDY.cluster)-2, 4);

for icluster = 3:length(STUDY.cluster)  % first cluster is Parentcluster containing all others, second - outlier, so start from 3d
    
    % Obtain the dipole xyz for centroid of each IC cluster
    currentXyz = STUDY.cluster(icluster).dipole.posxyz; % take the positions of the centroid
    inputData = currentXyz;
    
    % Transform the current xyz into the specified format.
    aalCoordinates = round([(inputData(1)-aal.transform(1,4))/aal.transform(1,1) ...
        (inputData(2)-aal.transform(2,4))/aal.transform(2,2) ...
        (inputData(3)-aal.transform(3,4))/aal.transform(3,3)]);
    aal.transform*[aalCoordinates(1);aalCoordinates(2);aalCoordinates(3);1]; % For a validation.
    
    % Find the 10 closest ROIs.
    uniqueROIs = unique(aal.tissue(:));
    minDistVector = zeros(length(uniqueROIs)-1,1);
    for uniqueRoiIdx = 1:length(minDistVector) % 0 is outside the brain.
        currentRoiMask   = aal.tissue == uniqueRoiIdx;
        currentRoiMask1D = find(currentRoiMask(:));
        [X,Y,Z] = ind2sub(size(aal.tissue), currentRoiMask1D);
        distVec = sqrt(sum(bsxfun(@minus, [X Y Z], [aalCoordinates(1), aalCoordinates(2), aalCoordinates(3)]).^2, 2));
        minDistVector(uniqueRoiIdx) = min(distVec);
    end
    [sortedDist, sortingIdx] = sort(minDistVector);
    brainIcAnatomicalLabels    = aal.tissuelabel(sortingIdx(1:10))';
    brainIcAnatomicalDistances = sortedDist(1:10)*mean([abs(aal.transform(1,1)) abs(aal.transform(2,2)) abs(aal.transform(3,3))]);
    
    % put the anatomic label of the closest ROI in STUDY structure
    STUDY.cluster(icluster).anatomLabel = brainIcAnatomicalLabels{1};
    
    % put characteristics of the cluster to the cell for export
    clustersLabels{(icluster-2),1} = STUDY.cluster(icluster).name; % the name of cluster in EEGLAB
    clustersLabels{(icluster-2),2} = STUDY.cluster(icluster).dipole.posxyz; % the positions of cluster's centroid 
    clustersLabels{(icluster-2),3} = brainIcAnatomicalLabels; % corresponding 10 closest ROI from aal atlas sorting from the closest
    clustersLabels{(icluster-2),4} = brainIcAnatomicalDistances'; % corresponding distances between these 10 ROIs and centroid
end

%% save the xls table with all clusters and their 10 closest ROIs with distances

% first transform cell array to the format suitable for xls table

num_rows = size(clustersLabels, 1);

% Create empty arrays to store flattened data
flattened_cluster_name = cell(num_rows, 1);
flattened_xyz_centroid = zeros(num_rows, 3);
flattened_closest_ROIs = cell(num_rows, 10);
flattened_distances_to_ROI = zeros(num_rows, 10);

% Flatten the data
for i = 1:num_rows
    flattened_cluster_name{i} = clustersLabels{i, 1};
    flattened_xyz_centroid(i, :) = clustersLabels{i, 2};
    flattened_closest_ROIs(i, :) = clustersLabels{i, 3};
    flattened_distances_to_ROI(i, :) = clustersLabels{i, 4};
end

% Write the headers
xlspath = 'E:\CIIRK\new_data\EEG_data\pre-processed_data\';
xlsfilename = fullfile(xlspath,  'clusters_of_ICs_labeled.xls');

headers = {'cluster_name', 'x_centroid', 'y_centroid', 'z_centroid', 'closest_ROI1'};
xlswrite(xlsfilename, headers, 1, 'A1');
xlswrite(xlsfilename, {'distances_to_ROI1'}, 1, 'O1');

% Write the flattened data
xlswrite(xlsfilename, flattened_cluster_name, 1, 'A2');
xlswrite(xlsfilename, flattened_xyz_centroid, 1, 'B2');
xlswrite(xlsfilename, flattened_closest_ROIs, 1, 'E2');
xlswrite(xlsfilename, flattened_distances_to_ROI, 1, 'O2');
