%% Homework 2 - Problem 3: DAC Area Optimization
% ET4369 Nyquist Rate Data Converters
clear; close all; clc;

savedir = fileparts(mfilename('fullpath'));

% Force light color scheme
try
    s = settings;
    s.matlab.appearance.figure.GraphicsTheme.TemporaryValue = 'light';
catch
end
set(0, 'DefaultFigureColor', 'w');
set(0, 'DefaultAxesColor', 'w');
set(0, 'DefaultAxesXColor', 'k');
set(0, 'DefaultAxesYColor', 'k');
set(0, 'DefaultTextColor', 'k');

%% Given parameters
B = 12;             % Total resolution [bits]
DNLspec = 0.5;      % Worst case DNL spec [LSB]
INLspec = 0.5;      % Worst case INL spec [LSB]
ku = 6e-2;          % Matching parameter [um] (6% um)
Adecode_unit = 2000; % Decode area per thermometer element [um^2]

%% Sweep across integer Bt values
Bt_range = 0:B;
Aunit_dnl = zeros(size(Bt_range));
Aunit_inl = zeros(size(Bt_range));
Aunit = zeros(size(Bt_range));
A_analog = zeros(size(Bt_range));
A_digital = zeros(size(Bt_range));
A_total = zeros(size(Bt_range));

% INL constraint (independent of Bt):
%   sigma_INL_max = 0.5 * sqrt(2^B) * sigma_u <= INLspec
%   sigma_u <= INLspec / (0.5 * sqrt(2^B))
sigma_u_inl = INLspec / (0.5 * sqrt(2^B));
Aunit_inl_fixed = (ku / sigma_u_inl)^2;

fprintf('INL constraint: sigma_u <= %.6f, Aunit_INL = %.4f um^2\n\n', ...
    sigma_u_inl, Aunit_inl_fixed);

fprintf('%-4s %-4s %-12s %-12s %-12s %-14s %-14s %-14s\n', ...
    'Bt', 'Bb', 'Aunit_DNL', 'Aunit_INL', 'Aunit', 'A_analog', 'A_digital', 'A_total');
fprintf('%s\n', repmat('-', 1, 90));

for idx = 1:length(Bt_range)
    Bt = Bt_range(idx);
    Bb = B - Bt;

    % DNL constraint:
    %   sigma_DNL_max = sqrt(n_dnl) * sigma_u <= DNLspec
    % where n_dnl = number of unit elements involved in worst-case transition
    if Bt == 0
        % Pure binary: worst carry at MSB transition
        % MSB = 2^(B-1) units ON, lower bits = 2^(B-1)-1 units OFF
        n_dnl = 2^B - 1;
    else
        % Segmented: major carry between binary and thermometer
        % Therm element = 2^Bb units ON, binary full scale = 2^Bb - 1 OFF
        n_dnl = 2^(Bb+1) - 1;
    end

    sigma_u_dnl = DNLspec / sqrt(n_dnl);
    Aunit_dnl(idx) = (ku / sigma_u_dnl)^2;
    Aunit_inl(idx) = Aunit_inl_fixed;

    % Take the tighter constraint (larger Aunit)
    Aunit(idx) = max(Aunit_dnl(idx), Aunit_inl(idx));

    % Compute areas
    A_analog(idx) = 2^B * Aunit(idx);          % [um^2]
    A_digital(idx) = 2^Bt * Adecode_unit;       % [um^2]
    A_total(idx) = A_analog(idx) + A_digital(idx);

    % Determine which constraint is active
    if Aunit_dnl(idx) > Aunit_inl(idx)
        active = 'DNL';
    elseif Aunit_dnl(idx) < Aunit_inl(idx)
        active = 'INL';
    else
        active = 'BOTH';
    end

    fprintf('%-4d %-4d %-12.4f %-12.4f %-12.4f %-14.1f %-14.1f %-14.1f  [%s]\n', ...
        Bt, Bb, Aunit_dnl(idx), Aunit_inl(idx), Aunit(idx), ...
        A_analog(idx), A_digital(idx), A_total(idx), active);
end

%% Find minimum area design
[min_area, min_idx] = min(A_total);
Bt_min = Bt_range(min_idx);
Bb_min = B - Bt_min;
Aunit_min = Aunit(min_idx);

fprintf('\n=== MINIMUM AREA DESIGN (Part a-i) ===\n');
fprintf('Bt = %d, Bb = %d\n', Bt_min, Bb_min);
fprintf('Aunit = %.4f um^2\n', Aunit_min);
fprintf('A_analog = %.1f um^2 = %.6f mm^2\n', A_analog(min_idx), A_analog(min_idx)/1e6);
fprintf('A_digital = %.1f um^2 = %.6f mm^2\n', A_digital(min_idx), A_digital(min_idx)/1e6);
fprintf('A_total = %.1f um^2 = %.6f mm^2\n', min_area, min_area/1e6);

%% Find optimal point (analog area = digital area)
% For Bt >= 3 (INL dominates), analog area is fixed at 2^B * Aunit_INL
% Digital area = 2^Bt * 2000
% Set equal: 2^Bt * 2000 = 2^B * Aunit_INL
% 2^Bt = 2^B * Aunit_INL / 2000
Bt_exact = log2(2^B * Aunit_inl_fixed / Adecode_unit);
fprintf('\n=== OPTIMAL POINT (Part a-ii) ===\n');
fprintf('Exact Bt for analog = digital: %.3f\n', Bt_exact);

% Check nearest integers
Bt_opt_candidates = [floor(Bt_exact), ceil(Bt_exact)];
fprintf('Nearest integer candidates: Bt = %d and Bt = %d\n', ...
    Bt_opt_candidates(1), Bt_opt_candidates(2));

for Bt_opt = Bt_opt_candidates
    idx_opt = Bt_opt + 1; % 0-indexed to 1-indexed
    ratio = A_analog(idx_opt) / A_digital(idx_opt);
    fprintf('  Bt = %d: A_analog = %.0f, A_digital = %.0f, ratio = %.3f, A_total = %.0f um^2 = %.4f mm^2\n', ...
        Bt_opt, A_analog(idx_opt), A_digital(idx_opt), ratio, A_total(idx_opt), A_total(idx_opt)/1e6);
end

% Select the one closest to ratio = 1
ratios = zeros(size(Bt_opt_candidates));
for i = 1:length(Bt_opt_candidates)
    idx_opt = Bt_opt_candidates(i) + 1;
    ratios(i) = abs(log(A_analog(idx_opt) / A_digital(idx_opt)));
end
[~, best] = min(ratios);
Bt_optimal = Bt_opt_candidates(best);
idx_optimal = Bt_optimal + 1;
fprintf('\nOptimal point: Bt = %d (closest to analog = digital)\n', Bt_optimal);
fprintf('A_total = %.1f um^2 = %.4f mm^2\n', A_total(idx_optimal), A_total(idx_optimal)/1e6);

%% Part (b): Create plot similar to Fig. 9
fig1 = figure('Position', [100 100 900 600], 'Color', 'w');

% Compute DNL-only analog area and INL-only analog area for all Bt
A_analog_dnl = 2^B * Aunit_dnl;
A_analog_inl = 2^B * Aunit_inl;

% Plot on semilogy
semilogy(Bt_range, A_total/1e6, 'k-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'k');
hold on; grid on;
semilogy(Bt_range, A_analog/1e6, 'b-s', 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
semilogy(Bt_range, A_digital/1e6, 'r-^', 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
semilogy(Bt_range, A_analog_dnl/1e6, 'b--', 'LineWidth', 1, 'HandleVisibility', 'off');
semilogy(Bt_range, A_analog_inl/1e6, 'b:', 'LineWidth', 1, 'HandleVisibility', 'off');

% Mark minimum area point
semilogy(Bt_min, min_area/1e6, 'gp', 'MarkerSize', 18, 'MarkerFaceColor', 'g', 'LineWidth', 1.5);
text(Bt_min + 0.3, min_area/1e6, sprintf('Min area\nB_t=%d, %.4f mm^2', Bt_min, min_area/1e6), ...
    'FontSize', 10, 'Color', [0 0.5 0]);

% Mark optimal point
semilogy(Bt_optimal, A_total(idx_optimal)/1e6, 'mp', 'MarkerSize', 18, 'MarkerFaceColor', 'm', 'LineWidth', 1.5);
text(Bt_optimal + 0.3, A_total(idx_optimal)/1e6, ...
    sprintf('Optimal point\nB_t=%d, %.4f mm^2', Bt_optimal, A_total(idx_optimal)/1e6), ...
    'FontSize', 10, 'Color', 'm');

% Labels for DNL/INL constraint lines
text(0.5, A_analog_dnl(1)/1e6 * 1.3, 'A_{DNL}', 'FontSize', 9, 'Color', 'b');
text(8, Aunit_inl_fixed * 2^B / 1e6 * 0.7, 'A_{INL}', 'FontSize', 9, 'Color', 'b');

xlabel('B_t (thermometer bits)', 'FontSize', 13);
ylabel('Total DAC Area [mm^2]', 'FontSize', 13);
title(sprintf('DAC Area vs Segmentation (B=%d, k_u=%.0f%%\\mum, DNL/INL<%.1f LSB)', ...
    B, ku*100, DNLspec), 'FontSize', 13);
xlim([-0.5 12.5]);
set(gca, 'XTick', 0:12);
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');

lgd = legend({'A_{total}', 'A_{analog} (dominant constraint)', 'A_{digital}', ...
    'Minimum area', 'Optimal point'}, 'Location', 'northeast', 'FontSize', 10);
set(lgd, 'Color', 'w', 'EdgeColor', 'k', 'TextColor', 'k');

exportgraphics(fig1, fullfile(savedir, 'p3b_area_vs_segmentation.png'), ...
    'BackgroundColor', 'white', 'Resolution', 150);
fprintf('\nSaved p3b_area_vs_segmentation.png\n');
