%% HW3 Problem 1: Spectral Performance Metrics
% 10-bit bipolar mid-rise ADC, fs = 100 MS/s, FSR = [-1, +1]

clear; close all; clc;

load('hw3_adc_out.mat');
x = adc_output_data_time_domain;
N = length(x);
B = 10;
FSR = 2;                % [-1, +1]
FS_amplitude = FSR/2;   % full-scale amplitude = 1

fprintf('=== Problem 1: Spectral Performance Metrics ===\n');
fprintf('Number of samples: %d\n', N);
fprintf('fs = %g MS/s\n', fs/1e6);
fprintf('Min = %g, Max = %g\n', min(x), max(x));

%% (a) Plot spectrum from 0 to fs/2 in dBFS vs MHz
X = fft(x);
X_one = X(1:N/2+1);          % one-sided
X_mag = abs(X_one) ./ (N/2);   % normalize amplitude (2/N for one-sided, but DC and Nyquist get 1/N)
X_mag(1) = X_mag(1)/2;         % DC bin correction
X_mag(end) = X_mag(end)/2;     % Nyquist bin correction

% dBFS: normalize to full-scale amplitude
X_dBFS = 20*log10(X_mag / FS_amplitude);

f_axis = (0:N/2) * fs / N;
f_MHz = f_axis / 1e6;

figure('Position', [100 100 900 500]);
plot(f_MHz, X_dBFS, 'b', 'LineWidth', 0.5);
xlabel('Frequency [MHz]');
ylabel('DFT Magnitude [dBFS]');
title(sprintf('%d-point FFT', N));
grid on;
xlim([0 fs/2/1e6]);
ylim([-140 10]);
set(gca, 'FontSize', 12);
exportgraphics(gcf, 'p1a_spectrum.png', 'Resolution', 200);
fprintf('\n(a) Spectrum plotted and saved to p1a_spectrum.png\n');

%% (b) Find input frequency
[sig_peak, sig_bin] = max(X_dBFS(2:end));
sig_bin = sig_bin + 1;  % offset for skipping DC
fin = f_axis(sig_bin);
fprintf('\n(b) Input frequency fin = %g MHz (bin %d)\n', fin/1e6, sig_bin-1);
fprintf('    Signal amplitude: %.2f dBFS\n', sig_peak);

%% (c) Compute SNR, SNDR, ENOB, THD, SFDR
% Power spectrum (one-sided, in linear power)
P = X_mag.^2;

% Signal power: sum over signal bin (and maybe +/-1 if leakage)
% Use just the signal bin for coherent sampling
P_signal = P(sig_bin);

% Find harmonics (2nd through 7th)
harm_bins = zeros(1, 6);
P_harm = zeros(1, 6);
for h = 2:7
    hbin = (sig_bin - 1) * h + 1;  % bin index (1-based)
    % Handle aliasing: if bin > N/2+1, fold back
    if hbin > N/2 + 1
        hbin = N + 2 - hbin;  % fold
    end
    if hbin < 1
        hbin = 2 - hbin;
    end
    harm_bins(h-1) = hbin;
    P_harm(h-1) = P(hbin);
    fprintf('    Harmonic %d: bin %d, freq %.2f MHz, level %.1f dBFS\n', ...
        h, hbin-1, f_axis(hbin)/1e6, 10*log10(P(hbin)/FS_amplitude^2));
end

% Total harmonic power
P_THD = sum(P_harm);

% Noise power: everything except DC, signal, and harmonics
noise_bins = true(size(P));
noise_bins(1) = false;              % exclude DC
noise_bins(sig_bin) = false;        % exclude signal
for h = 1:6
    noise_bins(harm_bins(h)) = false;  % exclude harmonics
end
P_noise = sum(P(noise_bins));

% SNR: signal power / noise power (noise only, no harmonics)
SNR_dB = 10*log10(P_signal / P_noise);

% SNDR: signal / (noise + distortion)
SNDR_dB = 10*log10(P_signal / (P_noise + P_THD));

% ENOB
ENOB = (SNDR_dB - 1.76) / 6.02;

% THD: harmonic power / signal power
THD_dB = 10*log10(P_THD / P_signal);

% SFDR: signal / largest spur (in dB)
[P_spur_max, spur_idx] = max([P_harm]);
SFDR_dB = 10*log10(P_signal / P_spur_max);
fprintf('\n(c) Performance Metrics:\n');
fprintf('    SNR   = %.2f dB\n', SNR_dB);
fprintf('    SNDR  = %.2f dB\n', SNDR_dB);
fprintf('    ENOB  = %.2f bits\n', ENOB);
fprintf('    THD   = %.2f dB\n', THD_dB);
fprintf('    SFDR  = %.2f dB\n', SFDR_dB);
fprintf('    Largest spur: Harmonic %d\n', spur_idx + 1);

%% (d) Which non-ideality determines SFDR?
fprintf('\n(d) SFDR-limiting non-ideality:\n');
fprintf('    The SFDR is determined by HD%d (harmonic %d).\n', spur_idx+1, spur_idx+1);
fprintf('    This is the largest spurious component in the spectrum.\n');

%% (e) Additional noise sources
% Ideal quantization noise floor for B-bit ADC with N-point FFT:
% SQNR_ideal = 6.02*B + 1.76 = %.2f dB
SQNR_ideal = 6.02*B + 1.76;
% Noise floor in dBFS for ideal quantizer:
% floor_ideal = -(SQNR_ideal) - 10*log10(N/2)
floor_ideal_dBFS = -(SQNR_ideal) - 10*log10(N/2);

% Measured noise floor: average power of noise bins
P_noise_avg = mean(P(noise_bins));
floor_measured_dBFS = 10*log10(P_noise_avg / FS_amplitude^2);

% Ideal quantization noise power (total)
Delta = FSR / 2^B;
P_quant_ideal = Delta^2 / 12;

fprintf('\n(e) Noise analysis:\n');
fprintf('    Ideal SQNR = %.2f dB\n', SQNR_ideal);
fprintf('    Ideal noise floor = %.2f dBFS\n', floor_ideal_dBFS);
fprintf('    Measured noise floor (avg bin) = %.2f dBFS\n', floor_measured_dBFS);
fprintf('    Difference = %.2f dB\n', floor_measured_dBFS - floor_ideal_dBFS);
fprintf('    Measured SNR = %.2f dB vs ideal SQNR = %.2f dB\n', SNR_dB, SQNR_ideal);

% If measured noise > quantization noise, there is extra noise
P_noise_total_measured = P_noise;
% Ideal total quantization noise power spread over N/2 bins (one-sided)
% For a full-scale sine: P_quant = Delta^2/12
% The total noise power from FFT should equal P_quant for ideal case
fprintf('    Ideal quantization noise power: %g\n', P_quant_ideal);
fprintf('    Measured total noise power: %g\n', P_noise_total_measured);
P_electronic = P_noise_total_measured - P_quant_ideal;
if P_electronic > 0
    fprintf('    Electronic noise power: %g\n', P_electronic);
    fprintf('    Ratio P_electronic/P_quant = %.2f (electronic noise is %.1f%% of quant noise)\n', ...
        P_electronic/P_quant_ideal, P_electronic/P_quant_ideal*100);
    fprintf('    => YES, there are additional noise sources.\n');
else
    fprintf('    => No significant additional noise sources detected.\n');
end

fprintf('\nDone.\n');
