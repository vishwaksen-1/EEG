% clear; clc;
maxLag   = 1.8;

fileList = ["datanorm", "actnorm_faNmiss", "actnorm_hitNcr"];

for file = fileList
    % file = "passnorm" % Max lag for corr/auto corr
    saveFile = sprintf("%scorrAcrr_results.mat", file); % Output filename
    
    datanorm = load(sprintf("Datasets/%s.mat", file));
    
    datanorm = datanorm.(file);
    
    main_corrAcrr;
end
