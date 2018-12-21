function [ spolecne,Unikatni ] = prekryv( csvfile )
%PREKRYV Summary of this function goes here
%   Detailed explanation goes here

Poradi = import2D3Dporadi(csvfile);
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

spolecne = intersect(intersect(cAllo,cEgo),cCon); %seznam jmen obrazku, ktere jsou spolecne pro vsech sest podminek

[~,iPoradi,] = unique(Poradi.obrazek);
Unikatni = Poradi(iPoradi,:); 

end

