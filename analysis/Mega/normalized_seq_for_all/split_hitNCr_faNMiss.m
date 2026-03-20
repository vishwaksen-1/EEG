% Assume variable `data` is already loaded (25x1 cell, each cell = 1x7 cell)
% `data` is from t_active
load('t_active.mat')
n = numel(data);
dataC = cell(n,1);
dataW = cell(n,1);

for i = 1:n
    current = data{i};   % 1x7 cell

    % dataC: elements 1,2,3,4,6
    dataC{i} = current([1 2 3 4 6]);


    % dataW: elements 1,2,3,5,6
    dataW{i} = current([1 2 3 5 6]);
end

data = dataC;
save active_hitNCr data

data = dataW;
save active_faNMiss data
