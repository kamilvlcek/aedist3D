classdef Arena < handle
    %ARENA trida na zobrazeni pozic objektu v AEDist testu
    %   jen 2D pozice pri pohledu shora
    %   Kamil Vlcek 26.10.2017
    
    properties
        pozice;
        sloupce;
        radky;
        figureh;
        Stred = 0+0i; %stred areny
        r = 0.5; %rozmer areny
        Tyc = 0.017 + 0.483i;
        rtyc = 0.069/2;
        rkoule = 0.083/2;
        rkamera = 0.05;
        lkamera = 0.3; %delka cary kamery
    end
    
    methods
        function obj = Arena(filename)
            obj.Load(filename);
        end
        function obj = Load(obj,filename)
            %nacte soubor s promennymi POZICE, SLOUPCE a RADKY
            load(filename);
            obj.pozice = POZICE;
            obj.sloupce = SLOUPCE;
            obj.radky = RADKY;

        end
        function obj = Plot(obj,r,lrflip)
            if ~exist('lrflip','var'), lrflip = 0; end %parametr obrazku - pokud na konci jmena R, znamena to lrflip = 1;
            if(isempty(obj.figureh) || ~isvalid(obj.figureh))
                obj.figureh = figure('Name','AEDist pozice');
            else
                figure(obj.figureh);
            end
            clf; %vymaze obrazek
            circle(obj.r,real(obj.Stred),imag(obj.Stred),'k'); %obrys areny
            hold on;
            axis equal;
            axis ij;
            pozice = obj.pozice(r,:); %#ok<*PROPLC>
            if lrflip 
                pozice([1 4 10]) = -pozice([1 4 10]);  %prehodim x souradnice - obrazek okolo svisle osy
                pozice(9) = 180-pozice(9); %prehodim cameraYaw 
                figname = obj.radky{r};
                figname(end) = 'R'; %nove jmeno obrazku
            else
                figname = obj.radky{r};
            end
            circle(obj.rtyc,real(obj.Tyc),imag(obj.Tyc),'y',1); %zluta tyc
            circle(obj.rkoule,pozice(1),pozice(2),'r',1); %cervena koule
            circle(obj.rkoule,pozice(4),pozice(5),'k',0); %bila koule
            circle(obj.rkamera,pozice(10),pozice(11),'m',1); %kamera
            obj.Line(pozice); %smer pohledu            
            text(-0.5,0.4,[num2str(r) ' ' figname]);
        end
        function Line(obj,pozice)           
           x(1) =  pozice(10);
           x(2) =  x(1) + obj.lkamera * cosd( pozice(9));
           y(1) =  pozice(11);
           y(2) =  y(1) + obj.lkamera * sind( pozice(9));
           plot(x,y);
        end
        function CheckAll(obj)
            pause('on');
            for r = 1:numel(obj.radky) %#ok<PROP>
                obj.Plot(r); %#ok<PROP>
                pause;
            end
            pause('off')
        end
        
    end
    
end

