function [ data ] = aedistCSV( filenames )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
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

obrazky = unique(Poradi.obrazek);
for o = 1:numel(obrazky)
    obrazky{o} = basename(obrazky{o}); %potrebuju odstranit pripony souboru .png
end
obrazkyRT_2D = array2table(zeros(numel(filenames),numel(obrazky)));
obrazkyRT_2D.Properties.VariableNames = obrazky;
obrazkyRT_3D = obrazkyRT_2D; %dve stejne prazdne tabulky na zacatku

for f = 1:numel(filenames)
    filename = filenames{f};
    Sdata = importCSVfile(filename);
    Sdata(iTrening,:) = []; %smazu data z treningu    
    DataBloky = zeros(length(Podle),length(d2D3D),ceil(height(Sdata)/6)); % to musi byt 64 jinak nekde chyba
    for p= 1:size(DataBloky,1)
        for d= 1:size(DataBloky,2)
            %DataBloky(p,d,:) = Sdata.RTms(Podle{p} & d2D3D{d});
            DataBloky(p,d,:) = Sdata.IsCorrect(Podle{p} & d2D3D{d});
            if p==3 %allo blok
                names = Sdata.Name(Podle{p} & d2D3D{d}); %jmena obrazku
                rt =  Sdata.RTms(Podle{p} & d2D3D{d}); %reakcni casy
                for n = 1:numel(names)
                    if any(strcmp(names{n},fieldnames(obrazkyRT_2D))) %existuje tohle jmeno obrazku v tabulce?
                        if d == 1
                            obrazkyRT_2D.(names{n})(f)= rt(n);                                      
                        else
                            obrazkyRT_3D.(names{n})(f)= rt(n);      
                        end
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

figure('name','allo times')
subplot(1,2,1)
plot(obrazkyRT_2D{:,:}');
subplot(1,2,2)
plot(obrazkyRT_3D{:,:}');

end

function y = sem(x,dim)
if ~exist('dim','var'), dim = 2; end

y = std(x,0,dim) / sqrt(size(x,dim));
end
function n= basename(filename)
    [~,n,~] = fileparts(filename);
end

