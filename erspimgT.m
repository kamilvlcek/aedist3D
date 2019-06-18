function erspimgT(erspdata,ersptimes,erspfreqs,STUDY,condition,channel)

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
    
    for c = 1:numel(erspdata) %conditions
        meanf(:,:,c) = squeeze(erspdata{c}(ifreqs(f),:,1,:)); %data teto condition        
    end
    %chyba - potrebuju delit vsema condition najednou ale pak nemuzu pouzit erspdata{c}
    erspdataNorm(f,:,:,:) = meanf(:,:,:); % ./ mean2(meanf); %delim prumerem 
end        
erspmean = squeeze(mean(erspdataNorm,1)); %time x subjects x conditions - prumery pro pasmo   
            
fh = figure('Name','Pasmo alfa');
set(fh, 'Position',  [1 1 1000 800]); % velikost obrazku je z nejakeho duvodu relativni vzhledem k monitoru
hue = 0.8;
colorskat = {[0 0 0],[0 1 0],[1 0 0],[0 0 1]; [hue hue hue],[hue 1 hue],[1 hue hue],[hue hue 1]}; % prvni radka - prumery, druha radka errorbars = svetlejsi

subplot(3,2,[2, 4, 6]);
for c = 1:size(erspmean,3)
    colorkatk = [colorskat{1,c+1} ; colorskat{2,c+1}]; %dve barvy, na caru a stderr plochu kolem
    M = mean(erspmean(:,:,c),2); %prumer pres subjekty 
    E = std(erspmean(:,:,c),[],2)/sqrt(size(erspmean,2)); %std err of mean / std(subjects)/pocet(subjects)
    %plot(ersptimes,M);    
    plotband(ersptimes, M, E,colorkatk(2,:)); %nejlepsi, je pruhledny, ale nejde kopirovat do corelu
    %ciplot(M+E, M-E, T, colorkatk(2,:)); %funguje dobre pri kopii do corelu, ulozim handle na barevny pas
    hold on;
    plot(ersptimes,M,'LineWidth',2,'Color',colorkatk(1,:));  %prumerna odpoved,  ulozim si handle na krivku  
end

for c = 1:size(erspmean,3)
    subplot(3,2,(c-1)*2+1);
    D = mean(erspdata{c},4);%mean over subjects
    imagesc(ersptimes,erspfreqs,D); %vykresluju jen alfa
    %set(gca, 'YTick',erspfreqs(1):10:erspfreqs(end), 'YTickLabel', round(erspfreqs(1:10:end))) % 20 ticks
    %axis ij;
    set(gca,'YDir','normal')
    ylabel('freq');
    xlabel('time [ms]');
    colorbar;
end 
filename = [STUDY.filepath '\\figures_export\\' STUDY.name '_' 'Alfa' '_' cell2str(condition,1) '_' channel];
print(fh,filename,'-djpeg');
print(fh,filename,'-dmeta');
close(fh); %zavre aktualni obrazek
        