function [T, ageLabs, ageBins] = assignTwoAgeGroups(T)

ageCutoff = 20;
ageMin = floor(min(T.age)); ageMax = ceil(max(T.age));
ageBins = [ageMin ageCutoff; ageCutoff ageMax];

%sort into age bins
nAgeGroups = size(ageBins,1);
ageGroup = NaN(size(T.age));
ageLabs = cell(1,nAgeGroups);
for ai = 1:nAgeGroups 
    ageS = T.age>=ageBins(ai,1) & T.age<ageBins(ai,2);
    ageGroup(ageS) = ai;
    ageLabs{ai} = sprintf('%i-%i',ageBins(ai,1),ageBins(ai,2)-1);
end
T.ageGroup = ageGroup;
%also a categorical variable for age group (for LMEs)
T.ageGroupLabel = ageLabs(T.ageGroup)';
