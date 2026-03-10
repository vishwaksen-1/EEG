bands = {'delta', 'theta', 'alpha', 'beta', 'gamma'};

for b = 1:length(bands)
    band = bands{b};
    fields = fieldnames(BandPower.set1.act.stim1.(band));
    
    % Combine stim1 + stim3 and stim2 + stim4 for 'act' condition
    combo13_act = (struct2array(BandPower.set1.act.stim1.(band)) + struct2array(BandPower.set1.act.stim3.(band)) + ...
                   struct2array(BandPower.set2.act.stim1.(band)) + struct2array(BandPower.set2.act.stim3.(band))) / 2;
    combo24_act = (struct2array(BandPower.set1.act.stim2.(band)) + struct2array(BandPower.set1.act.stim4.(band)) + ...
                   struct2array(BandPower.set2.act.stim2.(band)) + struct2array(BandPower.set2.act.stim4.(band))) / 2;

    % Combine stim1 + stim3 and stim2 + stim4 for 'pass' condition
    combo13_pass = (struct2array(BandPower.set1.pass.stim1.(band)) + struct2array(BandPower.set1.pass.stim3.(band)) + ...
                    struct2array(BandPower.set2.pass.stim1.(band)) + struct2array(BandPower.set2.pass.stim3.(band))) / 2;
    combo24_pass = (struct2array(BandPower.set1.pass.stim2.(band)) + struct2array(BandPower.set1.pass.stim4.(band)) + ...
                    struct2array(BandPower.set2.pass.stim2.(band)) + struct2array(BandPower.set2.pass.stim4.(band))) / 2;

    figure('Name',['Band: ', upper(band)]);
    
    % Subplot 1: Combined Active
    subplot(2,1,1)
    plot(1:length(fields), combo13_act, '-o', 'DisplayName', 'Periodic Act'); hold on;
    plot(1:length(fields), combo24_act, '-x', 'DisplayName', 'Aperiodic Act');
    set(gca, 'xtick', 1:length(fields), 'xticklabel', fields);
    xlabel('Channels');
    ylabel([upper(band) ' Power']);
    title(['Set1 & Set2 (Periodic [Stim1+3], Aperiodic [Stim2+4]) ACTIVE: ', upper(band)]);
    xtickangle(45);
    legend('show');
    hold off;
    
    % Subplot 2: Combined Passive
    subplot(2,1,2)
    plot(1:length(fields), combo13_pass, '-o', 'DisplayName', 'Periodic Pass'); hold on;
    plot(1:length(fields), combo24_pass, '-x', 'DisplayName', 'Aperiodic Pass');
    set(gca, 'xtick', 1:length(fields), 'xticklabel', fields);
    xlabel('Channels');
    ylabel([upper(band) ' Power']);
    title(['Set1 & Set2 (Periodic [Stim1+3], Aperiodic [Stim2+4]) PASSIVE: ', upper(band)]);
    xtickangle(45);
    legend('show');
    hold off;
end
