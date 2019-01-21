%reject events
%vyradi udalosti, kde subjekt udelal chybu nebo kde neodpovedel
epochsn = 594;
istim =[EEG.event.type]==10 | [EEG.event.type]==11 | [EEG.event.type]==20 | [EEG.event.type]==21 | [EEG.event.type]==30 | [EEG.event.type]==31  ; %indexy podnetu
assert(sum(istim) == epochsn, [ 'nespravny pocet podnetu ' num2str(sum(istim)) ]); %kontrola spravneho poctu epoch

iresp_err = [EEG.event.type]==2; %indexy chybnych odpovedi

istim_x = find(istim(1:end-1)== istim(2:end)); %cisla pondetu s vynechanymi odpovedmi
for j = istim_x
    EEG.event(j).type = EEG.event(j).type + 800; %zmenim type aby vyrazeno z eeganalyzy, ale zachovam puvodni cislo
end
disp([ 'vynechanych odpovedi: ' num2str(numel(istim_x)) ', oznaceny 8xx']); 

istim_err = find(iresp_err)-1; %cisla podnetu s chybnou odpovedi
for j = istim_err
    EEG.event(j).type = EEG.event(j).type + 900; %zmenim type aby vyrazeno z eeganalyzy, ale zachovam puvodni cislo
end
disp([ 'chybnych odpovedi: ' num2str(numel(istim_err)) ', oznaceny 9xx']); 

%ulozim EEG do ALLEEG
[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);