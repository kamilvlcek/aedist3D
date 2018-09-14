%skript mi vykresli z aktualnich EEGlab datasetu ITI a RT pro vsechny trialy
% 1.2.2018
i10 =[EEG.event.type]==10 | [EEG.event.type]==11 | [EEG.event.type]==20 | [EEG.event.type]==21 | [EEG.event.type]==30 | [EEG.event.type]==31  ; %indexy podnetu
%{
10,11 Red 2D, 3D
20,21 Ego 2D, 3D
30,31 Allo 2D, 3D
%}
iresp = [EEG.event.type]==1 | [EEG.event.type]==2 ;
% 1,2 - spravne, spatne
latency10 = [EEG.event(i10).latency];
latencyResp = [EEG.event(iresp).latency];
rt =  (latencyResp - latency10(1:numel(latencyResp)))'/EEG.srate ;
iti = diff(latency10)'/ EEG.srate;
figure('name','latency');
plot(iti/2,'.-'); %casy z CSV jsou kratsi, mozna nesedi srate a je 4kHz?
hold on;
plot(rt/2,'.-r'); %casy z CSV jsou kratsi, mozna nesedi srate a je 4kHz?
if exist('rtCSV','var')
    plot(rtCSV/1000,'.-g');
end
ylim([0 3]);
disp(num2str(median(iti)));
disp(num2str(median(rt)));

rtdiff = rtCSV/1000 - rt/2; %rtCSV ziskam kopii dat z CSV z excelu
figure,plot(rtdiff);