function rmsMat = rmser(data, length)
    if length == -1
        length = size(data, 1);
    end
    samples = round(length*256/1000);
    data_subset_squared = data(1:min(samples, end), :, :, :, :, :).^2;
    rmsMatt = sqrt(mean(data_subset_squared, 1, 'omitnan'));
    rmsMatt = mean(mean(rmsMatt, 4, 'omitnan'), 3, 'omitnan');
    rmsMat = squeeze(rmsMatt);
end