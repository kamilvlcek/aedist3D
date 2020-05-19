function [pmin] = erspimgT(erspdata,ersptimes,erspfreqs,STUDY,conditions,channel,EMFTODO,freqs)
%ERSPIMGT makes figure of one channel and computes statistics, for each frequency band separately
%   called from erspimg script, which prepares all argumenents
%   requires erspdata a ersptimes a erspfreqs
%   erspdata - 3x1 cell for three conditions, each one is matrix 83x106x1x21  freq x time x ch x subjects
%   erspfreqs - list of frequecies e.g. 83
%   returns minimal corrected p values (over time) for all bands

%freqs = {'alfa',[8 13],2; 'beta', [14 30],3; 'theta', [4 7.5],5; 'lowgamma', [31 50],8;'highgamma',[51 100],9}; % nazvy a pasma frekvenci, + cislo subplotu        

%figure to be saved 
fh = figure('Name','Pasma grafy','units','normalized','outerposition',[0 0 1 1]); %maximalizzed figure for whole monitor
%set(fh, 'Position',  [1 1 1200 600]); % velikost obrazku je z nejakeho duvodu relativni vzhledem k monitoru
hue = 0.8;
colorskat = {[0 0 0],[1 0 0],[0 1 0],[0 0 1]; [hue hue hue],[1 hue hue],[hue 1 hue],[hue hue 1]}; % prvni radka - prumery, druha radka errorbars = svetlejsi
colorMap = containers.Map({'control','ego','allo','2D','3D'},[4 3 2 3 2]); %prirazeni barev k podminkam
fprintf('Bands ');  
signif = '';
pmin = ones(1,size(freqs,1)); %tam budu davat minimalni hodnoty p

for ff = 1:size(freqs,1)
    fprintf('%s ... ',freqs{ff,1});
    
    %COMPUTE MEANS AND STATS
    freqband = freqs{ff,2};   %range of frequencies
    ifreqs = find( (erspfreqs >= freqband(1)) & (erspfreqs <= freqband(2)) );  %find the frequencies in ERSP data
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
    erspmean = squeeze(mean(erspdataNorm,1)); %time x subjects x conditions - averages for the all frequencies in the band   
    pp = anovafdr(erspmean); %anova s fdr korekci
    if(min(pp)<0.05), signif = '+'; end
    isignif = pp<0.05;
    pmin(ff) = min(pp);
    
    %PLOT MEANS AND STATS
    subplot(3,3,freqs{ff,3}); %vpravo obrazek pro vsechny podminky - prumery za pasma
    yyaxis left
    plotsh = zeros(1,size(erspmean,3)); %plots handles, only these fo the legend 
    for cond = 1:size(erspmean,3) %cyklus pro jednotlive podminky - conditions
        icolor = colorMap(conditions{cond}); %index barvy v colorkat, podle condition
        colorkatk = [colorskat{1,icolor} ; colorskat{2,icolor}]; %dve barvy, na caru a stderr plochu kolem
        M = mean(erspmean(:,:,cond),2); %prumer pres subjekty 
        E = std(erspmean(:,:,cond),[],2)/sqrt(size(erspmean,2)); %std err of mean / std(subjects)/pocet(subjects)
        %plot(ersptimes,M);   
        %error bands
        if ~EMFTODO
            plotband(ersptimes, M, E,colorkatk(2,:)); %nejlepsi, je pruhledny, ale nejde kopirovat do corelu - lepsi pro jpg obrazky       
        else
            ciplot(M+E, M-E, ersptimes, colorkatk(2,:)); %funguje dobre pri kopii do corelu, ulozim handle na barevny pas
        end
        hold on;
        %mean values
        plotsh(cond) = plot(ersptimes,M,'-','LineWidth',2,'Color',colorkatk(1,:));  %prumerna odpoved,  ulozim si handle na krivku      
    end    
    yyaxis right
    plot(ersptimes,pp,'-'); %line of significance
    hold on;
    plot(ersptimes(isignif),pp(isignif),'*r','MarkerSize',2); % significance <0.05 marked byt red stars 
    ylim([0 1])
    yticks(0:0.1:1)
    title(freqs{ff,1}); % nazev frekvencniho pasma
end
legend(plotsh,conditions,'Location','best'); %nazvy podminek - jen pro posledni graf. Chtel jsem dat do prazneho subplotu, ale diky plotsh to asi nejde

%PLOT all frequencies int the band as imagesc: time x freq
for cond = 1:size(erspmean,3)
    subplot(3,3,(cond-1)*3+1); %left of means - cas x frekvence - pro kontrolu
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
%save the figures and close them
fprintf(' printing figures ... ');
if ~EMFTODO
    filename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' 'Pasma' '_' cell2str(conditions,1) '_' channel signif];
    print(fh,filename,'-djpeg');
else
    filename = [STUDY.filepath '\\figures_export_emf\\' STUDY.name '_' 'Pasma' '_' cell2str(conditions,1) '_' channel signif];
    print(fh,filename,'-dmeta');
end
close(fh); %zavre aktualni obrazek
fprintf(' OK\n');
end %function 


        