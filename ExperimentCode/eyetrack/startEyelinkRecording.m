function record = startEyelinkRecording(el)

global task

Eyelink('startrecording');	% start recording
% You should always start recording 50-100 msec before required otherwise you may lose a few msec of data
WaitSecs(task.startRecordingTime);

if task.EYE>=0
    key = 1;
    while key~= 0
        key = EyelinkGetKey(el);		% dump any pending local keys
    end
end

err = Eyelink('checkrecording'); 	% check recording status
if err==0
    record = 1;
    Eyelink('message', 'RECORD_START');
else
    record = 0;	% results in repetition of fixation check
    Eyelink('message', 'RECORD_FAILURE');
    fprintf(1,'\n\nRECORD_FAILURE !!!!!!!\n\n');
end