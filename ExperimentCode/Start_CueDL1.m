%CueDL start script 
%This is code to run the experiment repoted by White, Boynton & Yeatman
%(2019): The link between reading ability and visual spatial attention
%across development.
% 
% Note: this code requires the Palamedes Toolbox
% (http://www.palamedestoolbox.org/) and Matlab's statistics toolbox. 
% 
% 
%% 

home; clear all; close all; %'clear all' is important to keep access to keyboards

%% Subject ID number:  

subj = 'XX123'; 

%% experiment version: 1, 2 or 3. 
%  1 is the orginal version.
%  2 is an updated version with the following changes: 
%        (a) no single stimulus condition, 
%        (b) monitor luminance linearized
%        (c) 5 freebie trials per block (rather than 4) 
%        (d) freebie tilt fixed to 25deg (rather than a function of current threshold) 
% 3 is a new version that is the same as version 1 with an additional cue
% condition that matches Roach & Hogben exactly. 

exptVersion = 3; 

%% computer name (with screen details listed in getDisplayParameters.m)
computerName = 'CHDD'; 

%% run it
stairRes = CueDL1_RunBlocks(subj,exptVersion,computerName); 

sca;


