function prepSounds()

clear all
global task

task = CueDL1_Params;
task.computerName = 'CHDD';

%% %%%%% Feedbacks sounds:
soundMode = 1; %playback only 
latClass = 0; % 1 is reasonably fast latency, but doesn't take over all sound functionality 

%create sounds ...

%Eyelink seems to use old 'Snd' function in it calibration routine, which
%meses with using PsychPortAudio
%So if we're using eyelink, let's not use PsychPortAudio but instead old
%fasioned Snd
task.usePortAudio = task.EYE<0;

if task.usePortAudio
    InitializePsychSound;
end

nblank = round(task.soundsOutFreq*task.soundsBlankDur);

for si=1:4
    nsignl = round(task.soundsOutFreq*task.sounds(si).toneDur); 
    t = (0:(nsignl-1))/task.soundsOutFreq;
    
    task.sounds(si).signal = [zeros(1,nblank) linspace(0.5,0,nsignl)].*[zeros(1,nblank) sin(2*pi*t*task.sounds(si).toneFreq)];
    task.sounds(si).signal = repmat(task.sounds(si).signal,2,1);
    task.sounds(si).freq = task.soundsOutFreq;
    task.sounds(si).nrchannels = size(task.sounds(si).signal,1);
    
end

% Timeout/FixBreak feedback
%Just two repetitions of incorrect sound
task.sounds(5).signal = repmat(task.sounds(3).signal,1,2);
task.sounds(5).freq = task.soundsOutFreq;
task.sounds(5).nrchannels = size(task.sounds(5).signal,1);


if task.usePortAudio
    if strcmp(task.computerName,'CHDD')
        devNum = 7; %'8=sysdefault'
    else
        devNum = [];
    end
    %Make buffers
    for si=1:length(task.sounds)
        fprintf(1,'\n\nTrying to open sound %i\n',si);
        task.sounds(si).handle = PsychPortAudio('Open', devNum, soundMode, latClass, task.sounds(si).freq, task.sounds(si).nrchannels);
        PsychPortAudio('FillBuffer', task.sounds(si).handle, task.sounds(si).signal);
    end
else
    Snd('Open');
end
%Play a sound to load up the sound engine (avoid delay on first feedback beep)
playPTB_DataPixxSound(2);
