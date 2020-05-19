%can call erspimg script repeatedly with different setup
%start eeglab if it is not running
if ~exist('EEG','var') || isempty(EEG)
    clear
    eeglab
end

%ERP jpg
%ERPTODO = 1; 
%EMFTODO = 0;
%erspimg;

%ERPS jpg
ERPTODO = 0; 
EMFTODO = 0;
erspimg;

return;

%ERPS emf
ERPTODO = 0; 
EMFTODO = 0;
erspimg;

%ERP emf
ERPTODO = 0; 
EMFTODO = 0;
erspimg;

