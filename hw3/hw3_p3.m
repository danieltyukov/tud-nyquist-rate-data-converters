%% HW3 Problem 3: Relationship between INL and SFDR
% 11-bit ADC, full-scale sinusoidal input
% Spectrum given in the problem (65536-point FFT)
clear; clc;

fprintf('=== Problem 3: INL and SFDR ===\n\n');

B = 11;
N_fft = 65536;

%% (a) Estimate maximum INL (cubic bow)
% From the spectrum figure (page 2 of hw3 PDF):
%   - Signal at ~0 dBFS
%   - HD3 is the dominant spur at approximately -40 dBFS
%   - SFDR ~ 40 dB
%
% For a cubic INL (endpoint-corrected), the relationship is:
%   INL(x) = INL_max * (x^3 - x)  where x in [-1,1] (normalized code)
%   This produces HD3 in the output spectrum.
%
% The transfer function error:  e(x) = alpha3 * x^3
% For full-scale sine x = sin(wt):
%   y = sin(wt) + alpha3*sin^3(wt)
%     = (1 + 3/4*alpha3)*sin(wt) - (alpha3/4)*sin(3wt)
%   HD3 = alpha3/4
%
% Relating alpha3 to INL_max:
%   INL(x) = alpha3 * 2^(B-1) * (x^3 - x)   [in LSB]
%   max of |x^3 - x| at x = 1/sqrt(3): value = 2/(3*sqrt(3))
%   INL_max = alpha3 * 2^(B-1) * 2/(3*sqrt(3))
%   alpha3 = INL_max * 3*sqrt(3) / 2^B
%
% Therefore:
%   HD3 = alpha3/4 = INL_max * 3*sqrt(3) / (4 * 2^B)
%   SFDR (dBc) = -20*log10(HD3)
%        = 20*log10(4 * 2^B / (3*sqrt(3) * INL_max))
%
% Rearranging:
%   INL_max = 4 * 2^B / (3*sqrt(3) * 10^(SFDR/20))

fprintf('(a) Maximum INL estimation:\n');

% Read SFDR from spectrum figure
% The HD3 spur appears at approximately -40 dBFS
SFDR_read = 40;  % dB (estimated from figure)

INL_max = 4 * 2^B / (3*sqrt(3) * 10^(SFDR_read/20));

fprintf('    SFDR from spectrum (estimated) = %d dB\n', SFDR_read);
fprintf('    Using: INL_max = 4 * 2^B / (3*sqrt(3) * 10^(SFDR/20))\n');
fprintf('    INL_max = 4 * %d / (%.3f * %.2f) = %.1f LSB\n', ...
    2^B, 3*sqrt(3), 10^(SFDR_read/20), INL_max);

% Verify: check with simpler formula HD3 = pi*INL_max/2^B
% (alternative commonly used approximation)
INL_max_alt = 2^B * 10^(-SFDR_read/20) / pi;
fprintf('    Alternative (HD3 ~ pi*INL/2^B): INL_max = %.1f LSB\n', INL_max_alt);

%% (b) Electronic noise standard deviation
% Ideal quantization noise floor:
%   floor_ideal = -SQNR - 10*log10(N/2)  [dBFS]
%   SQNR = 6.02*B + 1.76 = 67.98 dB
%   floor_ideal = -67.98 - 10*log10(32768) = -67.98 - 45.15 = -113.13 dBFS
%
% Measured noise floor from spectrum: approximately -100 dBFS
%
% Total noise = quantization noise + electronic noise
% P_total/P_quant = 10^((floor_quant - floor_meas)/10)  (per-bin powers)
%
% sigma_e = sqrt(P_electronic) in LSB

fprintf('\n(b) Electronic noise estimation:\n');

SQNR_ideal = 6.02*B + 1.76;
floor_ideal = -SQNR_ideal - 10*log10(N_fft/2);

% Estimated from the spectrum figure
floor_measured = -100;  % dBFS (approximate reading from figure)

% Ratio of measured to ideal noise (per bin)
ratio = 10^((floor_measured - floor_ideal)/10);
fprintf('    Ideal SQNR = %.2f dB\n', SQNR_ideal);
fprintf('    Ideal noise floor = %.2f dBFS\n', floor_ideal);
fprintf('    Measured noise floor ~ %d dBFS (read from figure)\n', floor_measured);
fprintf('    P_total/P_quant ratio = %.2f\n', ratio);

% Electronic noise power = total - quantization
% P_elec = (ratio - 1) * P_quant
% P_quant = Delta^2/12
Delta = 2 / 2^B;  % LSB in volts (FSR = 2V for [-1,+1])
P_quant = Delta^2 / 12;
sigma_quant = Delta / sqrt(12);

P_total = ratio * P_quant;
P_elec = (ratio - 1) * P_quant;

sigma_elec_V = sqrt(P_elec);
sigma_elec_LSB = sigma_elec_V / Delta;

fprintf('    Delta (1 LSB) = %.6f V\n', Delta);
fprintf('    sigma_quant = Delta/sqrt(12) = %.6f V = %.4f LSB\n', sigma_quant, sigma_quant/Delta);
fprintf('    P_electronic/P_quant = %.2f\n', (ratio-1));
fprintf('    sigma_electronic = %.4f LSB = %.2f uV\n', sigma_elec_LSB, sigma_elec_V*1e6);
fprintf('    => Electronic noise is about %.1fx the quantization noise power\n', ratio-1);

%% (c) Effective number of bits
% ENOB = (SNDR - 1.76) / 6.02
% SNDR accounts for both noise and distortion

fprintf('\n(c) Effective number of bits:\n');

% Total noise power (quantization + electronic)
P_noise_total = P_total;

% Distortion power (dominated by HD3)
HD3_power = 10^(-SFDR_read/10);  % relative to signal
% Signal power for full-scale sine: A^2/2 where A = FS_amplitude
A = 1;  % full-scale amplitude
P_signal = A^2 / 2;

P_distortion = HD3_power * P_signal;

SNDR = 10*log10(P_signal / (P_noise_total + P_distortion));
ENOB = (SNDR - 1.76) / 6.02;

fprintf('    P_signal = %.4f\n', P_signal);
fprintf('    P_noise_total = %.2e\n', P_noise_total);
fprintf('    P_distortion (HD3) = %.2e\n', P_distortion);
fprintf('    SNDR = %.2f dB\n', SNDR);
fprintf('    ENOB = %.2f bits\n', ENOB);

%% (d) INL-SFDR relationship in commercial product
% Paper: Lee et al., 10-bit 205-MS/s Pipeline ADC
% Fig. 14(b): INL shows cubic nonlinearity with INL = +/- 0.9 LSB
% Use smooth average amplitude to estimate SFDR

fprintf('\n(d) Commercial product INL-SFDR analysis:\n');

B_paper = 10;
INL_smooth = 0.9;  % LSB (from Fig. 14(b), smooth average amplitude)

% SFDR from cubic INL:
% HD3 = INL_max * 3*sqrt(3) / (4 * 2^B)
HD3_paper = INL_smooth * 3*sqrt(3) / (4 * 2^B_paper);
SFDR_from_INL = -20*log10(HD3_paper);

fprintf('    B = %d bits, INL_max (smooth) = %.1f LSB\n', B_paper, INL_smooth);
fprintf('    HD3 = %.1f * %.4f / (4 * %d) = %.6f\n', ...
    INL_smooth, 3*sqrt(3), 2^B_paper, HD3_paper);
fprintf('    SFDR_estimated = -20*log10(%.6f) = %.1f dB\n', HD3_paper, SFDR_from_INL);

% From Fig. 10(b): SFDR vs input frequency at 205 MS/s, 1.0-Vpp single-ended
% At fin = 70 MHz: SFDR ~ 62 dBc (reading from curve)
% From Fig. 11(d): at fin = 79 MHz, SFDR = 61.8 dBc (explicitly labeled)
% From Fig. 14(a): differential input: DNL = +/- 0.5 LSB, INL = +/- 0.5 LSB
% From Fig. 14(b): single-ended input: INL = +/- 0.9 LSB (cubic bow)
SFDR_specified = 62;  % dBc (typical around 70 MHz, from Fig. 10(b))
fprintf('    SFDR_specified (typical, ~70 MHz, Fig. 10(b)) ~ %d dBc\n', SFDR_specified);
fprintf('    Difference = %.1f dB\n', abs(SFDR_from_INL - SFDR_specified));
fprintf('    The estimated SFDR from INL is in reasonable agreement\n');
fprintf('    with the specified value.\n');

fprintf('\nDone.\n');
