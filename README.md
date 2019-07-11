WhiteBoyntonYeatman2019_Repository
by Alex L. White, July 2019 at the University of Washington 

This repository contains experiment code, raw data, and analysis code associated with White, Boynton & Yeatman's 2019 article, "The link between reading ability and visual spatial attention across development."

Using the Matlab code here, you can run the experiment and collect your own data, and use our data set to recreate all the figures and statistical analyses reported in the paper. 

Running the staircase in the experiment as well as fitting psychometric functions requires the Palamedes Toolbox (http://www.palamedestoolbox.org/). We used version 1.8. Our code also depends on several functions in Matlab's statistics toolbox, such as nanmean, randsample, and fitlme.  

There are several folders in this repo: 

(1) ExperimentCode. This contains code to run the experiment, display stimuli, and collect responses. First open the script Start_CueDL1, set the "subj" variable to the subject ID, the experimentVersion, and computerName. Then run that script and it will prompt you about doing practice blocks, and then continuing to the main experiment. 

Note: the keys for the subject to respond are the down arrow and the up arrow, to report counterclockwise and clockwise tilts, respectively. To end a block of trials early, press q. Those key assigments are set in getKeyAssignment.m. 

Data you collect are stored in ExperimentCode/data/subj/subj<DATE>, where <DATE> is something like Jul11. Where the data are automatically saved is determined in setupDataFile.m. For each block run, two files will automaticlaly be saved: a .mat file and a .txt file. The .txt file contains 1 row for each trial, and many columns for various descriptors of what happened on that trial. The .mat file contains two variables: scr, a structure with information about the screen, and task. The task variable is a structure with lots of other information about the stimulus and task, including task.data, with many fields, each of which is a vector. Each element of those vectors is for 1 trial. For example, task.data.respCorrect records whether the subject's response on each trial was correct or incorrect. 

    
The ExperimentCode folder contains several subfolders: 
- displayInfo: information about displays, to correctly size stimuli and calibrate the luminance output. getDisplayParameters.m is where you can enter the details of your display (which is linked to the computerName variable set in Start_CueDL1.m)
- experiment: this contains most of the code to present the stimuli. CueDL1_Params sets parameters for the stimuli. 
- eyetrack: this contains functions to communicate with an Eyelink eyetracker. However, the code is *not* currently set up to do any eye-tracking, so this code is unused. But it could be used if params.EYE is set to 1 (in experiment/CueDL1_Params.) 
- utils: various other useful functions. 

(2) Data. This contains the data set reported in our paper. In Data/indiv, there is 1 text file for each of the 129 participants who completed at least 1 session of the study. Each text file is named with format XXAllDat.txt, where XX is the subject's anonymized ID code. Each text file is a tab-delimited table, with 1 row for each trial. There are many columns. The most important ones are: 
- cueCond: stimulus condition. 0=Uncued; 1=Cued, 2=Single Stimulus; 3=Small Cue 
- gaborTilt: degrees of tilt of the target Gabor. 
- tiltDirctn: -1 or 1, for counterclockwise or clockwise tilt of the target (relative to vertical)
- chosenRes: 1 or 2, for which key the suject pressed to report tilt direction. 1=counterclockwise, 2=clockwise.  
- respCorrect: 0 or 1, whether the subject's response was incorrec or correct
- tRes: response time, relative to the trial start. We compute RT as tRes-tGaborOns (time between target stimulus onset and the keypress)
- dateNum: session number. Some participants completed more than 1 session. We only analyze the 1st session. 
- blockNum: block number in the session. 
- targPolarAngle: polar angle of the target, where 0 = right size on the horizontal meridian, 90=above fixation on the vertical meridian, 180 = left side on the horizontal meridian, 270 = below fixation on the vertical meridian. 

The data folder also contain the csv file SubjectInfoTable.csv. This is a table of demographic information about each subject. Those columns are: 
    - age in years 
    - gender (1=male, 2=female)
    - readingProblems: whether they reported experiencing reading problems 
    - dyslexiaDiagnosis: whether they reported being diagnosed with dyslexia 
    - adhdDiagnosis: whether they reported being diagnoses with ADHD 
    - exptVersion: which version of the experiment they were tested in (1,2 or 3)
    - twre_index: summary score on the combined TOWRE test (PDE and SWE)
    - twre_pde_ss: scaled score on the TOWRE phonemic decoding sub-test (reading aloud pseudowords). This is our primary measure of reading ability 
    - twre_swe_ss: scaled score on the TOWRE sight word efficienty sub-test (reading aloud real words). 
    - wasiMatrixReasoningTScore: non-verbal IQ score 
    - wasiFullScale2Score: full IQ score. 

The Data folder also includes a Matlab version of that table: SubjectInfoTable.mat. Those same data are stored in a table T, along with a structure called tableNotes, with some info about the three subjects that were excluded for having vision problems. Note that those participant's data are still included in the Data/indiv folder. 

Finally, the Data folder includes the table with each subject's results added. This is the result of running the script WBY2019_AnalyzeSubjects. This table is saved as AllSubjectResultsTable.mat.

(3) AnalysisCode 

There are two main scripts to run all the analysis: 
WBY2019_AnalyzeSubjects.m. This loads in the raw data, analyzes each subject (fitting psychometric functions, etc) and saves the results in a table in Data/AllSubjectResultsTable.mat. This script calls analyzeSubject, analyzeTrials, and analyzeThresholdReliability. 

WBY2019_FiguresAndStats.m This script loads in the table with all the individual results, and does the group-level analyses to reproduce all the figures in the manuscript. Those are saves as .eps files in the Figures folder. It also prints the results of statistical analyses to .txt files in the Stats folder. For each figure, it calls a function in the AnalysisCode/FiguresAndStats subfolder. 

Note: in both the AnalyzeSubjects script and the FiguresAndStats script, it is possible to change the reading measure used to sort the subjects from the TOWRE Phonemic Decoding Efficiency score (twre_pwd_ss) to the Sight Word Efficiency score (twre_swe_ss). If so, the figures are put in Figures/SWE, the stats in Stats/SWE, and the results table is saved as AllSubjectResultsTable_SWE.mat.  

There is also a subfolder AnalysisCode/utils, which contains various functions needed for the analysis. All were written by Alex White, except: 
- boyntonBootstrap (adapted from a function by Geoffrey M. Boynton)
- exportfig.m: by Ben Hinkle, downloaded from the Matlab file exchange 
- fdr_bh: by David Groppe. 



