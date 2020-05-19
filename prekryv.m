function [ spolecne,Unikatni,spravne ] = prekryv( csvfile )
%PREKRYV function to check the conditions in the Aedist3D csv setup file
%   Detailed explanation goes here

Poradi = import2D3Dporadi(csvfile);
%Poradi(Poradi.zpetnavazba==1,:)=[]; %smazu trening

[~,iAllo,i3D] = zacatkyBloku(Poradi,'znacka');
o3D_Allo = Poradi.obrazek(iAllo & i3D);
o2D_Allo = Poradi.obrazek(iAllo & ~i3D);
cAllo = intersect(o2D_Allo,o3D_Allo);

[~,iEgo,i3D] = zacatkyBloku(Poradi,'vy');
o3D_Ego = Poradi.obrazek(iEgo & i3D);
o2D_Ego = Poradi.obrazek(iEgo & ~i3D);
cEgo = intersect(o2D_Ego,o3D_Ego);

[~,iCon,i3D] = zacatkyBloku(Poradi,'cervena');
o3D_Con = Poradi.obrazek(iCon & i3D);
o2D_Con = Poradi.obrazek(iCon & ~i3D);
cCon = intersect(o2D_Con,o3D_Con);

spolecneEgoAllo = intersect(cAllo,cEgo);
spolecne = intersect(spolecneEgoAllo,cCon); %seznam jmen obrazku, ktere jsou spolecne pro vsech sest podminek

c2D = intersect(intersect(o2D_Allo,o2D_Ego),o2D_Con);
c3D = intersect(intersect(o3D_Allo,o3D_Ego),o3D_Con);

[~,iPoradi,] = unique(Poradi.obrazek);
Unikatni = Poradi(iPoradi,:); 

%28.12.2018 jeste zkontroluju spravne odpovedi (sloupec corrAns, podle souboru corrAns.mat). 
% pro kazdou podminku allo ego control to je zvlast
load('corrAns.mat');
spravne = cell(size(corrAns,1),3); %prvni sloupec - kolik obrazku v csv Poradi souhlasi, druhy sloupec - kolik celkove obrazku v csv Poradi (2D + 3D + trening)
for l = 1:size(corrAns,1)
   odpoved = table2cell(Poradi(contains(Poradi.obrazek,corrAns(l,1)) & contains(Poradi.podle,corrAns(l,2)),4));
   spravne{l,1} = sum(contains(odpoved,corrAns(l,3)));
   spravne{l,2} = numel(contains(odpoved,corrAns(l,3)));
   spravne{l,3} = corrAns{l,1};
end

end

