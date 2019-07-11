%function [m, status] = getDisplayParameters(computerName)
%
% Returns a structure m with parameters for display monitor for a
% particular computer (with name computerName). For use with the function
% prepScreen that opens a Psychtoolbox window. 
% 
% fields of m: 
% - width: width of active pixels [cm]
% - height: height of active pixels [cm]
% - subDist: distance of subject's eyes from monitor [cm]
% - goalResolution: desired screen resolution, horizontal and vertical [pixels]. 
%   PTB will try to set this resolution, unless it is left empty. 
% - goalFPS: desired screen refresh rate, in frames per second [Hz]. 
%   PTB will try to set this referesh rate, unless it is left empty. 
% - skipSyncTests: whether PTB should skip synchronization tests [boolean]
% - calibFile: the name of a mat file that contains the luminance calibration information, 
%   as a table to load into  Screen('LoadNormalizedGammaTable' [character string]. 
%   Can be left empty. 
% - monName: name of this monitor [character string]
% 
% Also returns status, which is 1 if input computerName matches one of the
% setups stored in this function, 0 if there was no match and monitor
% parameters resorted to the default. 

function [m, status] = getDisplayParameters(computerName)

status = 1;

switch computerName
        
    case 'CHDD'
        m.width = 53.34;
        m.height = 29.85;
        m.subDist = 53.34; %(21 inches)
        m.goalResolution = [1920 1080];
        m.goalFPS = 120;
        m.skipSyncTests = 1;
        
        %to use calibration fit to each gun separately (with suboptimal fit to blue gun): 
        m.calibFile = 'CHDD_LG_BDEComputer_Rm370_26Jan2016.mat';
        
        %to use calibration fit to gray levels only:
        %m.calibFile = 'CHDD_LG_BDEComputer_Rm370_26Jan2016_Gray.mat';
        
        m.colorCalibFile = '';
        m.monName = 'LG';
        
    case 'coombs'
        m.width = 35;
        m.height = 26.2500;
        m.subDist = 60;
        m.goalResolution = [832 624];
        m.goalFPS = 120;
        m.skipSyncTests = 0;
        m.calibFile = 'CoombsCalib070815.mat';
        m.monName = 'LabViewSonic';
        
    case 'Meriwether'
        m.width = 36;
        m.height = 29;
        m.subDist = 60;
        m.goalResolution = [1024 768];
        m.goalFPS = 60;
        m.skipSyncTests = 1;
        m.calibFile = '';
        m.monName = 'DELL';
        
    case 'turing'
        m.width = 40.5;
        m.height = 25.5;
        m.subDist = 57;
        m.goalResolution = [];
        m.goalFPS = [];
        m.skipSyncTests = 1;
        m.calibFile = '';
        m.monName = 'ASUS';
        
    otherwise 
        m.width = 36;
        m.height = 29;
        m.subDist = 60;
        m.goalResolution = [];
        m.goalFPS = [];
        m.skipSyncTests = 1;
        m.calibFile = '';
        m.monName = 'default';
        status = 0;
end

m.computerName = computerName;