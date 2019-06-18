function erspimgT(erspdata,ersptimes,erspfreqs,STUDY,conditions,channel)

%potrebuje erspdata a ersptimes a erspfreqs
%erspdata - 3x1 cell, matrix 83x106x1x21  freq x time x ch x subjects
%pasma = {'alfa',[8 12]; 'beta' [12 30]};
freqs = [8 13]; %alfa        
ifreqs = find( (erspfreqs >= freqs(1)) & (erspfreqs <= freqs(2)) );  
erspdataNorm = zeros(numel(ifreqs),size(erspdata{1},2),size(erspdata{1},4),numel(erspdata)); %normalizova kopie erspdata
    %freq x time x subjects x conditions
    %do jedne matrix, conditions maji vsechny stejne rozmery
for f = 1:numel(ifreqs)            
    meanf = zeros(size(erspdata{1},2),size(erspdata{1},4),numel(erspdata));  % time x subjects x condidions, tam ulozim data pro tuto frekvenci
    
    for cond = 1:numel(erspdata) %conditions
        meanf(:,:,cond) = squeeze(erspdata{cond}(ifreqs(f),:,1,:)); %data teto condition        
    end
    %chyba - potrebuju delit vsema condition najednou ale pak nemuzu pouzit erspdata{c}
    erspdataNorm(f,:,:,:) = meanf(:,:,:); % ./ mean2(meanf); %delim prumerem 
end        
erspmean = squeeze(mean(erspdataNorm,1)); %time x subjects x conditions - prumery pro pasmo   
pp = anovafdr(erspmean); %anova s fdr korekci

fh = figure('Name','Pasmo alfa');
set(fh, 'Position',  [1 1 1000 800]); % velikost obrazku je z nejakeho duvodu relativni vzhledem k monitoru
hue = 0.8;
colorskat = {[0 0 0],[0 1 0],[1 0 0],[0 0 1]; [hue hue hue],[hue 1 hue],[1 hue hue],[hue hue 1]}; % prvni radka - prumery, druha radka errorbars = svetlejsi

subplot(3,2,[2, 4, 6]); %vpravo obrazek pro vsechny podminky - prumery za pasma
yyaxis left
plotsh = zeros(1,size(erspmean,3)); %handle na ploty, jen ty chci do legendy
for cond = 1:size(erspmean,3) %cyklus pro jednotlive podminky - conditions
    colorkatk = [colorskat{1,cond+1} ; colorskat{2,cond+1}]; %dve barvy, na caru a stderr plochu kolem
    M = mean(erspmean(:,:,cond),2); %prumer pres subjekty 
    E = std(erspmean(:,:,cond),[],2)/sqrt(size(erspmean,2)); %std err of mean / std(subjects)/pocet(subjects)
    %plot(ersptimes,M);    
    plotband(ersptimes, M, E,colorkatk(2,:)); %nejlepsi, je pruhledny, ale nejde kopirovat do corelu
    %ciplot(M+E, M-E, T, colorkatk(2,:)); %funguje dobre pri kopii do corelu, ulozim handle na barevny pas
    hold on;
    plotsh(cond) = plot(ersptimes,M,'-','LineWidth',2,'Color',colorkatk(1,:));  %prumerna odpoved,  ulozim si handle na krivku      
end
legend(plotsh,conditions); %nazvy podminek
yyaxis right
plot(ersptimes,pp,'-');
ylim([0 1])

for cond = 1:size(erspmean,3)
    subplot(3,2,(cond-1)*2+1); %vlevo tri obrazky - cas x frekvence - pro kontrolu
    D = mean(erspdata{cond},4);%mean over subjects
    imagesc(ersptimes,erspfreqs,D); %vykresluju jen alfa
    %porad mi nefunguje popis osy Y aby sedel
    %set(gca, 'YTick',erspfreqs(1):10:erspfreqs(end), 'YTickLabel', round(erspfreqs(1:10:end))) % 20 ticks
    %axis ij;
    set(gca,'YDir','normal') 
    ylabel('freq');
    xlabel('time [ms]');
    title(conditions{cond});
    colorbar;
end 
filename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' 'Alfa' '_' cell2str(conditions,1) '_' channel];
print(fh,filename,'-djpeg');
filename = [STUDY.filepath '\\figures_export_emf\\' STUDY.name '_' 'Alfa' '_' cell2str(conditions,1) '_' channel];
print(fh,filename,'-dmeta');
close(fh); %zavre aktualni obrazek

end %function 

function pp = anovafdr(erspmean)
    %anova pres podminky pro kazdy bod v case s fdr korekci
    pp = zeros(size(erspmean,1),1); %p hodnoty z anovy
    for t = 1:size(erspmean,1)
        pp(t) = anova1(squeeze(erspmean(t,:,:)),[],'off'); %anova pro kazdy bod v case
    end
    [~, ~, adj_p]=fdr_bh(pp,0.05,'pdep','no'); %dep je striktnejsi nez pdep
    %[h, crit_p, adj_p]=fdr_bh(pvals,q,method,report);
    pp = adj_p; %prepisu puvodni hodnoty korigovanymi podle FDR
end
        