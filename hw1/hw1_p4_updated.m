clear;close all;clc;

savedir = fileparts(mfilename('fullpath'));

% Test signals
pts = 1e4;
x = zeros(pts, 4);

% Sinusoidal test signal x(:, 1)
A = 1;
x(:, 1) = A*cos(2*pi*67/2048*(0:pts-1));

% Sinusoid power: P_sin = A^2/2 = 0.5
P_sin = A^2/2;

% Random test signal x(:, 2) requirements:
% 1. Samples are I.I.D. uniform with zero mean
% 2. Expected instantaneous power of x(:, 2) equals
%    time averaged power of x(:, 1)
% Uniform in [-a, a]: E[x^2] = a^2/3 = P_sin => a = sqrt(3*P_sin)
a_unif = sqrt(3*P_sin);
x(:, 2) = a_unif * (2*rand(pts, 1) - 1);

% Random test signal x(:, 3) requirements:
% 1. Samples are I.I.D. Gaussian with zero mean
% 2. Expected instantaneous power of x(:, 3) equals
%    time averaged power of x(:, 1)
% Gaussian N(0,sigma): E[x^2] = sigma^2 = P_sin => sigma = sqrt(P_sin)
sigma_gauss = sqrt(P_sin);
x(:, 3) = sigma_gauss * randn(pts, 1);

% Random test signal x(:, 4) requirements:
% 1. Samples are I.I.D. and drawn from half-wave Gaussian distribution
% 2. Expected instantaneous power of x(:, 4) equals
%    time averaged power of x(:, 1)
% Half-wave (ReLU) Gaussian: X = max(N(0,sigma_hw), 0)
% E[X^2] = sigma_hw^2/2 = P_sin => sigma_hw = sqrt(2*P_sin)
sigma_hw = sqrt(2*P_sin);
x(:, 4) = max(sigma_hw * randn(pts, 1), 0);

% Sweep resolution
B = 4:10;
% Sweep FSR
FSR = A*logspace(-1, 5, 1000);
% Calculate SQNR for all test signals
SQNR = zeros(length(B), length(FSR), size(x, 2));

% Sweep resolution and FSR
for i = 1:length(B)
    for j = 1:length(FSR)
        % Output signals
        % x(:, 1) -> bipolar mid-rise -> y(:, 1)
        % x(:, 2) -> bipolar mid-rise -> y(:, 2)
        % x(:, 3) -> bipolar mid-rise -> y(:, 3)
        % x(:, 4) -> bipolar mid-rise -> y(:, 4)
        y(:, 1) = quantize_bipolar_midrise(x(:, 1), FSR(j), B(i));
        y(:, 2) = quantize_bipolar_midrise(x(:, 2), FSR(j), B(i));
        y(:, 3) = quantize_bipolar_midrise(x(:, 3), FSR(j), B(i));
        y(:, 4) = quantize_bipolar_midrise(x(:, 4), FSR(j), B(i));

        eq = y - x;
        SQNR(i, j, :) = 10*log10(std(x, 0, 1).^2./std(eq, 0, 1).^2);
    end
end

% Loading factor: LF = (FSR/2) / x_rms, where x_rms = A/sqrt(2) for sine
LF = FSR/2/(A/sqrt(2));

%% --- Figure 1: SQNR vs Loading Factor for B = 10 ---
fig1 = figure('Position', [100 100 800 500]);
semilogx(LF, squeeze(SQNR(B == 10, :, :)), 'LineWidth', 1.5);
grid on;
xlabel('Loading Factor (FSR/2) / x_{rms}');
ylabel('SQNR [dB]');
title('Range-Precision Trade-Off for B = 10');
legend({'Sinusoidal', 'Uniform', 'Gaussian', 'ReLU Gaussian'}, ...
       'Location', 'best');
saveas(fig1, fullfile(savedir, 'p4_sqnr_vs_lf_B10.png'));

%% --- Figure 2: SQNR vs Loading Factor for all B (sinusoidal only) ---
fig2 = figure('Position', [100 100 800 500]);
colors = lines(length(B));
legendstr = cell(1, length(B));
for i = 1:length(B)
    semilogx(LF, squeeze(SQNR(i, :, 1)), 'LineWidth', 1.5, 'Color', colors(i,:));
    hold on;
    legendstr{i} = sprintf('B = %d', B(i));
end
grid on;
xlabel('Loading Factor (FSR/2) / x_{rms}');
ylabel('SQNR [dB]');
title('SQNR vs Loading Factor -- Sinusoidal Input');
legend(legendstr, 'Location', 'best');
saveas(fig2, fullfile(savedir, 'p4_sqnr_vs_lf_allB_sine.png'));

%% --- Figure 3: Optimal SQNR and Loading Factor vs B ---
[SQNR_opt, idx_opt] = max(SQNR, [], 2);
SQNR_opt = squeeze(SQNR_opt);
LF_opt = squeeze(LF(idx_opt));

fig3 = figure('Position', [100 100 800 500]);
subplot(1,2,1);
plot(B, SQNR_opt, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6);
grid on;
xlabel('Resolution B [bits]');
ylabel('Optimal SQNR [dB]');
title('Optimal SQNR vs Resolution');
legend({'Sinusoidal', 'Uniform', 'Gaussian', 'ReLU Gaussian'}, ...
       'Location', 'best');

subplot(1,2,2);
plot(B, LF_opt, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6);
grid on;
xlabel('Resolution B [bits]');
ylabel('Optimal Loading Factor');
title('Optimal Loading Factor vs Resolution');
legend({'Sinusoidal', 'Uniform', 'Gaussian', 'ReLU Gaussian'}, ...
       'Location', 'best');
saveas(fig3, fullfile(savedir, 'p4_optimal_sqnr_and_lf.png'));

%% --- Print summary table ---
fprintf('\n=== Optimal SQNR [dB] ===\n');
fprintf('  B   Sine    Uniform  Gaussian  ReLU-Gauss\n');
for i = 1:length(B)
    fprintf(' %2d  %6.2f   %6.2f   %6.2f    %6.2f\n', ...
        B(i), SQNR_opt(i,1), SQNR_opt(i,2), SQNR_opt(i,3), SQNR_opt(i,4));
end

fprintf('\n=== Optimal Loading Factor ===\n');
fprintf('  B   Sine    Uniform  Gaussian  ReLU-Gauss\n');
for i = 1:length(B)
    fprintf(' %2d  %6.2f   %6.2f   %6.2f    %6.2f\n', ...
        B(i), LF_opt(i,1), LF_opt(i,2), LF_opt(i,3), LF_opt(i,4));
end

fprintf('\nPlots saved to: %s\n', savedir);
