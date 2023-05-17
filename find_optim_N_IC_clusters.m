% How to obtain the optimum number of clusters,  
% Makoto's code here https://sccn.ucsd.edu/wiki/Makoto%27s_useful_EEGLAB_code#How_to_obtain_the_optimum_number_of_clusters_.2812.2F19.2F2021_updated.29

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Obtain all dipole xyz coordinates as a list. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dipXyz = [];
for subjIdx = 1:length(ALLEEG)
 
    % Obtain xyz, dip moment, maxProj channel xyz.   
    xyz = zeros(length(ALLEEG(subjIdx).dipfit.model),3);
    for modelIdx = 1:length(ALLEEG(subjIdx).dipfit.model)
 
        % Choose the larger dipole if symmetrical.
        currentXyz = ALLEEG(subjIdx).dipfit.model(modelIdx).posxyz;
        currentMom = ALLEEG(subjIdx).dipfit.model(modelIdx).momxyz; % nAmm.
        if size(currentMom,1) == 2
            [~,largerOneIdx] = max([norm(currentMom(1,:)) norm(currentMom(2,:))]);
            currentXyz = ALLEEG(subjIdx).dipfit.model(modelIdx).posxyz(largerOneIdx,:);
        end
        xyz(modelIdx,:) = currentXyz;
    end
    dipXyz = [dipXyz; xyz];
end
 
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Optimize the number of clusters between the range 5-15. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reduce data dimension using PCA. Use Matlab function evalclusters().
kmeansClusterIdxMatrix = zeros(size(dipXyz,1),11);
meanWithinClusterDistance = nan(11+4,11);
for clustIdx = 1:11
    [IDX, ~, SUMD] = kmeans(dipXyz, clustIdx+4, 'emptyaction', 'singleton', 'maxiter', 10000, 'replicate', 100);
    kmeansClusterIdxMatrix(:,clustIdx)            = IDX;
    numIcEntries = hist(IDX, 1:clustIdx+4);
    meanWithinClusterDistance(1:clustIdx+4, clustIdx) = SUMD./numIcEntries';
end
 
eva1 = evalclusters(dipXyz, kmeansClusterIdxMatrix, 'CalinskiHarabasz');
eva2 = evalclusters(dipXyz, kmeansClusterIdxMatrix, 'Silhouette');
eva3 = evalclusters(dipXyz, kmeansClusterIdxMatrix, 'DaviesBouldin');
 
figure
subplot(2,2,1)
boxplot(meanWithinClusterDistance)
set(gca, 'xticklabel', 5:15)
xlabel('Number of clusters')
ylabel('Mean distance to cluster centroid')
subplot(2,2,2)
plot(eva1); title('CalinskiHarabasz');
subplot(2,2,3)
plot(eva2); title('Silhouette');
subplot(2,2,4)
plot(eva3); title('DaviesBouldin');