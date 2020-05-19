%EVENTSEEGLAB - script to plot ITI and RT for all trials from the actual EEG lab dataset 

% 1.2.2018
i10 =[EEG.event.type]==10 | [EEG.event.type]==11 | [EEG.event.type]==20 | [EEG.event.type]==21 | [EEG.event.type]==30 | [EEG.event.type]==31  ; %indexy podnetu
%{
10,11 Red 2D, 3D
20,21 Ego 2D, 3D
30,31 Allo 2D, 3D
%}
iresp = [EEG.event.type]==1 | [EEG.event.type]==2 ; %indexy odpovedi, 1,2 - spravne, spatne
latency10 = [EEG.event(i10).latency];
latencyResp = [EEG.event(iresp).latency];
if numel(latency10) > numel(latencyResp) %pokud je min odpovedi nez podnetu - nekdy neodpovedel
    iprvni = find(i10>0,1); %index prvniho podnetu
    inoresp = find(diff(i10(iprvni:end))==0)+iprvni-1; %indexy podnetu bez odpovedi
    latencyResp  = sort([latencyResp, EEG.event(inoresp).latency]); % k odpovedim pridam indexy podnetu bez odpovedi, ty pak budou mit rt=0
end
rtEEG =  (latencyResp - latency10(1:numel(latencyResp)))'/EEG.srate ;

itiEEG = diff(latency10)'/ EEG.srate;
figure('name','latency');
%ITI
plot(itiEEG,'.-'); %casy ITI z EEG modre
hold on;
itiCSV = diff(rtCSV(:,2)); %rtCSV ziskam kopii dat z CSV z excelu - druhy sloupec je ResponseOnsetClock
plot(itiCSV,'.-'); %casy z CSV ResponseOnsetClock - hnede

plot(rtEEG,'.-r'); %RT z EEG - cervene 
if exist('rtCSV','var')
    plot(rtCSV(:,1)/1000,'.-g'); %RT z CSV - zelene
end
ylim([0 6]);
legend({'ITI EEG','ITI CSV','RT EEG','RT CSV'});
disp(['itiEEG:' num2str(median(itiEEG))]);
disp(['rtEEG:' num2str(median(rtEEG))]);

rtdiff = rtEEG - rtCSV(1:numel(rtEEG),1)/1000; %rtCSV ziskam kopii dat z CSV z excelu
figure,plot(rtdiff);
legend({'rtEEG - rtCSV'});