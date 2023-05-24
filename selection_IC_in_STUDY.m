% script for creating STUDY using all loaded datasets in eeglab; 
% for each dataset it select independent components (IC) whcih have r.v. < 15% and by ICLabel plugin marked as 'Brain' with probability > 70%
% this approach used also in other papers such as Miyakoshi, M., Gehrke, L., Gramann, K., Makeig, S., & Iversen, J. (2021). The AudioMaze: An EEG and motion capture study of human spatial navigation in sparse augmented reality. Eur J Neurosci. https://doi.org/10.1111/ejn.15131

% add basic info about STUDY
[STUDY ALLEEG] = std_editset( STUDY, ALLEEG, 'name','Allo_ego_dipfit_vers2','task','AEDIST','notes','IC: rv < 15 % and IClabel','updatedat','on', 'rmclust','on');
[STUDY ALLEEG] = std_checkset(STUDY, ALLEEG);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

for seti = 1:length(EEG) % for each dataset; partly code taken from Makoto's code: https://sccn.ucsd.edu/wiki/Makoto%27s_preprocessing_pipeline#How_to_perform_automated_IC_selection_using_IClabel.28.29_.2811.2F13.2F2019_updated.29 
    
    % Perform IC selection using ICLabel scores and r.v. from dipole fitting.
    % EEG(seti) = IClabel(EEG(seti), 'default'); it was already performed on subject level; here we use only results
    brainIdx  = find(EEG(seti).etc.ic_classification.ICLabel.classifications(:,1) >= 0.7);
    rvList    = [EEG(seti).dipfit.model.rv];
    goodRvIdx = find(rvList < 0.15);
    goodIcIdx = intersect(brainIdx, goodRvIdx);
    
    % input these good IC for each subject in STUDY
    [STUDY ALLEEG] = std_editset( STUDY, ALLEEG, 'commands',{{'index',seti,'comps',goodIcIdx'}},'updatedat','on','rmclust','on');
    [STUDY ALLEEG] = std_checkset(STUDY, ALLEEG);
end

eeglab redraw
