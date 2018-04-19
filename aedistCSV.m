function [ obrazkyRT_2D,obrazkyRT_3D,obrazkyIC_2D,obrazkyIC_3D,Errors,Poradi ] = aedistCSV( filenames,datafolder )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
close all;
if ~exist('datafolder','var'), datafolder = [pwd '\']; end %muzu mit soubory bez cesty a uvest ji v novem parametru
csvfilelast = ''; %na zacatku je prazdne
%19.4.2018 -  pouziti ruznych konfiguracnich souboru pro ruzne lidi - lepsi kdyz jsou serazene podle csv file, pak se kazdy csv nacita jen jednou
for f = 1:size(filenames,1)
    csvfile = filenames{f,2};    
    if strcmp(csvfile,csvfilelast)==0 %pokud jiny csv file nez v predchozim radku
        
        if f>1, fprintf('\n'); end %ukoncim radku
        assert(exist(csvfile,'file')==2, 'pozadovany csv file nenalezen');
        Poradi = import2D3Dporadi(csvfile); %soubor se vzorovym poradim podminek %'AEDist2D3D poradi.csv'
        fprintf('%s:',csvfile);
        csvfilelast = csvfile;
        
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
        [blokyallozac,iAllo] = zacatkyBloku(Poradi);

        %zakladam tabulku, obrazky jako nazvy sloupcu
        obrazky = Poradi.obrazek(iAllo);
        for o = 1:numel(obrazky)
            obrazky{o} = basename(obrazky{o}); %potrebuju odstranit pripony souboru .png
        end
    end
    if f == 1 %pokud se jedna o prvni cyklus 
        obrazkyRT_2D = array2table(nan(size(filenames,1),numel(obrazky)));
        obrazkyRT_2D.Properties.VariableNames = obrazky;
        obrazkyRT_3D = obrazkyRT_2D; %dve stejne prazdne tabulky na zacatku
        obrazkyIC_2D = obrazkyRT_2D; %is correct - uspesnost u obrazku 2D
        obrazkyIC_3D = obrazkyRT_2D; %is correct - uspesnost u obrazku 3D
        RowNames = cell(size(filenames,1),1);
        Errors = cell2table(cell(0,7), 'VariableNames', {'Subject','Condition', 'Dimension','Obrazek','Response','Missed','IsCorrect'}); %prazdna tabulka
    end

    filename = filenames{f,1};    
    Sdata = importCSVfile([datafolder filename]);
    fprintf(' %s\n',filenames{f,1});
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
                            obrazkyIC_2D.(names{n})(f)= ic(n);  
                        else
                            obrazkyRT_3D.(names{n})(f)= rt(n);  
                            obrazkyIC_3D.(names{n})(f)= ic(n);  
                        end
                             
                    else
                        disp(['nezname jmeno obrazku ' names{n}]);
                    end
                end
            end
            %jeste ulozim zaznamy o chybach
            SdataExt = Sdata(Podle{p} & d2D3D{d},:); %vyber tabulky Sdata
            PoradiExt = Poradi(Podle{p} & d2D3D{d},:); %vyber tabulky s conditions
            chyby = find(SdataExt.IsCorrect==0);                
            for ir = chyby' %cyklus pro kazdou chybu
                %ir = chyby(row);
                ERR = {fname,PoradiExt.podle(ir),PoradiExt.d2D3D(ir),SdataExt.Name(ir),SdataExt.Response(ir),SdataExt.Missed(ir),SdataExt.IsCorrect(ir)};
                Errors = [Errors ; ERR]; %#ok<AGROW>
            end
        end        
    end
    
    if filenames{f,3} > 0 %pokud se ma zobrazi obrazek
        prumery = mean(DataBloky,3);
        stderr = sem(DataBloky,3);
        fh = figure('name',[ basename(filename) 'prumery']);
        set(fh, 'Visible', 'off');
        bar(prumery);
        hold on;
        errorbar(prumery,stderr);
        legend({'2D','3D'},'Location','northwest');  
        title(strrep(basename(filename),'_','\_'));
        xticklabels({'cervena','vy','znacka'})
        saveas(gcf,[ datafolder basename(filename) '.png'])
        close(fh);
    end
end
fprintf('\n'); %dalsi radka
%obrazek Allo - jednotlivci
% figure('name','allo times')
% subplot(1,2,1)
% plot(obrazkyRT_2D{:,:}');
% title('2D');
% subplot(1,2,2)
% plot(obrazkyRT_3D{:,:}');
% title('3D');

M2 = nanmean(obrazkyRT_2D{:,:},1); %prumer sloupcu - pres subjekty
M2err = sem(obrazkyRT_2D{:,:},1);
%[M2,M2i]=sort(M2,'descend');
%obrazkyRT_2D = obrazkyRT_2D(:,M2i); %seradim sloupce v tabulce podle prumeru pres subjekty

M3 = nanmean(obrazkyRT_3D{:,:},1); %prumer sloupcu - pres subjekty
M3err = sem(obrazkyRT_3D{:,:},1); %prumer sloupcu - pres subjekty
%[M3,M3i]=sort(M3,'descend');
%obrazkyRT_3D = obrazkyRT_3D(:,M3i); %seradim sloupce v tabulce podle prumeru pres subjekty

IC_2D = nanmean(obrazkyIC_2D{:,:},1); %prumer sloupcu - pres subjekty
ICerr_2D = sem(obrazkyIC_2D{:,:},1);
IC_3D = nanmean(obrazkyIC_3D{:,:},1); %prumer sloupcu - pres subjekty
ICerr_3D = sem(obrazkyIC_3D{:,:},1);
% IC = nanmean(cat(1,IC_2D,IC_3D),1); %prumer pro 2D i 3D obrazky
% ICerr = nanmean(cat(1,ICerr_2D,ICerr_3D),1);

%obrazek prumeru Allo
figure('name','allo times means')
plot(M2,'color',[0 0 1]); %modra = 2D
hold on;
errorbar(M2,M2err,'color',[0 0 1]);
plot(M3,'color',[1 0 0]); %cervena = 3D
errorbar(M3,M3err,'color',[1 0 0]);
legend('2D','2D','3D','3D');
ylimit = 100; %max(M2);
for o = 1:numel(obrazky) % nazvy vsech obrazku
    if M2(o)>ylimit || M3(o)>ylimit
        th = text(o,300,obrazky{o});
        th.Rotation = 90;
    end
end
for col = 1:size(M2,2) %pro kazdy obrazek
    line( [col col],[0 3000],'LineStyle',':','Color',[0.1 0.1 0.1]); %tenoucka cara pro lepsi lokalizaci obrazku
end
for b = 1:numel(blokyallozac) %svisle cary oznacujici zacatku bloku
    line( [blokyallozac(b) blokyallozac(b)],[0 3000],'Color',[0.5 0.5 0.5]);
end

yyaxis right;
plot(IC_2D,'-','color',[0 0 0.5]); %uspesnost prumerna - cara
ylim([-1 1.2]);
errorbar(IC_2D,ICerr_2D,'o','color',[0 0 0.5]); %modra = 2D - krouzky
plot(IC_3D,'-','color',[0.5 0 0]); %uspesnost prumerna
errorbar(IC_3D,ICerr_3D,'o','color',[0.5 0 0]); %modra = 2D

%doplnim jmena radku
obrazkyRT_2D.Properties.RowNames = RowNames;
obrazkyRT_3D.Properties.RowNames = RowNames;
obrazkyIC_2D.Properties.RowNames = RowNames;
obrazkyIC_3D.Properties.RowNames = RowNames;

%zapisu vystupni tabulky do excelu
writetable(obrazkyRT_2D,[datafolder 'obrazkyRT_2D.xls'],'WriteRowNames',true);
writetable(obrazkyRT_3D,[datafolder 'obrazkyRT_3D.xls'],'WriteRowNames',true);
writetable(obrazkyIC_2D,[datafolder 'obrazkyIC_2D.xls'],'WriteRowNames',true);
writetable(obrazkyIC_3D,[datafolder 'obrazkyIC_3D.xls'],'WriteRowNames',true);
writetable(Errors,[datafolder 'Errors.xls'],'WriteRowNames',true);
end

function y = sem(x,dim)
if ~exist('dim','var'), dim = 2; end
y = nanstd(x,0,dim) / sqrt(size(x,dim));
end
function n= basename(filename)
    [~,n,~] = fileparts(filename);
end

function [blokyallozac,iAllo] = zacatkyBloku(Poradi)
    iAllo = contains(Poradi.podle(:),'znacka'); %indexy radku z Allo
    blokyzacatky = iAllo == 1 & [0 ; diff(iAllo)]==1; %kde zacinaji allo bloky
    jAllo = double(iAllo); %potrebuju zjistit bloky zacatku allo, jen v ramci allo 
    jAllo(blokyzacatky)=2; %zacatky bloku allo si takhle oznacim
    jAllo(jAllo==0) = []; %zbylo mi jen allo 
    blokyallozac = find(jAllo==2); %tohle jsou relativni indexy zacatku bloku allo 
end


