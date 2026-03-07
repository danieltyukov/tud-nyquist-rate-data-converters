%% Homework 2 - Problem 1: Reconstruction (ZOH)
% ET4369 Nyquist Rate Data Converters
clear; close all; clc;

savedir = fileparts(mfilename('fullpath'));

%% Given parameters
fs = 125e6;          % Sampling frequency [Hz]
Ts = 1/fs;           % Sampling period [s] = 8 ns
Tp = [2e-9, 4e-9, 8e-9]; % Hold pulse widths [s]

%% Part (a): Plot amplitude envelopes for three hold pulse widths

f = linspace(0, 500e6, 10000); % Frequency axis up to 500 MHz

set(0, 'DefaultFigureColor', 'w');
set(0, 'DefaultAxesColor', 'w');
set(0, 'DefaultAxesXColor', 'k');
set(0, 'DefaultAxesYColor', 'k');
set(0, 'DefaultTextColor', 'k');

fig1 = figure('Position', [100 100 900 500], 'Color', 'w');
hold on; grid on;
colors = {'b', 'r', 'k'};
h = gobjects(1, length(Tp));

for k = 1:length(Tp)
    % Amplitude envelope: (Tp/Ts) * |sinc(f * Tp)|
    % sinc in MATLAB is sinc(x) = sin(pi*x)/(pi*x)
    envelope = (Tp(k)/Ts) * abs(sinc(f * Tp(k)));
    h(k) = plot(f/1e6, envelope, colors{k}, 'LineWidth', 1.5);
end

xlabel('Frequency [MHz]', 'FontSize', 12);
ylabel('Amplitude Envelope |H_p(f)| / A', 'FontSize', 12);
title('ZOH Reconstruction: Amplitude Envelope for Different Hold Pulse Widths', 'FontSize', 13);
lgd1 = legend(h, {'T_p = 2 ns', 'T_p = 4 ns', 'T_p = 8 ns'}, 'Location', 'northeast', 'FontSize', 11);
set(lgd1, 'Color', 'w', 'EdgeColor', 'k', 'TextColor', 'k');
xlim([0 500]);
ylim([0 1.1]);

% Mark fs and 2*fs
xline(fs/1e6, '--', 'f_s = 125 MHz', 'FontSize', 9, 'LabelOrientation', 'aligned', 'HandleVisibility', 'off');
xline(2*fs/1e6, '--', '2f_s = 250 MHz', 'FontSize', 9, 'LabelOrientation', 'aligned', 'HandleVisibility', 'off');

exportgraphics(fig1, fullfile(savedir, 'p1a_amplitude_envelopes.png'), 'BackgroundColor', 'white', 'Resolution', 150);
fprintf('Saved p1a_amplitude_envelopes.png\n');

%% Part (b): Tones up to 250 MHz for 8ns hold, 30 MHz sine input

fin = 30e6;        % Input frequency [Hz]
Tp_nrz = 8e-9;     % NRZ hold (Tp = Ts)

% Tones appear at |fin + k*fs| for all integers k
% Positive frequency tones up to 250 MHz:
%   k=0:  fin          = 30 MHz
%   k=-1: fs - fin     = 95 MHz  (from negative freq image folded)
%   k=1:  fs + fin     = 155 MHz
%   k=-2: 2*fs - fin   = 220 MHz
tones = [];
for k = -10:10
    f_tone = fin + k*fs;
    if abs(f_tone) <= 250e6 && abs(f_tone) > 0
        tones = [tones, abs(f_tone)];
    end
end
tones = unique(sort(tones));

fprintf('\nPart (b): Tones up to 250 MHz for T_p = 8 ns, f_in = 30 MHz\n');
fprintf('%-15s %-20s %-20s\n', 'Frequency', 'Norm. Amplitude', '|H(f)|/A');
fprintf('%-15s %-20s %-20s\n', '---------', '---------------', '--------');

tone_freqs = [];
tone_amps = [];

for i = 1:length(tones)
    f_t = tones(i);
    % Amplitude: (Tp/Ts) * |sinc(f * Tp)|
    amp = (Tp_nrz/Ts) * abs(sinc(f_t * Tp_nrz));
    tone_freqs = [tone_freqs, f_t];
    tone_amps = [tone_amps, amp];
    fprintf('%-15s %-20.6f %-20.6f\n', ...
        sprintf('%.0f MHz', f_t/1e6), amp, amp);
end

% Create figure for part (b)
fig2 = figure('Position', [100 100 900 500], 'Color', 'w');
hold on; grid on;

% Plot the sinc envelope
f_fine = linspace(0, 300e6, 10000);
envelope_nrz = abs(sinc(f_fine * Tp_nrz));
h_env = plot(f_fine/1e6, envelope_nrz, 'b-', 'LineWidth', 1.5);

% Plot the tones as stems
h_stem = stem(tone_freqs(1)/1e6, tone_amps(1), 'ro', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
for i = 2:length(tone_freqs)
    stem(tone_freqs(i)/1e6, tone_amps(i), 'ro', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
end
for i = 1:length(tone_freqs)
    text(tone_freqs(i)/1e6 + 3, tone_amps(i) + 0.02, ...
        sprintf('%.0f MHz\n%.4f', tone_freqs(i)/1e6, tone_amps(i)), ...
        'FontSize', 9, 'Color', 'r');
end

xlabel('Frequency [MHz]', 'FontSize', 12);
ylabel('Normalized Amplitude (to A)', 'FontSize', 12);
title('Output Spectrum Tones for T_p = 8 ns (NRZ), f_{in} = 30 MHz', 'FontSize', 13);
lgd2 = legend([h_env, h_stem], {'sinc envelope', 'Output tones'}, 'Location', 'northeast', 'FontSize', 11);
set(lgd2, 'Color', 'w', 'EdgeColor', 'k', 'TextColor', 'k');
xlim([0 260]);
ylim([0 1.1]);

xline(fs/1e6, 'k--', 'f_s', 'FontSize', 9, 'HandleVisibility', 'off');
xline(2*fs/1e6, 'k--', '2f_s', 'FontSize', 9, 'HandleVisibility', 'off');

exportgraphics(fig2, fullfile(savedir, 'p1b_output_tones.png'), 'BackgroundColor', 'white', 'Resolution', 150);
fprintf('\nSaved p1b_output_tones.png\n');

%% Print summary table
fprintf('\n=== SUMMARY: Part (b) ===\n');
fprintf('Hold pulse: T_p = 8 ns (NRZ, T_p = T_s)\n');
fprintf('Input: 30 MHz sine, amplitude A\n\n');
fprintf('  Tone [MHz]   Amplitude/A    Origin\n');
fprintf('  ----------   -----------    ------\n');
origins = {'f_{in}', 'f_s - f_{in}', 'f_s + f_{in}', '2f_s - f_{in}'};
for i = 1:length(tone_freqs)
    fprintf('  %10.0f   %11.6f    %s\n', tone_freqs(i)/1e6, tone_amps(i), origins{i});
end
