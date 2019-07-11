function rubber(rect);
%
% deletes a rectangle (sets it to background color)
% 
% rect:	 [X1 Y1 X2 Y2]
% 
% 2006 by Martin Rolfs (for Mac OSX)

global scr

Screen(scr.main,'FillRect',scr.bgColor,rect);
