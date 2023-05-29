% ERSPimg_clusters saves figures and stat results for all clusters for selected frequiences and groups of conditions

if ~exist('ERPTODO','var'), ERPTODO = 0; end % to select ERP or ERSP
if ~exist('EMFTODO','var'), EMFTODO = 0; end % to save jpg or emf images

% STUDY = pop_statparams(STUDY,'condstats','on','mode','fieldtrip','fieldtripmethod','montecarlo','fieldtripmcorrect','cluster'); % fieldtrip permutation statistics montecarlo method with cluster correction
STUDY = pop_statparams(STUDY, 'mode','eeglab','mcorrect','fdr','alpha',0.05); % parametric statistics with FDR correction, exact p < 0.05
STUDY = pop_erspparams(STUDY, 'freqrange',[2 100],'timerange',[-400 2000] ); % parameters for ERSP
STUDY = pop_erpparams(STUDY, 'plotconditions','together','topotime',[]); % parameters for ERP

clusters = {STUDY.cluster.name}; % all clusters in the study 
conditions = {{{'ego2D','ego3D'},{'allo2D','allo3D'},{'control2D','control3D'}}, {{'ego2D','ego3D'},{'allo2D','allo3D'}}}; % {{'allo2D'}, {'allo3D'}}}; TODO: add other contrasts e.g. 2D vs 3D

if ERPTODO
    freqs = {'ERP',0,0};     
else    
    % the frequency bands to analyze: name, freq range and position in the summary plot (=number of subplot)
    freqs = {'alfa',[8.5 13],2; 'beta', [14 30],3; 'theta', [4 8],5; 'lowgamma', [31 50],8;'highgamma',[51 100],9; 'delta',[1 3.5],6};       
end
fname = iff(ERPTODO,'ERP','ERSP');
statresults = cell(1+(numel(clusters)-2)*numel(conditions),2+size(freqs,1)); % output of statistics results
statresults(1,:) = [{'conditions','cluster'},freqs(:,1)']; % variable names 
xlsfilename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' fname '.xls'];

for cond = 1:numel(conditions)  % over all conditions groups
    disp([' *********** CONDITION ' cell2str(conditions{1}) ' **********' ]);
    STUDY = std_makedesign(STUDY, ALLEEG, 4, 'name','STUDY.design_4','delfiles','off','defaultdesign','off','variable1','type','values1', conditions{cond},'vartype1','categorical'...
        ,'subjselect',{'ag20200131','as20200224','db20190128','dw20190325','ez20200207','jk20190418','jm20190401','ks20190322','kz20190328','md20200312','mk20190209','mm20190228','na20190119','pm20190314','tc20190105','vl20190404'}); 

    [STUDY EEG] = pop_savestudy( STUDY, ALLEEG, 'savemode','resave'); 

    for icluster = 3:numel(clusters)   % over all clusters but without parent and outlier clusters (first two)
       disp([' +++++  CLUSTER ' clusters{icluster} ' +++++' ]);
       clustername = clusters{icluster};
       clusterLabel = STUDY.cluster(icluster).anatomLabel; % anatomical label of cluster obtained after calling script IC_clusters_labeling_STUDY.m
       istat = (cond-1)*numel(clusters)+icluster+1;
       try % not to fail the whole script because of one error in one cluster
        if ERPTODO
            [STUDY erpdata erptimes pgroup pcond pinter] = std_erpplot(STUDY,ALLEEG,'clusters',icluster, 'design', 4); % ERP plot
            % erpdata 3x1 cell, matrix time x components
        else    
            [STUDY erspdata ersptimes erspfreqs pgroup pcond pinter] = std_erspplot(STUDY,ALLEEG,'clusters',icluster,'design', 4); % ersp plot
            % erspdata - 3x1 cell, matrix [freqs x times x components]
        end  
        
        fig = gcf; % handle to the plot

        % set figure size and position
        set(fig, 'Position',  [1 1 2000 1000]); 
        
        clustername = [clustername '_' clusterLabel]; % name includes number of cluster and anatomical label
        
        if ~EMFTODO
            filename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' fname '_' cell2str(conditions{cond},1) '_' clustername];
            print(fig,filename,'-djpeg'); % save the figure
        else
            filename = [STUDY.filepath '\\figures_export_emf\\' STUDY.name '_' fname '_' cell2str(conditions{cond},1) '_' clustername];
            print(fig,filename,'-dmeta');% save the figure
        end
        
        close(fig); 
        
        if ~ERPTODO % for ERSP 
            pmin = erspimgT(erspdata,ersptimes,erspfreqs,STUDY,conditions{cond},clustername,EMFTODO,freqs, 1); % compute means, saves figures, returns p values from stats
            statresults(istat,:) = [{cell2str(conditions{cond}),clustername},num2cell(pmin)];
        else  % for ERP
            pmin = erpimgT(erpdata,erptimes,STUDY,conditions{cond},clustername,EMFTODO);
            statresults(istat,:) = {cell2str(conditions{cond}),clustername,pmin};
        end
      catch exception 
             errorMessage = exceptionLog(exception);
             disp(errorMessage);     % display error message if there was any                                         
             statresults(istat,1:3) = {cell2str(conditions{cond}),clustername,'error'};
      end
    end    
    xlswrite(xlsfilename, statresults); % write to xls table statistic results
end
disp('Done');
