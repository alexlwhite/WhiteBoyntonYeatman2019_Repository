taskLevel=[];
question = sprintf('Enter a single intensity level as the threshold estimate\n\t');
ncin = 1;
gotCs = false;
while ~gotCs
    threshC = input(question);
    gotCs = all(isfloat(threshC)) && (numel(threshC)==ncin);
end
