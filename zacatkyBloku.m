function [blokyallozac,iAllo,i3D] = zacatkyBloku(Poradi,podle)
    %called from aedistCSV and prekryv
    
    if ~exist('podle','var'), podle = 'znacka'; end
    iAllo = contains(Poradi.podle(:),podle); %indexy radku z Allo
    i3D = Poradi.d2D3D(:) == 3; %indexy radku z Allo
    blokyzacatky = iAllo == 1 & [0 ; diff(iAllo)]==1; %kde zacinaji allo bloky
    jAllo = double(iAllo); %potrebuju zjistit bloky zacatku allo, jen v ramci allo 
    jAllo(blokyzacatky)=2; %zacatky bloku allo si takhle oznacim
    jAllo(jAllo==0) = []; %zbylo mi jen allo 
    blokyallozac = find(jAllo==2); %tohle jsou relativni indexy zacatku bloku allo 
end