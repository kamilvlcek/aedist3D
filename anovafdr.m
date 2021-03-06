function pp = anovafdr(erspmean)
    %ANOVAFDR ANOVA test/ Ttest for differece between conditions, for all time samples with fdr correction
    %  erspmean - time x subjects x conditions - averages for frequency band 
    %  called from erpimgT and erspimgT
    pp = zeros(size(erspmean,1),1); %p hodnoty z anovy
    if size(erspmean,3) == 2      %for two conditions - paired t-test 
        for t = 1:size(erspmean,1) %pro kazdy bod v case
            data = squeeze(erspmean(t,:,:)); %data subjects x conditions
            [~,pp(t)] = ttest(data(:,1), data(:,2)); %paired t-test pro kazdy bod v case
        end
    elseif size(erspmean,3) == 3  %for three conditions      - repeated measures ANOVA
        for t = 1:size(erspmean,1) %for each timepoint
            subjects = repmat({'subject'}, size(erspmean,2),1);
            data = squeeze(erspmean(t,:,:)); %data subjects x conditions
            %dale viz navod https://nl.mathworks.com/help/stats/repeatedmeasuresmodel.ranova.html
            T = table(subjects,data(:,1),data(:,2),data(:,3), 'VariableNames',{'subjects','c1','c2','c3'}); %tabulka dat pro ranova
            C = table([1 2 3]','VariableNames',{'Conditions'});
            rm = fitrm(T,'c1-c3 ~ 1','WithinDesign',C); %~1 misto ~subjects jsem nasel na internetu, kvuli chybe, funguje to
            ranovatbl = ranova(rm); %repeated measures anova pro kazdy bod v case, vrati table
            pp(t) = table2array(ranovatbl(1,'pValue'));  %overoval jsem p vysledky se STATISTICA a sedi to
            %pp(t) = anova1(squeeze(erspmean(t,:,:)),[],'off'); %one-way anova pro kazdy bod v case
        end
    else
        error('max 3 podminky'); %its not possible to have more than three conditions now
    end
    [~, ~, adj_p]=fdr_bh(pp,0.05,'dep','no'); %dep je striktnejsi nez pdep
    %[h, crit_p, adj_p]=fdr_bh(pvals,q,method,report);
    pp = adj_p; %prepisu puvodni hodnoty korigovanymi podle FDR
end

