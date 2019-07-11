function [fullFileName, eyelinkFileName] = setupDataFile(fileNum)

global task scr


crntDir = pwd; nlets = length(crntDir);
if strcmp('code',crntDir(nlets-3:nlets))
    dataFolder = fullfile(crntDir(1:nlets-4),'data');
else
    dataFolder = fullfile(pwd,'data');
end

if ischar(task.subj)
    subjN = task.subj;
else
    subjN = sprintf('s%i',task.subj);
end

thedate=date;
folderdate=[subjN thedate(4:6) thedate(1:2)];



scr.datadir = fullfile(dataFolder,subjN,folderdate);

if task.practice
    scr.datadir = fullfile(scr.datadir,'practice');
end

if ~isdir(scr.datadir)
    mkdir(scr.datadir);
    display(sprintf('\nMaking a folder for this subject in data directory!'));
end

% Decide what this data file should be called
thedate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
if task.doStair
    filename = sprintf('%s_%s_Stair',subjN,thedate);
else
    filename = sprintf('%s_%s',subjN,thedate);
end
if task.practice
    filename = sprintf('%s_prac',filename);
end

% make sure we don't have an existing file in the directory
% that would get overwritten
bn = fileNum-1;
goodname = false;

while ~goodname
    bn = bn+1;
    fullFileName = fullfile(scr.datadir, sprintf('%s_%02i',filename, bn));
    filenameshort = sprintf('%s_%02i',filename, bn);
    goodname = ~(isfile(sprintf('%s.mat',fullFileName)) || isfile(sprintf('%s.txt',fullFileName)) || isfile(sprintf('%s.edf',fullFileName)));
end

scr.dataFileName=fullFileName;
    
fprintf(1,'\n\nSaving data file as %s\n\n',fullFileName);

%eyelink file name
if task.practice
    extraLet='p';
else
    if task.doStair
        extraLet='s';
    else
        extraLet='';
    end
end
eyelinkFileName = sprintf('%s%s_%i%s',subjN,datestr(now,'dd'),bn,extraLet);
scr.eyelinkFileName=eyelinkFileName;

