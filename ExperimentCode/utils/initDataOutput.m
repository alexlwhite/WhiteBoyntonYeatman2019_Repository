%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Initialize data output structures 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Alex White, April 2015
%
% function task = initDataOutput(task, data, datFid)
%
%
% This function, when used inside a psychtoolbox experiment, initializes data 
% output structures. For use in combination with the function outputData, 
% which prints out trial data to a txt tile, an edf file, and saves them in 
% the "task.data" structure that at the end of the experiments is saved in a mat file.
% This function, initDataOutput, should be called on the first trial, once 
% the first trial's data has been collected. It initializes empty vectors for each
% variable in the task.data structure, adds a header to the txt file, an
% divides the variables into separate strings for the edf file (so that the
% strings sent with Eyelink('message') don't get too long and crash Matlab.
% It also saves which "class" the variables are: character strings,
% integers with 0 decimals, or doubles with 4 decimals.
%
% Inputs:
% - task:   task structure with all info about experiment
% - data:   data structure with fields for each variable from the last
%           trial that should be printed out
% - datFid: the handle to the text file 
% 
%
% Outputs: 
% - task: original structure returned with some arguments added:
%       - dataClasses, which is a vector of integers for each variable
%         (1=string,2=integer,3=double)
%       - data.EDFStringIs, which is a vector of indices indicating which edf data
%         string each variable should be added to. 
%       - edfVariableNames, which is a cell array containing the names of each
%         variable in each edf data string (rows = string number, columns = column
%         in edf file). 
%       - task.numEDFStrings, the total number of strings sent to EDF file (there
%         will be one line for each, beginning 'TrialData1 ...', 'TrialData2 ...', etc. 


function task = initDataOutput(task, data, datFid)

%On first trial, initialize variables, and make headers, and divide up the
%variables for the EDF files

edfStringMax = 100; %max characters in a string sent to edf file

edfDat1 = ''; %initialize the first string
edfCount = 1; %number of strings
edfSubcount = 0; %numberof variables in each string

dvars = fieldnames(data);
nVars = numel(dvars);


if data.trial==1 
    task.dataClasses = zeros(1,nVars); %Which type of variable is each one: 1=string, 2=integer, 3=double (kinda)
    task.dataEDFStringIs = zeros(1,nVars); %Which edf string does each variable belong to
    
    
    %Print header for first variable in txt file, which is is subject initials
    if task.dataToTxt, fprintf(datFid,'subj\t'); end
    
    
    for varI = 1:nVars
        thisVar = dvars{varI};
        fullVar = ['data.' thisVar];
        edfSubcount = edfSubcount+1;
        
        %Initialize variable in matlab data structure:
        eval(sprintf('task.data.%s=[];', thisVar));
        
        %Add variable to header in text file:
        if task.dataToTxt, fprintf(datFid,'%s\t',thisVar); end
        
        %Assign it to an edf file string number, so those strings dont
        %get too long
        eval(sprintf('vclass = class(%s);',fullVar));
        if strcmp(vclass,'char')
            %print to EDF string
            eval(sprintf('edfDat%i = sprintf(''%%s\\t %%s'',edfDat%i,%s);',edfCount, edfCount, fullVar));
            task.dataClasses(varI) = 1;
            
        elseif strcmp(vclass,'double') || strcmp(vclass,'single') || strcmp(vclass,'logical')
            if strcmp(vclass,'logical')
                isIntgr = true;
            else
                eval(sprintf('isIntgr = (%s-round(%s))==0;',fullVar, fullVar));
            end
            %print out integer
            if isIntgr
                %print out integer to edf file
                eval(sprintf('edfDat%i = sprintf(''%%s\\t %%i'',edfDat%i,%s);',edfCount, edfCount, fullVar));
                task.dataClasses(varI) = 2;
            else %print out number to 4 decimals
                %print out number to edf file
                eval(sprintf('edfDat%i = sprintf(''%%s\\t %%.4f'',edfDat%i,%s);',edfCount, edfCount, fullVar));
                task.dataClasses(varI) = 3;
            end
        else %error
            fprintf(1,'\n\n\t\t\t!!!Warning!!\t\t\t\n(outputData) Data Variable %s can''t be printed\n\n\n',fullVar);
            return
        end
        
        task.dataEDFStringIs(varI) = edfCount;
        
        %save which variables are in which edf string
        task.edfVariableNames{edfCount,edfSubcount}=thisVar;
        %Cut off edfDat at max characters, and start a new one if too long
        eval(sprintf('tooLong = length(edfDat%i)>=edfStringMax;',edfCount));
        
        if tooLong && varI~=nVars %initialize the next string, unless we're on the last variable
            edfCount = edfCount+1;
            edfSubcount = 0;
            eval(sprintf('edfDat%i = '''';',edfCount));
        end
        
    end
    task.numEDFStrings = edfCount;
    %return character
    if task.dataToTxt, fprintf(datFid,'\n'); end
end
