function analyzeThresholdReliability(T, paths)

%% choices
log10Threshs = true;
nSubj = size(T,1);
nConds = 4;

%cap thresholds at this value to avoid nonsensical outliers (has no effect
%for session1 to session2 reliability)
threshCap = 1000;
threshReplace = 133;

doPlot = false;

%% open stat file
fName = 'ThresholdReliabilities.txt';
f = fopen(fullfile(paths.stats,fName),'w');

fprintf(f,'RELIABILITY OF THRESHOLD MEASUREMENTS');
if log10Threshs
    fprintf(f,'\nThresholds are log10 transformed\n');
end
%% analyze each subject's data

%maxSessions: how many session to include in the half-split analysis. Only
%analyze subjects with at least that many sessions.
for maxSessions = 2
    
    thresholds = NaN(nSubj, nConds, 2);
    
    
    for si=1:nSubj
        %load in the text file with information about each trial
        subj = T.IDs{si};
        subjFile = fullfile(paths.data, 'indiv', sprintf('%sAllDat.txt', subj));
        d = readtable(subjFile);
        %note: this prints a warning about variable names being modified,
        %because one column in the AllDat text file is call "catch", which
        %is also a Matlab term. it gets changed to xCatch. Not a problem.
        
        %analyze the data... only if the subject has enough sessions
        if max(d.dateNum)>=maxSessions
            r = analyzeSubject_HalfSplit(d, maxSessions);
            
            %add results to the big matrix of thresholds:
            for ci=1:length(r.condLabels)
                
                thisCond = r.condLabels{ci};
                
                %initalize the columns in the table on 1st subject
                if si==1
                    eval(sprintf('Threshs_%s = NaN(nSubj,2);', thisCond));
                end
                
                %ONLY SAVE THESE INDIVIDUAL HALF-SPLIT THRESHOLDS IF THE OVERALL
                %THRESHOLD SAVED IN TABLE T WAS ACCEPTABLE (~NAN)
                eval(sprintf('goodThresh = ~isnan(T.thresh_%s(si));', thisCond));
                if goodThresh
                    eval(sprintf('thresholds(si, ci, :) = r.thresh_%s;', thisCond, thisCond));
                end
            end
        end
        
    end
    
    if ~isnan(threshCap)
        thresholdsOverCap = thresholds>threshCap;
        nThresholdsOverCap = sum(thresholdsOverCap(:));
        nSubjsWithThresholdsOverCap = sum(squeeze(any(any(thresholdsOverCap,3),2)));
        badThreshs = thresholds(thresholds>threshCap);
        meanBadThresh = mean(badThreshs);
        thresholds(thresholds>threshCap) = threshReplace;
    end
    
    if log10Threshs
        thresholds = log10(thresholds);
    end
    
    
    %% compute reliability
    nConds = length(r.condLabels);
    reliability  = NaN(1,nConds);
    Ns = NaN(1,nConds);
    
    if doPlot, figure; end
    
    for ci=1:length(r.condLabels)
        thisCond = r.condLabels{ci};
        ts = squeeze(thresholds(:, ci, :));
        
        %exclude subjects who dont have this condition
        goods = ~any(isnan(ts),2);
        ts = ts(goods,:);
        
        reliability(ci) = corr(ts(:,1),ts(:,2));
        Ns(ci) = size(ts,1);
        
        if doPlot
            subplot(2,2,ci);
            plot(ts(:,1), ts(:,2),'.');
            title(sprintf('%s %.3f',thisCond, reliability(ci)));
        end
    end
    
    %disattenuate these correlations to estimate what they would be with twice
    %as much data. Use the Spearman-Brown prediction formula
    m = 2; %factor to multiply data
    disattenReliability = m*reliability./(1+(m-1)*reliability);
    % https://en.wikipedia.org/wiki/Spearman%E2%80%93Brown_prediction_formula
    
    %now do reliability of cueing effect, difference in (log) thresholds
    cuedI = strcmp(r.condLabels, 'Cued');
    uncuedI = strcmp(r.condLabels, 'Uncued');
    effects = squeeze(thresholds(:, uncuedI, :) - thresholds(:, cuedI, :));
    
    goods = ~any(isnan(effects),2);
    effects = effects(goods,:);
    cueEffectReliability = corr(effects(:,1),effects(:,2));
    
    if doPlot
        figure;
        plot(effects(:,1), effects(:,2), '.');
        title(sprintf('Cueing effect %.3f', cueEffectReliability));
    end
    %disattenuate that reliability:
    cueEffectReliability_Disatten =  m*cueEffectReliability./(1+(m-1)*cueEffectReliability);
    
    %% print stats
    
    fprintf(f,'================================================================\n');
    if maxSessions==1
        fprintf(f,'FITTING THRESHOLDS IN THE FIRST AND SECOND HALVES OF EACH SUBJECTS FIRST SESSION ONLY\n');
    elseif maxSessions==2
        fprintf(f,'FITTING THRESHOLDS IN THE FIRST AND SECOND SESSIONS OF SUBJECTS WHO HAVE MORE THAN 1 SESSION\n');
    end
    
    
    if ~isnan(threshCap) && nThresholdsOverCap>0
        fprintf(f,'\nThresholds over %i deg are set to %i deg, to avoid extreme outliers due to very bad performance in a single block.', threshCap, threshReplace);
        fprintf(f,'\nThat led to %i thresholds (mean = %.2f) from %i subjects being capped.', nThresholdsOverCap, meanBadThresh, nSubjsWithThresholdsOverCap);
        fprintf(f,'\nThose thresholds were:\t');
        for bti=1:nThresholdsOverCap
            fprintf(f,'%.5f\t', badThreshs(bti));
        end
        fprintf(f,'\n\n');
    end
    
    fprintf(f,'\nCondition\tRho\tN\n');
    for ci=1:nConds
        fprintf(f,'%s\t%.3f\t%i\n', r.condLabels{ci}, reliability(ci), Ns(ci));
    end
    
    fprintf(f,'\nAcross-condition mean reliability: %.3f', mean(reliability));
    
    fprintf(f,'\nReliability of the cueing effect (Uncued - Cued): %.3f\n', cueEffectReliability);
    
    %Disattenuated reliabilities
    if maxSessions==1
        fprintf(f,'\n\nDisattenuated reliabilities using Spearman-Brown Prophecy Formula, simulating doubling the data:\n');
        fprintf(f,'Condition\tRho\tN\n');
        for ci=1:nConds
            fprintf(f,'%s\t%.3f\t%i\n', r.condLabels{ci}, disattenReliability(ci), Ns(ci));
        end
        fprintf(f,'\nAcross-condition mean disattenuated reliability: %.3f\n', mean(disattenReliability));
        
        fprintf(f,'\tDisattenuated cueing effect reliability: %.3f\n',cueEffectReliability_Disatten);
    end
    
end

