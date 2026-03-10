set=1;
for s=1:size(final_t_act_faNmiss,1)
    data = final_t_act_faNmiss{s, set}{1,4};  % size = 1664×14×4×10
for stim=1:4
    for t = 1:size(data,4)
    trialData = data(:,:,stim,t);
    if all(trialData(:) == 0)
        data(:,:,stim,t) = NaN;   % Replace entire trial with NaN
    end
    end
end
final_t_act_faNmiss{s, set}{1,4}=data;
end


 %%%%%%%%%%%%%


% for final_t_act_hitNcr
set=1;
for s=1:size(final_t_act_hitNcr,1)
    data = final_t_act_hitNcr{s, set}{1,4};  % size = 1664×14×4×10
for stim=1:4
    for t = 1:size(data,4)
    trialData = data(:,:,stim,t);
    if all(trialData(:) == 0)
        data(:,:,stim,t) = NaN;   % Replace entire trial with NaN
    end
    end
end
final_t_act_hitNcr{s, set}{1,4}=data;
end


