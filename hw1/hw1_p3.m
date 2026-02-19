%% Homework 1 - Problem 3: Quantization Noise Power for Ramp Input
% ET4369 Nyquist Rate Data Converters
clear; close all; clc;

Delta = 1; % Step size (normalized to 1V)
B = 3;     % Number of bits
N_levels = 2^B; % 8 levels

%% =====================================================================
%  Part (a): Ideal 3-bit mid-tread quantizer
%  =====================================================================

% Ideal mid-tread quantizer: output levels at -4, -3, -2, -1, 0, 1, 2, 3
% Decision boundaries at: -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5
% Step at code k covers [(k-0.5)*Delta, (k+0.5)*Delta)
% Full input range: [-4.5, 3.5] (total = 8*Delta = FSR)

% Ramp input: from beginning to end of FSR
FSR = N_levels * Delta; % = 8
x_start = -4.5 * Delta;
x_end   =  3.5 * Delta;
N_pts = 100000;
t = linspace(0, 1, N_pts); % normalized time [0, 1] representing [0, t1]
x_ramp = x_start + (x_end - x_start) * t; % ramp from -4.5 to 3.5

% Ideal mid-tread quantizer function
ideal_levels = (-4:3) * Delta; % output levels
ideal_boundaries = (-3.5:1:2.5) * Delta; % decision boundaries

Q_ideal = zeros(size(x_ramp));
for i = 1:length(x_ramp)
    xv = x_ramp(i);
    if xv < ideal_boundaries(1)
        Q_ideal(i) = ideal_levels(1);
    elseif xv >= ideal_boundaries(end) + Delta
        Q_ideal(i) = ideal_levels(end);
    else
        idx = find(xv >= ideal_boundaries, 1, 'last');
        if isempty(idx)
            Q_ideal(i) = ideal_levels(1);
        else
            Q_ideal(i) = ideal_levels(idx + 1);
        end
    end
end

% Quantization error
e_ideal = Q_ideal - x_ramp;

% Noise power (mean square error)
P_noise_ideal = mean(e_ideal.^2);
fprintf('Part (a) - Ideal quantizer:\n');
fprintf('  Noise power (numerical) = %.6f\n', P_noise_ideal);
fprintf('  Delta^2/12              = %.6f\n', Delta^2/12);
fprintf('  Ratio to Delta^2/12    = %.4f\n', P_noise_ideal / (Delta^2/12));
fprintf('\n');

%% Plot Part (a): Ideal quantizer transfer characteristic
figure('Position', [100 100 900 400]);

% Transfer characteristic
subplot(1,2,1);
hold on; grid on;
x_plot = linspace(-5, 4.5, 10000);
Q_plot = zeros(size(x_plot));
for i = 1:length(x_plot)
    xv = x_plot(i);
    if xv < ideal_boundaries(1)
        Q_plot(i) = ideal_levels(1);
    elseif xv >= ideal_boundaries(end) + Delta
        Q_plot(i) = ideal_levels(end);
    else
        idx = find(xv >= ideal_boundaries, 1, 'last');
        if isempty(idx)
            Q_plot(i) = ideal_levels(1);
        else
            Q_plot(i) = ideal_levels(idx + 1);
        end
    end
end
plot(x_plot, Q_plot, 'b-', 'LineWidth', 2);
plot(x_plot, x_plot, 'k--', 'LineWidth', 0.5); % ideal line
% Mark FSR
plot([x_start x_start], [-5 4], 'r:', 'LineWidth', 0.5);
plot([x_end x_end], [-5 4], 'r:', 'LineWidth', 0.5);
xlabel('V_{in} [V]', 'FontSize', 12);
ylabel('D_{out}', 'FontSize', 12);
title('Ideal 3-bit Mid-Tread Quantizer', 'FontSize', 13);
xlim([-5 4.5]);
ylim([-5 4]);
set(gca, 'YTick', -4:1:3);
set(gca, 'XTick', -4.5:1:3.5);

% Quantization error vs time
subplot(1,2,2);
hold on; grid on;
plot(t, e_ideal, 'b-', 'LineWidth', 1.5);
plot([0 1], [Delta/2 Delta/2], 'r--', 'LineWidth', 0.5);
plot([0 1], [-Delta/2 -Delta/2], 'r--', 'LineWidth', 0.5);
xlabel('t / t_1', 'FontSize', 12);
ylabel('e(t) = Q(x) - x', 'FontSize', 12);
title(sprintf('Quantization Error (P_e = \\Delta^2/12 = %.4f)', P_noise_ideal), 'FontSize', 13);
ylim([-1 1]);

sgtitle('Problem 3(a): Ideal Quantizer with Ramp Input', 'FontSize', 14, 'FontWeight', 'bold');

% Save as PDF
exportgraphics(gcf, '/home/danieltyukov/workspace/tud/tud-nyquist-rate-data-converters/hw1/p3a_ideal_quantizer.pdf', 'ContentType', 'vector');
fprintf('Saved p3a_ideal_quantizer.pdf\n');

%% =====================================================================
%  Part (b): "Broken" quantizer (missing codes 0 and 1)
%  =====================================================================

% From the figure: the broken quantizer has:
% D_out = -4 for V_in in [-4.5, -3.5)  (width Delta)
% D_out = -3 for V_in in [-3.5, -2.5)  (width Delta)
% D_out = -2 for V_in in [-2.5, -1.5)  (width Delta)
% D_out = -1 for V_in in [-1.5, +1.5)  (width 3*Delta) <-- BROKEN: missing codes 0,1
% D_out = 2  for V_in in [+1.5, +2.5)  (width Delta)
% D_out = 3  for V_in in [+2.5, +3.5)  (width Delta)

broken_levels     = [-4, -3, -2, -1,  2,  3] * Delta;
broken_boundaries = [-3.5, -2.5, -1.5, 1.5, 2.5] * Delta;
% Transitions at: -3.5, -2.5, -1.5, +1.5, +2.5
% Note: transition from -1 to 2 happens at +1.5 (not at -0.5 and 0.5)

Q_broken = zeros(size(x_ramp));
for i = 1:length(x_ramp)
    xv = x_ramp(i);
    if xv < broken_boundaries(1)
        Q_broken(i) = broken_levels(1);     % -4
    elseif xv < broken_boundaries(2)
        Q_broken(i) = broken_levels(2);     % -3
    elseif xv < broken_boundaries(3)
        Q_broken(i) = broken_levels(3);     % -2
    elseif xv < broken_boundaries(4)
        Q_broken(i) = broken_levels(4);     % -1  (wide step)
    elseif xv < broken_boundaries(5)
        Q_broken(i) = broken_levels(5);     %  2
    else
        Q_broken(i) = broken_levels(6);     %  3
    end
end

% Quantization error
e_broken = Q_broken - x_ramp;

% Noise power
P_noise_broken = mean(e_broken.^2);
fprintf('Part (b) - Broken quantizer:\n');
fprintf('  Noise power (numerical)  = %.6f\n', P_noise_broken);
fprintf('  Analytical: 17*Delta^2/24 = %.6f\n', 17*Delta^2/24);
fprintf('  Delta^2/12               = %.6f\n', Delta^2/12);
fprintf('  Ratio to Delta^2/12     = %.4f\n', P_noise_broken / (Delta^2/12));
fprintf('\n');

%% Analytical verification for part (b)
% Normal steps (5 steps, each width Delta): integral of e^2 = Delta^3/12 each
% Wide step (width 3*Delta, output = -1):
%   e(x) = -1 - x for x in [-1.5, 1.5]
%   integral = integral of (-1-x)^2 from -1.5 to 1.5
%   = [x + x^2 + x^3/3] from -1.5 to 1.5
%   Let's compute:
int_normal = 5 * Delta^3 / 12;

syms xs
int_wide_sym = int((-1*Delta - xs)^2, xs, -1.5*Delta, 1.5*Delta);
int_wide = double(int_wide_sym);
fprintf('Analytical verification:\n');
fprintf('  Integral over 5 normal steps: %.6f\n', int_normal);
fprintf('  Integral over wide step:      %.6f\n', int_wide);
fprintf('  Total integral:               %.6f\n', int_normal + int_wide);
fprintf('  Noise power = total / FSR     = %.6f\n', (int_normal + int_wide) / FSR);
fprintf('  17*Delta^2/24                 = %.6f\n', 17*Delta^2/24);

%% Plot Part (b): Broken quantizer
figure('Position', [100 100 900 400]);

% Transfer characteristic
subplot(1,2,1);
hold on; grid on;
Q_plot_broken = zeros(size(x_plot));
for i = 1:length(x_plot)
    xv = x_plot(i);
    if xv < broken_boundaries(1)
        Q_plot_broken(i) = broken_levels(1);
    elseif xv < broken_boundaries(2)
        Q_plot_broken(i) = broken_levels(2);
    elseif xv < broken_boundaries(3)
        Q_plot_broken(i) = broken_levels(3);
    elseif xv < broken_boundaries(4)
        Q_plot_broken(i) = broken_levels(4);
    elseif xv < broken_boundaries(5)
        Q_plot_broken(i) = broken_levels(5);
    else
        Q_plot_broken(i) = broken_levels(6);
    end
end
plot(x_plot, Q_plot_broken, 'b-', 'LineWidth', 2);
plot(x_plot, x_plot, 'k--', 'LineWidth', 0.5); % ideal line
% Highlight the wide step
fill([-1.5 1.5 1.5 -1.5], [-1.2 -1.2 -0.8 -0.8], 'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
% Mark missing codes
text(0, 0, 'Missing code 0', 'Color', 'r', 'FontSize', 9, 'HorizontalAlignment', 'center');
text(0, 1, 'Missing code 1', 'Color', 'r', 'FontSize', 9, 'HorizontalAlignment', 'center');
xlabel('V_{in} [V]', 'FontSize', 12);
ylabel('D_{out}', 'FontSize', 12);
title('"Broken" Quantizer (Missing Codes 0, 1)', 'FontSize', 13);
xlim([-5 4.5]);
ylim([-5 4]);
set(gca, 'YTick', -4:1:3);

% Quantization error vs time
subplot(1,2,2);
hold on; grid on;
plot(t, e_broken, 'b-', 'LineWidth', 1.5);
plot([0 1], [Delta/2 Delta/2], 'r--', 'LineWidth', 0.5);
plot([0 1], [-Delta/2 -Delta/2], 'r--', 'LineWidth', 0.5);
xlabel('t / t_1', 'FontSize', 12);
ylabel('e(t) = Q(x) - x', 'FontSize', 12);
title(sprintf('Quantization Error (P_e = 17\\Delta^2/24 = %.4f)', P_noise_broken), 'FontSize', 13);
ylim([-3 1]);

sgtitle('Problem 3(b): Broken Quantizer with Ramp Input', 'FontSize', 14, 'FontWeight', 'bold');

% Save as PDF
exportgraphics(gcf, '/home/danieltyukov/workspace/tud/tud-nyquist-rate-data-converters/hw1/p3b_broken_quantizer.pdf', 'ContentType', 'vector');
fprintf('Saved p3b_broken_quantizer.pdf\n');

%% Combined figure for the report
figure('Position', [50 50 1000 800]);

% Part (a) - Error plot
subplot(2,2,1);
hold on; grid on;
plot(x_plot, Q_plot, 'b-', 'LineWidth', 2);
plot(x_plot, x_plot, 'k--', 'LineWidth', 0.5);
xlabel('V_{in} [V]', 'FontSize', 11);
ylabel('D_{out}', 'FontSize', 11);
title('(a) Ideal Quantizer Characteristic', 'FontSize', 12);
xlim([-5 4.5]); ylim([-5 4]);
set(gca, 'YTick', -4:1:3);

subplot(2,2,2);
hold on; grid on;
plot(t, e_ideal, 'b-', 'LineWidth', 1.5);
plot([0 1], [Delta/2 Delta/2], 'r--', 'LineWidth', 0.5);
plot([0 1], [-Delta/2 -Delta/2], 'r--', 'LineWidth', 0.5);
xlabel('t / t_1', 'FontSize', 11);
ylabel('e(t)', 'FontSize', 11);
title(sprintf('(a) Error: P_e = \\Delta^2/12 = %.4f', P_noise_ideal), 'FontSize', 12);
ylim([-1 1]);

% Part (b) - Error plot
subplot(2,2,3);
hold on; grid on;
plot(x_plot, Q_plot_broken, 'b-', 'LineWidth', 2);
plot(x_plot, x_plot, 'k--', 'LineWidth', 0.5);
fill([-1.5 1.5 1.5 -1.5], [-1.3 -1.3 -0.7 -0.7], 'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
text(0, 0.3, 'Missing 0,1', 'Color', 'r', 'FontSize', 9, 'HorizontalAlignment', 'center');
xlabel('V_{in} [V]', 'FontSize', 11);
ylabel('D_{out}', 'FontSize', 11);
title('(b) Broken Quantizer Characteristic', 'FontSize', 12);
xlim([-5 4.5]); ylim([-5 4]);
set(gca, 'YTick', -4:1:3);

subplot(2,2,4);
hold on; grid on;
plot(t, e_broken, 'b-', 'LineWidth', 1.5);
plot([0 1], [Delta/2 Delta/2], 'r--', 'LineWidth', 0.5);
plot([0 1], [-Delta/2 -Delta/2], 'r--', 'LineWidth', 0.5);
% Shade the region where error exceeds +/- Delta/2
idx_wide = (x_ramp >= -1.5*Delta) & (x_ramp < 1.5*Delta);
t_wide = t(idx_wide);
e_wide = e_broken(idx_wide);
fill([t_wide fliplr(t_wide)], [e_wide zeros(size(e_wide))], 'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel('t / t_1', 'FontSize', 11);
ylabel('e(t)', 'FontSize', 11);
title(sprintf('(b) Error: P_e = 17\\Delta^2/24 = %.4f', P_noise_broken), 'FontSize', 12);
ylim([-3 1]);

sgtitle('Problem 3: Quantization Noise Power for Ramp Input', 'FontSize', 14, 'FontWeight', 'bold');

exportgraphics(gcf, '/home/danieltyukov/workspace/tud/tud-nyquist-rate-data-converters/hw1/p3_combined.pdf', 'ContentType', 'vector');
fprintf('Saved p3_combined.pdf\n');

%% Annotated version of the homework figure for part (b)
figure('Position', [100 100 700 500]);
hold on; grid on;

% Plot the broken quantizer staircase (thick lines like in the homework)
% Draw horizontal segments for each step
steps_x = {[-4.5, -3.5], [-3.5, -2.5], [-2.5, -1.5], [-1.5, 1.5], [1.5, 2.5], [2.5, 3.5]};
steps_y = [-4, -3, -2, -1, 2, 3];

for k = 1:length(steps_y)
    % Horizontal line (step)
    plot(steps_x{k}, [steps_y(k) steps_y(k)], 'k-', 'LineWidth', 2.5);
    % Vertical riser (except for last step at right end)
    if k < length(steps_y)
        plot([steps_x{k}(2) steps_x{k}(2)], [steps_y(k) steps_y(k+1)], 'k-', 'LineWidth', 2.5);
    end
end

% Vertical lines at boundaries (dashed)
for xb = -4.5:1:4.5
    plot([xb xb], [-5 4], 'k:', 'LineWidth', 0.3);
end

% Diagonal reference line
plot([-5 5], [-5 5], 'k-', 'LineWidth', 0.5);

% Mark Delta
annotation('doublearrow', [0.19 0.255], [0.82 0.82], 'Color', 'k', 'LineWidth', 1);
text(-3.5, 3.3, '\Delta', 'FontSize', 14, 'HorizontalAlignment', 'center');

% FSR label
annotation('doublearrow', [0.19 0.83], [0.92 0.92], 'Color', 'k', 'LineWidth', 1);
text(-0.5, 4.2, 'FSR', 'FontSize', 14, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% Highlight the wide step in red
fill([-1.5 1.5 1.5 -1.5], [-1.3 -1.3 -0.7 -0.7], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'r', 'LineWidth', 1);
text(0, 0.5, {'Missing codes', '0 and 1'}, 'Color', 'r', 'FontSize', 11, ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% Arrow pointing to wide step
annotation('arrow', [0.5 0.5], [0.55 0.42], 'Color', 'r', 'LineWidth', 1.5);

% Labels
xlabel('V_{in} [V]', 'FontSize', 13);
ylabel('D_{out}', 'FontSize', 13);
title('Broken 3-bit Mid-Tread Quantizer (Annotated)', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YTick', -4:1:3);
set(gca, 'XTick', -4.5:1:4.5);
set(gca, 'XTickLabel', {'-4.5','-3.5','-2.5','-1.5','-0.5','+0.5','+1.5','+2.5','+3.5','+4.5'});
xlim([-5 4.5]);
ylim([-5 4.5]);

exportgraphics(gcf, '/home/danieltyukov/workspace/tud/tud-nyquist-rate-data-converters/hw1/p3b_annotated_figure.pdf', 'ContentType', 'vector');
fprintf('Saved p3b_annotated_figure.pdf\n');

fprintf('\n=== SUMMARY ===\n');
fprintf('Part (a): Ideal quantizer noise power    = Delta^2/12     = %.6f\n', Delta^2/12);
fprintf('Part (b): Broken quantizer noise power   = 17*Delta^2/24  = %.6f\n', 17*Delta^2/24);
fprintf('Ratio (broken/ideal)                     = %.1f\n', (17*Delta^2/24)/(Delta^2/12));
