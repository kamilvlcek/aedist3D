
ERPTODO = 0;

%nacti studii
%[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
%[STUDY ALLEEG] = pop_loadstudy('filename', 'AEdist SA.study', 'filepath', 'D:\eeg\CIIRK\JanaEEG');
%[STUDY ALLEEG] = pop_loadstudy('filename', 'AEdist ERP.study', 'filepath', 'D:\eeg\CIIRK\JanaEEG');
%CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

STUDY = pop_statparams(STUDY, 'condstats','on','mode','fieldtrip','fieldtripmethod','montecarlo','fieldtripmcorrect','cluster');
STUDY = pop_erspparams(STUDY, 'freqrange',[1 120] ); %parametry pro ERSP
STUDY = pop_erpparams(STUDY, 'plotconditions','together','topotime',[]); %parametry pro ERP

channels = {STUDY.changrp.channels};
conditions = {{'allo' 'ego' 'control'}, {'allo' 'ego'}, {'allo' 'control'},{'ego' 'control'}};
set(groot, 'DefaultFigureVisible', 'off') %vsechny vytvorene obrazku budou neviditelne - ale nefunguje

for c = 1:numel(conditions)  
    disp([' *********** CONDITION ' cell2str(conditions{1}) ' **********' ]);              
    STUDY = std_makedesign(STUDY, ALLEEG, 1, 'variable1','condition','variable2','','name','STUDY.design 1','pairing1','on','pairing2','on', ...
                'delfiles','off','defaultdesign','off','values1',conditions{c}, ... 
                'subjselect',{'1' '2' '3' '4' '5' '6' '7' '8' '9'  '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20' '21'});    
    [STUDY EEG] = pop_savestudy( STUDY, ALLEEG, 'savemode','resave'); %#ok<NCOMMA>

    for ch = 1:numel(channels)   
        disp([' +++++  CHANNEL ' channels{ch}{1} ' +++++' ]);
        if ERPTODO
            STUDY = std_erpplot(STUDY,ALLEEG,'channels',channels{ch});  %ERP plot
        else
            std_erspplot(STUDY,ALLEEG,'channels',channels{ch}); % ERSP plot
            %erspdata - 3x1 cell, 83x106x1x21 matrix freq x time x ch x subjects
        end
                
        fig = gcf; %ziskam handle na aktualni obrazek
        set(fig, 'Visible', 'off'); %hned ho schovam

        %zvetsim a ulozim aktualni obrazek
        set(fig, 'Position',  [1 1 1000 500]); % velikost obrazku je z nejakeho duvodu relativni vzhledem k monitoru
        fname = iff(ERPTODO,'ERP','ERSP');
        filename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' fname '_' cell2str(conditions{c},1) '_' channels{ch}{1}];
        print(fig,filename,'-djpeg');
        print(fig,filename,'-dmeta');
        close(fig); %zavre aktualni obrazek
    end

end
set(groot, 'DefaultFigureVisible', 'on');
disp('Hotovo');
%zobraz ERP s stderr
% jak statistika?
%STUDY = pop_erpparams(STUDY, 'condstats', 'on');
%[STUDY erpdata erptimes] = std_erpplot(STUDY,ALLEEG,'channels',{ 'FP1'});
%std_plotcurve(erptimes, erpdata, 'plotconditions', 'together', 'plotstderr', 'on', 'figure', 'on');