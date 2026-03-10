% load('AllSubjects_AllSegments_withTime.mat')
 S = numel(allSubjectsData);                              % subjects
% Infer channels (Ch) and canonical datapoints (N) from avgSegment
nCh =14;
N   = size(data(1).avgSegment, 2);
Tmax=10;
X = nan(S, Tmax, nCh, N, 'like', allSubjectsData(1).avgSegment);
fs=256;

for s = 1:S
    ts = allSubjectsData(s).trialSegments;      % 1xT cell
    T  = numel(ts);
    for t = 1:T
        M = ts{t};

        if size(M,1) == nCh
            A = M;
        elseif size(M,2) == nCh
            A = M.';                            % transpose to [Ch x Time]
        else
            error('Subject %d trial %d has unexpected size [%d x %d].', ...
                  s, t, size(M,1), size(M,2));
        end

        At = nan(nCh, N, 'like', A);
        Nt = min(N, size(A,2));
        At(:, 1:Nt) = A(:, 1:Nt);

        % Drop into X (S x T x Ch x N)
        X(s, t, :, :) = At;
    end
end
plot_visual_eeg(X,256);
plot_visual_eeg_avg_allsub(X,256);
%% to [;ot average of all subjects 


%% for segmentation 


segment_into_2s_V(X,256) ;


