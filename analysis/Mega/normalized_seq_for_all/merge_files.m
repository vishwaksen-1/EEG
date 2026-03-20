% Script to merge data files of two sets

load set1_active.mat
s1 = data;
load set2_active.mat
s2 = data;
data = cat(1, s1, s2);
save active.mat data

load set1_passive.mat
s1 = data;
load set2_passive.mat
s2 = data;
data = cat(1, s1, s2);
save passive.mat data

load t_set1_active.mat
s1 = data;
load t_set2_active.mat
s2 = data;
data = cat(1, s1, s2);
save t_active.mat data
