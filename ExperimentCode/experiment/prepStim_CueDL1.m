function prepStim_CueDL1()

global scr;
global task


%% Fixation point:
scr.fixCkRad = round(task.fixCheckRad*scr.ppd);   % fixation check radius
scr.intlFixCkRad = round(task.initlFixCheckRad*scr.ppd);   % fixation check radius, for trial start

task.fixation.posX  = scr.centerX+scr.ppd*task.fixation.ecc.*cosd(task.fixation.posPolarAngles);
task.fixation.posY  = scr.centerY-scr.ppd*task.fixation.ecc.*sind(task.fixation.posPolarAngles);

angles = [0 90];
allxy = [];
for ai = 1:2
    startx = -scr.ppd*0.5*task.fixation.length*cosd(angles(ai));
    endx = scr.ppd*0.5*task.fixation.length*cosd(angles(ai));
    starty = -scr.ppd*0.5*task.fixation.length*sind(angles(ai));
    endy =  scr.ppd*0.5*task.fixation.length*sind(angles(ai));
    
    newxy = [startx endx; starty endy];
    
    allxy = [allxy newxy];
end
task.fixation.allxy = allxy;

%% Spatial cue 

switch task.cue.type
    case {1,2} %ring or dot
        task.cue.centerX = round(scr.centerX+scr.ppd*task.cue.ecc*cosd(task.cue.posPolarAngles));
        task.cue.centerY = round(scr.centerY-scr.ppd*task.cue.ecc*sind(task.cue.posPolarAngles));
        task.cue.radPix    = round(scr.ppd*task.cue.rad);
        
        %[left top right buttom]
        task.cue.rects   = [task.cue.centerX'-task.cue.radPix task.cue.centerY'-task.cue.radPix task.cue.centerX'+task.cue.radPix task.cue.centerY'+task.cue.radPix];
        
        if isfield(task,'cueRH') %Roach & Hogben style cue in Version 3
            task.cueRH.centerX = round(scr.centerX+scr.ppd*task.cueRH.ecc*cosd(task.cueRH.posPolarAngles));
            task.cueRH.centerY = round(scr.centerY-scr.ppd*task.cueRH.ecc*sind(task.cueRH.posPolarAngles));
            task.cueRH.radPix    = round(scr.ppd*task.cueRH.rad);
            
            %[left top right buttom]
            task.cueRH.rects   = [task.cueRH.centerX'-task.cueRH.radPix task.cueRH.centerY'-task.cueRH.radPix task.cueRH.centerX'+task.cueRH.radPix task.cueRH.centerY'+task.cueRH.radPix];

        end
    case 3 %line
        task.cue.x1 = round(scr.centerX+scr.ppd*task.cue.minEcc*cosd(task.cue.posPolarAngles));
        task.cue.x2 = round(scr.centerX+scr.ppd*task.cue.maxEcc*cosd(task.cue.posPolarAngles));
        task.cue.y1 = round(scr.centerY-scr.ppd*task.cue.minEcc*sind(task.cue.posPolarAngles));
        task.cue.y2 = round(scr.centerY-scr.ppd*task.cue.maxEcc*sind(task.cue.posPolarAngles));
end

%make cue.color be a 2-row matrix, with 1st row for cue absent, color = background
task.cue.color   = [scr.bgColor*ones(1,3); task.cue.color];

if isfield(task,'cueRH') %Roach & Hogben style cue in Version 3
    task.cueRH.color   = [scr.bgColor*ones(1,3); task.cueRH.color];
end
%% Gabors
task.gabor.posX = round(scr.centerX+scr.ppd*task.gabor.ecc*cosd(task.gabor.posPolarAngles));
task.gabor.posY = round(scr.centerY-scr.ppd*task.gabor.ecc*sind(task.gabor.posPolarAngles));
task.gabor.sizePx = round(scr.ppd*task.gabor.size);


%Gabor's Gaussian window
task.gaussWin = ptbMakeGaussian(task.gabor.size,task.gabor.size,task.gabor.sd,task.gabor.sd);
task.gaussTexSize = size(task.gaussWin);

%Gabor itself: Make here to speed up each trial
grat = ptbMakeGrating(task.gabor.size, task.gabor.size,task.gabor.sf,task.gabor.standardOri,task.gabor.phase);
img = task.gabor.contrast*grat.*task.gaussWin*scr.deltaColor+scr.bgColor;
%round
if ~scr.normalizedLums
    img = round(img);
end
%clip
img(img>scr.white) = scr.white;
img(img<scr.black) = scr.black;

task.gabor.img = img;
task.gaborTex = Screen('MakeTexture',scr.main,task.gabor.img);

wid = size(task.gabor.img,2);
hei = size(task.gabor.img,1);
task.gabor.wid = wid;
task.gabor.hei = hei;

%texture positions 
g = task.gabor;

task.gabor.rects = [g.posX'-floor(wid/2) g.posY'-floor(hei/2) g.posX'+ceil(wid/2) g.posY'+ceil(hei/2)];


%% Text

%Text rendering:
Screen('Preference', 'TextRenderer', 1); %0=fast but no anti-aliasing; 1=high-quality slower, 2=FTGL (whatever that is)
%Try again to get rid of text anti-aliasing
Screen('Preference','TextAntiAliasing',0);


Screen('TextFont',scr.main,task.fontName);
Screen('TextSize',scr.main,task.textSize);
Screen('TextStyle',scr.main,0);


%% Feedback images: star and x 
star = imread('greenStar3Small.bmp','bmp'); 
%make it a bit darker
star = star*.9;
%get set white pixels to background 
cutoff = 130;
iswhite = star(:,:,1)>cutoff & star(:,:,2)>cutoff & star(:,:,3)>cutoff;

for g=1:3
    gi = squeeze(star(:,:,g));
    gi(iswhite)=scr.bgColor;
    if task.grayscale
        gi(~iswhite)=mean([scr.bgColor scr.white]);
    end
    star(:,:,g)=gi;
end
swid = size(star,2); shei=size(star,1);

task.starTex = Screen('MakeTexture',scr.main,star);
task.starRect = [scr.centerX-floor(swid/2) scr.centerY-floor(shei/2) scr.centerX+ceil(swid/2) scr.centerY+ceil(shei/2)];
    
%adjust position a bit to center vertically, if using the smallest start (greenStar3Small)
task.starRect = task.starRect - [0 2 0 2];

%red x: 
task.feedbackX.posX  = scr.centerX+scr.ppd*task.fixation.ecc.*cosd(task.fixation.posPolarAngles);
task.feedbackX.posY  = scr.centerY-scr.ppd*task.fixation.ecc.*sind(task.fixation.posPolarAngles);
angles = [45 135];
allxy = [];
for ai = 1:2
    startx = -scr.ppd*0.5*task.feedbackX.length*cosd(angles(ai));
    endx = scr.ppd*0.5*task.feedbackX.length*cosd(angles(ai));
    starty = -scr.ppd*0.5*task.feedbackX.length*sind(angles(ai));
    endy =  scr.ppd*0.5*task.feedbackX.length*sind(angles(ai));
    
    newxy = [startx endx; starty endy];
    
    allxy = [allxy newxy];
end
task.feedbackX.allxy = allxy;

%figure out how to position feedback text to be centered 
if task.feedbackPoints
    task.feedbackPointsText{1} = sprintf('+%i',task.feedbackPointsLoss);
    task.feedbackPointsText{2} = sprintf('+%i',task.feedbackPointsGain);

    for pti=1:2
        bounds = Screen(scr.main,'TextBounds',task.feedbackPointsText{pti});
        task.feedbackPointsHShift(pti) = -bounds(3)/2;
        task.feedbackPointsVShift(pti) = -bounds(4)/2;
    end
end


%% %%%%%  Sounds
prepSounds;






