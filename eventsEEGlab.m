%skript mi vykresli z aktualnich EEGlab datasetu ITI a RT pro vsechny trialy
% 1.2.2018
i10 =[EEG.event.type]==10; %indexy podnetu
iresp = [EEG.event.type]==1 | [EEG.event.type]==2 ;
latency10 = [EEG.event(i10).latency];
latencyResp = [EEG.event(iresp).latency];
rt =  latencyResp - latency10(1:numel(latencyResp));
figure('name','latency');
plot(diff(latency10),'.-');
hold on;
plot(rt,'.-r');
ylim([1000 3000]);
disp(num2str(median(diff(latency10))));
disp(num2str(median(rt)));
