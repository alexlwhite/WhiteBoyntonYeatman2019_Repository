%Given a list of data variables to store and their format types, create format strings and prepare to save
%those data in a text file and in mat files. 

%Make format strings: 

for dti = 1:numDataStrings
    
    formatStr = endTrialDataTypes{dti}{1};
    for ti=2:numel(endTrialDataTypes{dti})
        formatStr = sprintf('%s\\t %s',formatStr,endTrialDataTypes{dti}{ti});
    end
    if dti==1, formatStr=[formatStr '\t']; end %add a tab for concatenating with the next one
    task.endTrialFormatStr{dti} = formatStr;
    task.endTrialData{dti} = endTrialData{dti};
    
    
    %Add header to text file and extract variables to be stored in mat files
    commaIs=find(endTrialData{dti}==',');
    commaIs=[commaIs (length(endTrialData{dti})+1)];
    starti=1;
    for di=1:length(commaIs)
        dtitle=endTrialData{dti}(starti:(commaIs(di)-1));
        if ~strcmp(dtitle,'task.subj')
            task.endTrialVars{dti}{di}=dtitle;
        end
        if numel(dtitle)>5
            if strcmp(dtitle(1:5),'task.')
                dtitle=dtitle(6:end);
            elseif strcmp(dtitle(1:5),'data.')
                dtitle=dtitle(6:end);
            end
        end
        
        if numel(dtitle)>3
            if strcmp(dtitle(1:3),'td.')
                dtitle=dtitle(4:end);
            end
        end
        
        %Add entry to header
        fprintf(datFid,'%s\t',dtitle);
        
        %initialize variable for storing in mat files
        if ~strcmp(dtitle,'subj')
            task.endTrialVarNames{dti}{di}=dtitle;
            eval(sprintf('task.data.%s=[];',dtitle));
        end

        starti=commaIs(di)+1;
    end
end
fprintf(datFid,'\n');

%make EDF format string 
task.edfFormatStr = task.edfDataTypes{1}; 
for ti=2:numel(task.edfDataTypes)
    task.edfFormatStr = sprintf('%s\\t %s',task.edfFormatStr,task.edfDataTypes{ti});
end
