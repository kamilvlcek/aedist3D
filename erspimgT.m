function erspimgT(erspdata,ersptimes,erspfreqs,STUDY,conditions,channel)

%potrebuje erspdata a ersptimes a erspfreqs
%erspdata - 3x1 cell, matrix 83x106x1x21  freq x time x ch x subjects

freqs = {'alfa',[8 13],2; 'beta', [14 30],3; 'theta', [4 7.5],5; 'lowgamma', [31 50],8;'highgamma',[51 100],9}; % nazvy a pasma frekvenci, + cislo subplotu        
fh = figure('Name','Pasma grafy');
set(fh, 'Position',  [1 1 1200 600]); % velikost obrazku je z nejakeho duvodu relativni vzhledem k monitoru
hue = 0.8;
colorskat = {[0 0 0],[0 1 0],[1 0 0],[0 0 1]; [hue hue hue],[hue 1 hue],[1 hue hue],[hue hue 1]}; % prvni radka - prumery, druha radka errorbars = svetlejsi
fprintf('Pasma ');  
signif = '';

for ff = 1:size(freqs,1)
    fprintf('%s ... ',freqs{ff,1});
    freqband = freqs{ff,2};   
    ifreqs = find( (erspfreqs >= freqband(1)) & (erspfreqs <= freqband(2)) );  
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
    if(min(pp)<0.05), signif = '+'; end
    isignif = pp<0.05;
    
    subplot(3,3,freqs{ff,3}); %vpravo obrazek pro vsechny podminky - prumery za pasma
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
    plot(ersptimes,pp,'-'); %cara signifikance
    hold on;
    plot(ersptimes(isignif),pp(isignif),'*r','MarkerSize',2); % zvyraznena signif
    ylim([0 1])
    yticks(0:0.1:1)
    title(freqs{ff,1}); % nazev frekvencniho pasma
end

for cond = 1:size(erspmean,3)
    subplot(3,3,(cond-1)*3+1); %vlevo tri obrazky - cas x frekvence - pro kontrolu
    D = mean(erspdata{cond},4);%mean over subjects
    imagesc(ersptimes,erspfreqs,D); %vykresluju jen alfa
     
    frex = [4 8 14 31 51]; %frekvence ktere chci na y ose zobrazit
    ifrex = zeros(1,numel(frex)); 
    for f = 1:numel(frex)
        ifrex(f) = find(erspfreqs>=frex(f),1); 
    end
    l = linspace(round(min(erspfreqs)),round(max(erspfreqs)),numel(erspfreqs)); %takhle imagesc zobrazuje frekvence defaultne, jako by linearni skala mezi min a max
    set(gca, 'YTick',l(ifrex), 'YTickLabel', frex) % na te linearni skale linspace zobrazim odpovidajici nelinearni hodnoty
    set(gca,'YDir','normal') %otocim osu y
    ylabel('freq');
    xlabel('time [ms]');
    title(conditions{cond});
    colorbar;
end 
fprintf(' printing figures ... ');
filename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' 'Pasma' '_' cell2str(conditions,1) '_' channel signif];
print(fh,filename,'-djpeg');
filename = [STUDY.filepath '\\figures_export_emf\\' STUDY.name '_' 'Pasma' '_' cell2str(conditions,1) '_' channel signif];
print(fh,filename,'-dmeta');
close(fh); %zavre aktualni obrazek
fprintf(' OK\n');
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
        