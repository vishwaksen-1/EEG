function [MI_vals, lags] = MIcorr(X, Y, k, maxLag)
% MIcorr - Mutual Information as a function of lag (KNN-based)
%
% Usage:
%   [MI_vals, lags] = MIcorr(X, Y, k, maxLag)
%   [MI_vals, lags] = MIcorr(X, [], k, maxLag)   % auto-MI (self)
%
% Inputs:
%   X, Y     : Input signals (column or row vectors)
%   k        : Number of neighbors for MI_KNN_cont_cont
%   maxLag   : Maximum lag (positive integer)
%
% Outputs:
%   MI_vals  : Normalized mutual information across lags
%   lags     : Lag vector (-maxLag:maxLag)
%
% Notes:
%   - Auto-MI normalized by entropy H(X)
%   - Cross-MI normalized by MI(X,Y) at zero lag
%   - Positive lag means Y is delayed relative to X
%
% Example:
%   x = randn(1000,1);
%   y = circshift(x, 10) + 0.2*randn(1000,1);
%   [MI_vals, lags] = MIcorr(x, y, 5, 50);
%   plot(lags, MI_vals), xlabel('Lag'), ylabel('Normalized MI')

    % --- Handle auto-MI case ---
    if nargin < 2 || isempty(Y)
        Y = X;
        autoMI = true;
    else
        autoMI = false;
    end
    if nargin < 3 || isempty(k)
        k = 3;
    end
    if nargin < 4 || isempty(maxLag)
        maxLag = floor(length(X)/4);
    end

    % --- Ensure column vectors ---
    X = X(:);
    Y = Y(:);
    N = length(X);

    % --- Setup ---
    lags = -maxLag:maxLag;
    MI_vals = nan(size(lags));

    % --- Loop over lags ---
    for idx = 1:length(lags)
        lag = lags(idx);

        if lag > 0
            Xs = X(1:end-lag);
            Ys = Y(1+lag:end);
        elseif lag < 0
            Xs = X(1-lag:end);
            Ys = Y(1:end+lag);
        else
            Xs = X;
            Ys = Y;
        end

        % Skip if too short
        if length(Xs) < k + 2
            MI_vals(idx) = NaN;
            continue;
        end

        try
            MI_vals(idx) = MI_KNN_cont_cont(Xs, Ys, k);
        catch
            MI_vals(idx) = NaN;
        end
    end

    % --- Normalization ---
    % if autoMI
    %     % Entropy H(X) = MI(X, X) at zero lag (conceptually same as self-MI)
    %     Hx = MI_vals(lags == 0);
    %     if Hx > 0
    %         MI_vals = MI_vals / Hx;
    %     end
    % else
    %     % Normalize by zero-lag cross MI
    %     M0 = MI_vals(lags == 0);
    %     if M0 > 0
    %         MI_vals = MI_vals / M0;
    %     end
    % end
end
