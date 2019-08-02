%promenne nastaveni, ktere ale muzu nastavit i drive
if ~exist('ERPTODO','var'), ERPTODO = 1; end %jestli ERP nebo ERSP
if ~exist('EMFTODO','var'), EMFTODO = 0; end %jestli jpg nebo EMf obrazky

%nacti studii
%Clear Study
STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
pop_editoptions( 'option_storedisk', 1, 'option_savetwofiles', 1, 'option_saveversion6', 1, 'option_single', 1, ...
    'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 1, 'option_scaleicarms', 1, ...
    'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, 'option_checkversion', 1, 'option_chat', 0); % nacist vsechno do pameti

%load study
if ERPTODO
    [STUDY ALLEEG] = pop_loadstudy('filename', 'ERP_study_NEW!.study', 'filepath', 'D:\eeg\CIIRK\JanaEEG\EEGnove');
else
    [STUDY ALLEEG] = pop_loadstudy('filename', 'SA_study_NEW!.study', 'filepath', 'D:\eeg\CIIRK\JanaEEG\EEGnove');
end
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

%STUDY = pop_statparams(STUDY, 'condstats','on','mode','fieldtrip','fieldtripmethod','montecarlo','fieldtripmcorrect','cluster');
STUDY = pop_statparams(STUDY, 'mode','eeglab','mcorrect','fdr','alpha',0.05); %parametricka statistika s FDR korekci, exact p < 0.05
STUDY = pop_erspparams(STUDY, 'freqrange',[1 120],'timerange',[-1000 2000] ); %parametry pro ERSP
STUDY = pop_erpparams(STUDY, 'plotconditions','together','topotime',[]); %parametry pro ERP

channels = {STUDY.changrp.channels};
conditions = {{'2D','3D'}, {'allo' 'ego' 'control'}, {'allo' 'ego'}, {'allo' 'control'},{'ego' 'control'}};
set(groot, 'DefaultFigureVisible', 'off') %vsechny vytvorene obrazku budou neviditelne - ale nefunguje
if ERPTODO
    freqs = {'ERP',0,0};     
else    
    freqs = {'alfa',[8 13],2; 'beta', [14 30],3; 'theta', [4 7.5],5; 'lowgamma', [31 50],8;'highgamma',[51 100],9; 'delta',[1 3.5],6}; % nazvy a pasma frekvenci, + cislo subplotu      
end
fname = iff(ERPTODO,'ERP','ERSP');
statresults = cell(1+numel(channels)*numel(conditions),2+size(freqs,1)); %tam budu ukladat vysledky statistiky
statresults(1,:) = [{'conditions','channel'},freqs(:,1)'];
xlsfilename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' fname '.xls'];

for cond = 1:numel(conditions)  
    disp([' *********** CONDITION ' cell2str(conditions{1}) ' **********' ]);              
    STUDY = std_makedesign(STUDY, ALLEEG, 1, 'variable1','condition','variable2','','name','STUDY.design 1','pairing1','on','pairing2','on', ...
                'delfiles','off','defaultdesign','off','values1',conditions{cond}, ... 
                'subjselect',{'1' '2' '3' '4' '5' '6' '7' '8' '9'  '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20' '21'});    
    [STUDY EEG] = pop_savestudy( STUDY, ALLEEG, 'savemode','resave'); %#ok<NCOMMA>

    for ch = 1:numel(channels)   
       disp([' +++++  CHANNEL ' channels{ch}{1} ' +++++' ]);
       channelname = channels{ch}{1};
       istat = (cond-1)*numel(channels)+ch+1;
       try 
        if ERPTODO
            [STUDY erpdata erptimes pgroup pcond pinter] = std_erpplot(STUDY,ALLEEG,'channels',channels{ch}); %#ok<NCOMMA> %ERP plot
            %erpdata 3x1 cell, matrix 1536x21 time x subjects
        else
            [STUDY erspdata ersptimes erspfreqs pgroup pcond pinter] = std_erspplot(STUDY,ALLEEG,'channels',channels{ch}); %#ok<NCOMMA> % ERSP plot
            %erspdata - 3x1 cell, matrix 83x106x1x21  freq x time x ch x subjects
                                        
        end  
        
        
        fig = gcf; %ziskam handle na aktualni obrazek
        set(fig, 'Visible', 'off'); %hned ho schovam

        %zvetsim a ulozim aktualni obrazek
        set(fig, 'Position',  [1 1 1000 500]); % velikost obrazku je z nejakeho duvodu relativni vzhledem k monitoru
        
        if length(channelname)==2
           channelname = [ channelname(1) '0' channelname(2)]; %pridam nulu, aby byly serazene soubory podle cisla
        end
        if ~EMFTODO
            filename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' fname '_' cell2str(conditions{cond},1) '_' channelname];
            print(fig,filename,'-djpeg');
        else
            filename = [STUDY.filepath '\\figures_export_emf\\' STUDY.name '_' fname '_' cell2str(conditions{cond},1) '_' channelname];
            print(fig,filename,'-dmeta');
        end
        close(fig); %zavre aktualni obrazek
        
        if ~ERPTODO %jen pro ersp
            pmin = erspimgT(erspdata,ersptimes,erspfreqs,STUDY,conditions{cond},channelname,EMFTODO,freqs); 
            statresults(istat,:) = [{cell2str(conditions{cond}),channelname},num2cell(pmin)];
        else
            pmin = erpimgT(erpdata,erptimes,STUDY,conditions{cond},channelname,EMFTODO);
            statresults(istat,:) = {cell2str(conditions{cond}),channelname,pmin};
        end
      catch exception 
             errorMessage = exceptionLog(exception);
             disp(errorMessage);     %zobrazim hlasku, zaloguju, ale snad to bude pokracovat dal                                          
             statresults(istat,1:3) = {cell2str(conditions{cond}),channelname,'error'};
      end
    end    
    xlswrite(xlsfilename, statresults); %zapisu do xls tabulky 
end
set(groot, 'DefaultFigureVisible', 'on');
disp('Hotovo');
%zobraz ERP s stderr
% jak statistika?
%STUDY = pop_erpparams(STUDY, 'condstats', 'on');
%[STUDY erpdata erptimes] = std_erpplot(STUDY,ALLEEG,'channels',{ 'FP1'});
%std_plotcurve(erptimes, erpdata, 'plotconditions', 'together', 'plotstderr', 'on', 'figure', 'on');