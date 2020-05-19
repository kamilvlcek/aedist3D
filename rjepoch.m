%reject events
%reject events where the subjects made error or did not respond
epochsn = 594;
istim =[EEG.event.type]==10 | [EEG.event.type]==11 | [EEG.event.type]==20 | [EEG.event.type]==21 | [EEG.event.type]==30 | [EEG.event.type]==31  ; %indexy podnetu
assert(sum(istim) == epochsn, [ 'nespravny pocet podnetu ' num2str(sum(istim)) ]); %kontrola spravneho poctu epoch

iresp_err = [EEG.event.type]==2; %indexy chybnych odpovedi

%ommitted responses
istim_x = find(istim(1:end-1)== istim(2:end)); %cisla pondetu s vynechanymi odpovedmi
for j = istim_x
    EEG.event(j).type = EEG.event(j).type + 800; %change type to exclude from eeg analysis, but saves the original number
end
disp([ 'vynechanych odpovedi: ' num2str(numel(istim_x)) ', oznaceny 8xx']); 

%error responses
istim_err = find(iresp_err)-1; %cisla podnetu s chybnou odpovedi
for j = istim_err
    EEG.event(j).type = EEG.event(j).type + 900; %change type to exclude from eeg analysis, but saves the original number
end
disp([ 'chybnych odpovedi: ' num2str(numel(istim_err)) ', oznaceny 9xx']); 

%saves EEG back to ALLEEG
[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);