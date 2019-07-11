%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Ouptut data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Alex White, September 2014
%
% function task = outputData(task, data, datFid)
%
%
% This function, when used inside a psychtoolbox experiment, prints out
% trial data to a txt tile, an edf file, and saves them in the "task.data"
% structure that at the end of the experiments is saved in a mat file.
%
% Before using this function in the experiment, on the first trial of a block
% you must call initDataOutput, which  initializes empty vectors for each
% variable in the task.data structure, adds a header to the txt file, an
% divides the variables into separate strings for the edf file (so that the
% strings sent with Eyelink('message') don't get too long and crash Matlab.
% On the first trial it also saves which "class" the variables are: character strings,
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
% - task: original structure returned with data added to the task.data
%   structure


function task = outputData(task, data, datFid)


dvars = fieldnames(data);
nVars = numel(dvars);
edfDat1 = ''; %initialize the first string


%If not first trial, print it all out!
%first entry in text file is subject initials:
if task.dataToTxt, fprintf(datFid,'%s\t',task.subj); end

for edfI = 1:task.numEDFStrings %reset the edf strings to nothing
    eval(sprintf('edfDat%i = '''';',edfI));
end


for varI = 1:nVars
    thisVar = dvars{varI};
    fullVar = ['data.' thisVar];
    
    edfI = task.dataEDFStringIs(varI);
    
    %Add to mat file
    eval(sprintf('task.data.%s=[task.data.%s %s];', thisVar, thisVar, fullVar));
    
    switch task.dataClasses(varI)
        case 1
            %print out string to txt file
            if task.dataToTxt, eval(sprintf('fprintf(datFid,''%%s\\t'',%s);',fullVar)); end
            
            %print to EDF string
            eval(sprintf('edfDat%i = sprintf(''%%s\\t %%s'',edfDat%i,%s);', edfI, edfI, fullVar));
            
        case 2
            %print out integer to txt tile
            if task.dataToTxt, eval(sprintf('fprintf(datFid,''%%i\\t'',%s);',fullVar)); end
            
            %print out integer to edf file
            eval(sprintf('edfDat%i = sprintf(''%%s\\t %%i'',edfDat%i,%s);', edfI, edfI, fullVar));
            
        case 3
            %print out number to txt file
            if task.dataToTxt, eval(sprintf('fprintf(datFid,''%%.4f\\t'',%s);',fullVar)); end
            
            %print out number to edf file
            eval(sprintf('edfDat%i = sprintf(''%%s\\t %%.4f'',edfDat%i,%s);', edfI, edfI, fullVar));
    end
end

%return character between trials on txt file
if task.dataToTxt, fprintf(datFid,'\n'); end


%Save EDF data: loop through all the strings
if task.EYE>=0
    for edfdi = 1:task.numEDFStrings
        eval(sprintf('edfDat = edfDat%i;',edfdi));
        Eyelink('message', 'TrialData%d %s', edfdi, edfDat);
    end
    Eyelink('message', 'TRIAL_ENDE %d',  data.trial);
end

