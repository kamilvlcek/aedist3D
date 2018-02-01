function [ obrazkyRT_2D,obrazkyRT_3D,Poradi ] = aedistCSV( filenames )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
close all;

Poradi = import2D3Dporadi('AEDist2D3D poradi.csv'); %soubor se vzorovym poradim podminek
iTrening = Poradi.zpetnavazba == 1; %indexy treningovych pokusu
Poradi(iTrening,:) = []; % i tady potrebuju smazat treningove pokusy
%bloky podle otazky
Podle = cell(3,1);
Podle{1} = contains(Poradi.podle,'cervena');
Podle{2} = contains(Poradi.podle,'vy');
Podle{3} = contains(Poradi.podle,'znacka');

d2D3D = cell(2,1);
%bloky podle 2D3D pohledu
d2D3D{1} = Poradi.d2D3D == 2;
d2D3D{2} = Poradi.d2D3D == 3; 

%bloky Allo podminek
iAllo = contains(Poradi.podle(:),'znacka'); %indexy radku z Allo
blokyzacatky = iAllo == 1 & [0 ; diff(iAllo)]==1; %kde zacinaji allo bloky
jAllo = double(iAllo); %potrebuju zjistit bloky zacatku allo, jen v ramci allo 
jAllo(blokyzacatky)=2; %zacatky bloku allo si takhle oznacim
jAllo(jAllo==0) = []; %zbylo mi jen allo 
blokyallozac = find(jAllo==2); %tohle jsou relativni indexy zacatku bloku allo 

%zakladam tabulku, obrazky jako nazvy sloupcu
obrazky = Poradi.obrazek(iAllo);
for o = 1:numel(obrazky)
    obrazky{o} = basename(obrazky{o}); %potrebuju odstranit pripony souboru .png
end
obrazkyRT_2D = array2table(zeros(numel(filenames),numel(obrazky)));
obrazkyRT_2D.Properties.VariableNames = obrazky;
obrazkyRT_3D = obrazkyRT_2D; %dve stejne prazdne tabulky na zacatku
obrazkyIC = obrazkyRT_2D; %is correct - uspesnost u obrazku
RowNames = cell(numel(filenames),1);

for f = 1:numel(filenames)
    filename = filenames{f};
    Sdata = importCSVfile(filename);
    [~,fname,~] = fileparts(filename);
    RowNames{f} = fname;
    Sdata(iTrening,:) = []; %smazu data z treningu    
    DataBloky = zeros(length(Podle),length(d2D3D),ceil(height(Sdata)/6)); % to musi byt 64 jinak nekde chyba
    for p= 1:size(DataBloky,1) %cyklus podminky - Allo, Ego, Cervena
        for d= 1:size(DataBloky,2) %cyklus 2D vs 3D
            DataBloky(p,d,:) = Sdata.RTms(Podle{p} & d2D3D{d});
            %DataBloky(p,d,:) = Sdata.IsCorrect(Podle{p} & d2D3D{d});
            if p==3 %allo blok
                names = Sdata.Name(Podle{p} & d2D3D{d}); %jmena obrazku
                rt =  Sdata.RTms(Podle{p} & d2D3D{d}); %reakcni casy
                ic =  Sdata.IsCorrect(Podle{p} & d2D3D{d}); %uspesnost
                for n = 1:numel(names)
                    if any(strcmp(names{n},fieldnames(obrazkyRT_2D))) %existuje tohle jmeno obrazku v tabulce?
                        if d == 1
                            obrazkyRT_2D.(names{n})(f)= rt(n);                                      
                        else
                            obrazkyRT_3D.(names{n})(f)= rt(n);      
                        end
                        obrazkyIC.(names{n})(f)= ic(n);       
                    else
                        disp(['nezname jmeno obrazku ' names{n}]);
                    end
                end
            end
        end        
    end
    prumery = mean(DataBloky,3);
    stderr = sem(DataBloky,3);
    figure('name',[ basename(filename) 'prumery']);
    bar(prumery);
    hold on;
    errorbar(prumery,stderr);
    legend({'2D','3D'});      
end

%obrazek Allo - jednotlivci
figure('name','allo times')
subplot(1,2,1)
plot(obrazkyRT_2D{:,:}');
title('2D');
subplot(1,2,2)
plot(obrazkyRT_3D{:,:}');
title('3D');

M2 = mean(obrazkyRT_2D{:,:}); %prumer sloupcu - pres subjekty
M2err = sem(obrazkyRT_2D{:,:},1);
%[M2,M2i]=sort(M2,'descend');
%obrazkyRT_2D = obrazkyRT_2D(:,M2i); %seradim sloupce v tabulce podle prumeru pres subjekty

M3 = mean(obrazkyRT_3D{:,:}); %prumer sloupcu - pres subjekty
M3err = sem(obrazkyRT_3D{:,:},1); %prumer sloupcu - pres subjekty
%[M3,M3i]=sort(M3,'descend');
%obrazkyRT_3D = obrazkyRT_3D(:,M3i); %seradim sloupce v tabulce podle prumeru pres subjekty

IC = mean(obrazkyIC{:,:}); %prumer sloupcu - pres subjekty
ICerr = sem(obrazkyIC{:,:},1);

%obrazek prumeru Allo
figure('name','allo times means')
plot(M2,'b');
hold on;
errorbar(M2,M2err);
plot(M3,'r');
errorbar(M3,M3err);
legend('2D','2D','3D','3D');
ylimit = 100; %max(M2);
for o = 1:numel(obrazky) % nazvy vsech obrazku
    if M2(o)>ylimit || M3(o)>ylimit
        th = text(o,300,obrazky{o});
        th.Rotation = 90;
    end
end
for b = 1:numel(blokyallozac) %svisle cary oznacujici zacatku bloku
    line( [blokyallozac(b) blokyallozac(b)],[0 3000],'Color',[0.5 0.5 0.5]);
end

yyaxis right;
plot(IC,'g'); %uspesnost prumerna
errorbar(IC,ICerr,'color',[0.5 0.5 0.5]);
ylim([-1 1.2]);
%doplnim jmena radku
obrazkyRT_2D.Properties.RowNames = RowNames;
obrazkyRT_3D.Properties.RowNames = RowNames;

end

function y = sem(x,dim)
if ~exist('dim','var'), dim = 2; end

y = std(x,0,dim) / sqrt(size(x,dim));
end
function n= basename(filename)
    [~,n,~] = fileparts(filename);
end

