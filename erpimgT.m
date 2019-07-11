function [pmin]  = erpimgT( erpdata,erptimes,STUDY,conditions,channel,EMFTODO )
%ERPIMGT udelat graf jednoho kanalu a spocita statistiku
%   Detailed explanation goes here
fprintf('ERP ...');  
signif = '';

%prehazim podminky do jedne matrix a udelam statistiku
erpall = zeros(size(erpdata{1},1),size(erpdata{1},2),numel(erpdata));  % time x subjects x condidions, tam ulozim data pro vsechny podminky
for cond = 1:numel(erpdata) %conditions
    erpall(:,:,cond) = squeeze(erpdata{cond}); %data teto condition        
end
pp = anovafdr(erpall); %anova s fdr korekci
if(min(pp)<0.05), signif = '+'; end
isignif = pp<0.05;
pmin = min(pp); %minimalni hodnota p, bylo tam neco signifikantniho?

%vykreslim obrazek s carou statistiky
fh = figure('Name','ERP graf','units','normalized','outerposition',[0 0 1 1]); %maximalizovany obrazek na cely monitor
hue = 0.8;
colorskat = {[0 0 0],[1 0 0],[0 1 0],[0 0 1]; [hue hue hue],[1 hue hue],[hue 1 hue],[hue hue 1]}; % prvni radka - prumery, druha radka errorbars = svetlejsi
colorMap = containers.Map({'control','ego','allo','2D','3D'},[4 3 2 3 2]); %prirazeni barev k podminkam

yyaxis left
plotsh = zeros(1,size(erpall,3)); %handle na ploty, jen ty chci do legendy
for cond = 1:size(erpall,3) %cyklus pro jednotlive podminky - conditions
    icolor = colorMap(conditions{cond}); %index barvy v colorkat, podle condition
    colorkatk = [colorskat{1,icolor} ; colorskat{2,icolor}]; %dve barvy, na caru a stderr plochu kolem   
    M = mean(erpall(:,:,cond),2); %prumer pres subjekty 
    E = std(erpall(:,:,cond),[],2)/sqrt(size(erpall,2)); %std err of mean / std(subjects)/pocet(subjects)
    %plot(ersptimes,M);   
    if ~EMFTODO
        plotband(erptimes, M, E,colorkatk(2,:)); %nejlepsi, je pruhledny, ale nejde kopirovat do corelu - lepsi pro jpg obrazky       
    else
        ciplot(M+E, M-E, erptimes, colorkatk(2,:)); %funguje dobre pri kopii do corelu, ulozim handle na barevny pas
    end
    hold on;
    plotsh(cond) = plot(erptimes,M,'-','LineWidth',2,'Color',colorkatk(1,:));  %prumerna odpoved,  ulozim si handle na krivku      
end    
yyaxis right
plot(erptimes,pp,'-'); %cara signifikance
hold on;
plot(erptimes(isignif),pp(isignif),'*r','MarkerSize',2); % zvyraznena signif
ylim([0 1])
yticks(0:0.1:1)
    


legend(plotsh,conditions,'Location','best'); %nazvy podminek - jen pro posledni graf. Chtel jsem dat do prazneho subplotu, ale diky plotsh to asi nejde
fprintf(' printing figure ... ');
if ~EMFTODO
    filename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' 'ERPstat' '_' cell2str(conditions,1) '_' channel signif];
    print(fh,filename,'-djpeg');
else
    filename = [STUDY.filepath '\\figures_export_emf\\' STUDY.name '_' 'ERPstat' '_' cell2str(conditions,1) '_' channel signif];
    print(fh,filename,'-dmeta');
end
close(fh); %zavre aktualni obrazek
fprintf(' OK\n');

end

