
clear
load('Visual_segmented_data.mat')
nsub = length(data);

% Get dimensions from first subject to pre-allocate X
first_subject = cell2mat(data(1));
[nchannels, nsamples, ntrials] = size(first_subject);
ntrials_to_use = min(ntrials, 10); % Use up to 10 trials

X = zeros(nsub, nchannels, nsamples, ntrials_to_use);

for i=1:nsub
    xx = cell2mat(data(i));
    % Handle potential size mismatches by taking minimum dimensions
    current_samples = min(size(xx,2), nsamples);
    current_trials = min(size(xx,3), ntrials_to_use);
    X(i, :, 1:current_samples, 1:current_trials) = xx(:, 1:current_samples, 1:current_trials);
end

% Transform format from subjects*channels*samples*trials to subjects*trials*channels*datapoints
% Current: X(subjects, channels, samples, trials)
% Desired: X(subjects, trials, channels, samples)
X = permute(X, [1, 4, 2, 3]);

