function b = getKeyAssignment()% unify keynames for different operating systemsKbName('UnifyKeyNames');b.resp = KbName({'DownArrow','RightArrow','q'}); %'q' to quit should be the last oneb.quit = numel(b.resp);   otherKeys = KbName({'c','v','d','a','escape','space','return'});  %for calibration, validation, drift correctionFlushEvents('keyDown');%Restrict keyboard so nothing works except necessary keysRestrictKeysForKbCheck([b.resp otherKeys]);