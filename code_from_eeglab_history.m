% some useful code from eeglab history (when these steps were done in gui)
%% Locating dipoles using DIPFIT in one subject from gui eeglab history
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename','jm20190401_ICA.set','filepath','E:\\CIIRK\\new_data\\EEG_data\\pre-processed data\\final_all_subjects\\jm20190401\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

EEG=pop_chanedit(EEG, []); % load new channel loc file
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_reref( EEG, [],'exclude',[126:129] ); % average reference
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','jm20190401_ICA_chan_loc_10_5','savenew','E:\\CIIRK\\new_data\\EEG_data\\pre-processed data\\final_all_subjects\\jm20190401\\jm20190401_ICA_chan_loc_10_5.set','overwrite','on','gui','off'); 

EEG=pop_chanedit(EEG, []);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = pop_reref( EEG, [],'exclude',[126:129] );

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

% Co-registration of head model and electrode locations
EEG = pop_dipfit_settings( EEG, 'hdmfile','D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.1\\standard_BEM\\standard_vol.mat','mrifile','D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.1\\standard_BEM\\standard_mri.mat','chanfile','D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.1\\standard_BEM\\elec\\standard_1005.elc','coordformat','MNI','coord_transform',[0.52588 -8.4007 -1.9173 0.037341 -0.0068294 -1.5684 98.2903 93.4194 97.4829] ,'chansel',[1:125] );
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);


% apply this matrix to another subject to locate dipoles in dipfit
EEG = pop_loadset('filename','as20200224_ICA.set','filepath','E:\\CIIRK\\new_data\\EEG_data\\pre-processed data\\final_all_subjects\\as20200224\\');
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

EEG = pop_dipfit_settings( EEG, 'hdmfile','D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.1\\standard_BEM\\standard_vol.mat','mrifile','D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.1\\standard_BEM\\standard_mri.mat','chanfile','D:\\instalace\\eeglab2023.0\\plugins\\dipfit5.1\\standard_BEM\\elec\\standard_1005.elc','coordformat','MNI','coord_transform',[0.52588 -8.4007 -1.9173 0.037341 -0.0068294 -1.5684 98.2903 93.4194 97.4829] ,'chansel',[1:120] );

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

EEG = pop_multifit(EEG, [1:123] ,'threshold',100,'dipoles',2,'dipplot','on','plotopt',{'normlen','on'});

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);


%% creating study with IC and dipfit info; preclustering, clustering using kmeans with number of clusters = 14, plotting
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
[STUDY ALLEEG] = pop_loadstudy('filename', 'Allo_ego_without_source.study', 'filepath', 'E:\CIIRK\new_data\EEG_data\pre-processed data');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
[STUDY ALLEEG] = std_editset( STUDY, ALLEEG, 'name','Allo_Ego_dipfit','task','Aedist','notes','study for comparing consition on source level after dipole fitting','commands',{{'inbrain','on','dipselect',0.15}},'updatedat','on','rmclust','on' );
[STUDY ALLEEG] = std_checkset(STUDY, ALLEEG);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
EEG = pop_saveset( EEG, 'savemode','resave');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
STUDY = std_checkset(STUDY, ALLEEG);
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'filename','Allo_Ego_dipfit.study','filepath','E:\\CIIRK\\new_data\\EEG_data\\pre-processed data\\');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','STUDY.AlloEgoCtrl','delfiles','off','defaultdesign','off','variable1','type','values1',{{'allo2D','allo3D'},{'control2D','control3D'},{'ego2D','ego3D'}},'vartype1','categorical','subjselect',{'ag20200131','as20200224','db20190128','dw20190325','ez20200207','jk20190418','jm20190401','ks20190322','kz20190328','md20200312','mk20190209','mm20190228','na20190119','pm20190314','tc20190105','vl20190404'});
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','Allo vs Ego vs Ctrl (2D and 3D grouped together)','delfiles','off','defaultdesign','off','variable1','type','values1',{{'allo2D','allo3D'},{'control2D','control3D'},{'ego2D','ego3D'}},'vartype1','categorical','subjselect',{'ag20200131','as20200224','db20190128','dw20190325','ez20200207','jk20190418','jm20190401','ks20190322','kz20190328','md20200312','mk20190209','mm20190228','na20190119','pm20190314','tc20190105','vl20190404'});
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, 'components','savetrials','on','recompute','on','erp','on','scalp','on','spec','on','specparams',{'specmode','fft','logtrials','off'},'erpim','on','erpimparams',{'nlines',10,'smoothing',10},'ersp','on','erspparams',{'cycles',[3 0.8] ,'nfreqs',30,'ntimesout',60},'itc','on');
eeglab('redraw');
[STUDY ALLEEG] = std_preclust(STUDY, ALLEEG, 1,{'dipoles','weight',1},{'moments','weight',1});

STUDY = std_dipplot(STUDY,ALLEEG,'clusters',2, 'design', 1, 'comps',1 );
[STUDY] = pop_clust(STUDY, ALLEEG, 'algorithm','kmeans','clus_num',  14 , 'outliers',  3 );

STUDY = std_topoplot(STUDY,ALLEEG,'clusters',[2   3   4   5   6   7   8   9  10  11  12  13  14  15  16], 'design', 1);
STUDY = pop_dipparams(STUDY, 'centrline','off');
STUDY = pop_erspparams(STUDY, 'timerange',[-400 1500] ,'freqrange',[1 100] );
STUDY = std_erspplot(STUDY,ALLEEG,'clusters',3, 'design', 1);
STUDY = pop_erspparams(STUDY, 'timerange',[-200 1500] ,'freqrange',[1 120] );
STUDY = std_erspplot(STUDY,ALLEEG,'clusters',3, 'design', 1);
STUDY = std_erspplot(STUDY,ALLEEG,'clusters',4, 'design', 1);
STUDY = std_erspplot(STUDY,ALLEEG,'clusters',5, 'design', 1);
STUDY = std_erspplot(STUDY,ALLEEG,'clusters',6, 'design', 1);
STUDY = std_topoplot(STUDY,ALLEEG,'clusters',6, 'design', 1);
STUDY = std_itcplot(STUDY,ALLEEG,'clusters',6, 'design', 1);
STUDY = pop_erpimparams(STUDY, 'topotime',[],'timerange',[-200 1200] );
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resavegui');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];


