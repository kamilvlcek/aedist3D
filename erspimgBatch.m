%pokud nebezi eeglab, nastartuju ho
if ~exist('EEG','var') || isempty(EEG)
    clear
    eeglab
end

%ERP jpg
ERPTODO = 1; 
EMFTODO = 0;
erspimg;

%ERPS jpg
ERPTODO = 0; 
EMFTODO = 0;
erspimg;

return;

%ERPS emf
ERPTODO = 0; 
EMFTODO = 1;
erspimg;

%ERP emf
ERPTODO = 1; 
EMFTODO = 1;
erspimg;

