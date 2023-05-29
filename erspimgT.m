function [pmin] = erspimgT(erspdata,ersptimes,erspfreqs,STUDY,conditions,channel,EMFTODO,freqs, clusters)
%ERSPIMGT makes figure of one channel (or one cluster) and computes statistics, for each frequency band separately
%   called from erspimg or ERSPimg_clusters script, which prepares all argumenents
%   requires erspdata, ersptimes and erspfreqs
%   erspdata - 3x1 cell for three conditions (or two), each one is matrix freq x time x ch x subjects
%   erspfreqs - list of frequecies e.g. 83
%   returns minimal corrected p values (over time) for all bands

%%% Sofia May 2023: additional parameter - clusters, if clusters==1, computes statistics for frequency bands
%%% for each cluster of independent components instead of channel; 
%%% in that case erspdata - 3x1 cell for three conditions, each one is 3D matrix (not 4D as in case of channel): freq x time x components

if ~exist('clusters','var'), clusters = 0; end % to compute statistic for one channel over subjects

%freqs = {'alfa',[8 13],2; 'beta', [14 30],3; 'theta', [4 7.5],5; 'lowgamma', [31 50],8;'highgamma',[51 100],9}; % nazvy a pasma frekvenci, + cislo subplotu        

% figure to be saved 
fh = figure('Name','Frequency bands','units','normalized','outerposition',[0 0 1 1]); % maximalize figure for whole monitor
%set(fh, 'Position',  [1 1 1200 600]); % velikost obrazku je z nejakeho duvodu relativni vzhledem k monitoru
hue = 0.8;
colorskat = {[0 0 0],[1 0 0],[0 1 0],[0 0 1]; [hue hue hue],[1 hue hue],[hue 1 hue],[hue hue 1]}; % first row - means, second row - errorbars = brighter
colorMap = containers.Map({'control','ego','allo','2D','3D'},[4 3 2 3 2]); % matching colors to conditions

% rearrange var conditions if it is folded cell array to match with colorMap for further plotting
if iscell(conditions{1})
    conditionsOld = conditions;
    conditions = cell(1, numel(conditions));
    for icond = 1:numel(conditionsOld)
        strcells = regexp(conditionsOld{icond}{1}, '\d', 'split'); % split by number - e.g. ego2D = ego + 2D
        conditions{icond} = strcells{1};
    end
end

fprintf('Bands ');  
signif = '';
pmin = ones(1,size(freqs,1)); % here minimal p values will be stored

for ff = 1:size(freqs,1)
    fprintf('%s ... ',freqs{ff,1});
    
    % COMPUTE MEANS AND STATS
    freqband = freqs{ff,2};   %range of frequencies
    ifreqs = find( (erspfreqs >= freqband(1)) & (erspfreqs <= freqband(2)) );  % find the frequencies in ERSP data
    
    if clusters == 1
        subjectsSize = size(erspdata{1},3); % if compute over components in cluster, erspdata - 3D matrix: freq x time x components
    else
        subjectsSize = size(erspdata{1},4); % if compute over subjects for one channel, erspdata - 4D matrix: freq x time x ch x subjects (freq x time x 1 x subjects)
    end
        
    erspdataNorm = zeros(numel(ifreqs),size(erspdata{1},2),subjectsSize,numel(erspdata)); % normalizova kopie erspdata : freq x times x components(subjects) x conditions  
    %do jedne matrix, conditions maji vsechny stejne rozmery
    for f = 1:numel(ifreqs)            
        meanf = zeros(size(erspdata{1},2),subjectsSize,numel(erspdata));  % time x subjects x condidions, save data for this frequency
        for cond = 1:numel(erspdata) %conditions
            if clusters == 1
                meanf(:,:,cond) = erspdata{cond}(ifreqs(f),:,:); % data for this condition; erspdata - 3D matrix
            else
                meanf(:,:,cond) = squeeze(erspdata{cond}(ifreqs(f),:,1,:)); % erspdata - 4D matrix, squeeze dimension of channel
            end
        end
        %chyba - potrebuju delit vsema condition najednou ale pak nemuzu pouzit erspdata{c}
        erspdataNorm(f,:,:,:) = meanf(:,:,:); % ./ mean2(meanf); %delim prumerem 
    end        
    erspmean = squeeze(mean(erspdataNorm,1)); % time x subjects(components) x conditions - averages for the all frequencies in the band   
    pp = anovafdr(erspmean); % ANOVA with FDR correction
    if(min(pp)<0.05), signif = '+'; end
    isignif = pp<0.05;
    pmin(ff) = min(pp);
    
    % PLOT MEANS AND STATS
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

% PLOT all frequencies int the band as imagesc: time x freq
for cond = 1:size(erspmean,3)
    subplot(3,3,(cond-1)*3+1); %left of means - cas x frekvence - pro kontrolu
    if clusters == 1
        D = mean(erspdata{cond},3);% mean over components in one cluster
    else
        D = mean(erspdata{cond},4);% mean over subjects in one channel
    end
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

        