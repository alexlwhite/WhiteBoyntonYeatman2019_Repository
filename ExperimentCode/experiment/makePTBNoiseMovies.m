function makePTBNoiseMovies(td)

global scr task

if td.cueCond<0
    stimToDraw = abs(td.cueCond);
    targsPres(stimToDraw) = td.targPres;
else
    stimToDraw = 1:length(task.noise.posPolarAngles);
    if td.targSide == 1
        targsPres = [td.targPres td.distPres];
    else
        targsPres = [td.distPres td.targPres];
    end
end

%make 1D gabor temporal waveform into a "movie", where each frame is is all 1 number, the scalar
%by which to modulate Gabor contrast:
gaborWave  = repmat(reshape(td.gaborTempMod,1,1,task.noise.framesPerMovie),[task.noise.sizePx task.noise.sizePx  1]);

task.movieTex = zeros(length(task.noise.posPolarAngles), task.noise.framesPerMovie);

for sli = stimToDraw
    eval(sprintf('movI = td.movieI%i;',sli));
    eval(sprintf('ctrX = td.targ%iCtrX;',sli));
    eval(sprintf('ctrY = td.targ%iCtrY;',sli));
    
    load(sprintf(task.noise.movieFileForm,movI)); %load movie matrix m
    
    m = task.noise.sdContrast*m; %.*task.noise.attenuateEdgeMask; %scale by contrast and attenuate edges 
                                 %(now movies are pre-made with edges attenuated)
                           
    %Make Gabor   
    gaborImg = myMakeGabor(ctrX, ctrY, targsPres(sli)*td.gaborContrast);   
 
    %Make whole Gabor movie (to be faster than doing it in each loop)
    gaborMovie = repmat(gaborImg,[1 1 task.noise.framesPerMovie]);
        
    sM = m+gaborMovie.*gaborWave;

    
    %clip to range [-1 1]
    sM(sM>1) = 1;   sM(sM<-1)=-1;
    
    %move to range [0 1]
    sM = (sM+1)/2;
    
    if ~scr.normalizedLums
        %put in 0-255 range:
        sM = round(255*sM);
    end
    
    
    for fri = 1:task.noise.framesPerMovie        
        task.movieTex(sli,fri) = Screen('MakeTexture',scr.main,sM(:,:,fri));
    end
    
end
end



function [gaborImg] = myMakeGabor(ctrX, ctrY, contrast)
%Return an image (gabrImg) the same size as the noise patch, with a Gabor embedded in
%it, at the max contrast for this trial, at center pixel position [ctrX, ctrY] 
global task

%Use pre-made Gabor:
gabor = task.gabor.img*contrast;

x1 = ctrX - task.gabor.halfWid;
y1 = ctrY - task.gabor.halfHei;

x2 = x1 + task.gabor.wid - 1;
y2 = y1 + task.gabor.hei - 1;

%create base image of Gabor
gaborImg = zeros(task.noise.sizePx,task.noise.sizePx);
gaborImg(y1:y2, x1:x2) = gabor(:,:);

end
