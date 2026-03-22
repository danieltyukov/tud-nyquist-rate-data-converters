%% HW3 Problem 5: Boxcar Sampling
% HermesE paper: derive eq. (2) and verify 3.4x ENBW advantage
clear; clc;

fprintf('=== Problem 5: Boxcar Sampling ===\n\n');

%% (h) Derivation of Equation (2)
fprintf('(h) Derivation of Equation (2):\n\n');
fprintf('    From the paper, Eq. (1):\n');
fprintf('       Q_{in2,CT}(t) = integral from (t - D*Ts) to t of I_{out1d}(t'') dt''\n\n');
fprintf('    This is a convolution of I_{out1d}(t) with a rectangular window:\n');
fprintf('       h(tau) = 1  for  0 <= tau <= D*Ts\n');
fprintf('       h(tau) = 0  otherwise\n\n');
fprintf('    Taking the Fourier transform of h(tau):\n');
fprintf('       H(w) = integral_0^{D*Ts} e^{-jw*tau} dtau\n');
fprintf('            = [e^{-jw*tau} / (-jw)]_0^{D*Ts}\n');
fprintf('            = (1 - e^{-jw*D*Ts}) / (jw)\n\n');
fprintf('    Factor out e^{-jw*D*Ts/2}:\n');
fprintf('       H(w) = e^{-jw*D*Ts/2} * (e^{jw*D*Ts/2} - e^{-jw*D*Ts/2}) / (jw)\n');
fprintf('            = e^{-jw*D*Ts/2} * 2*sin(w*D*Ts/2) / w\n\n');
fprintf('    Taking the magnitude:\n');
fprintf('       |H(w)| = 2|sin(w*D*Ts/2)| / w\n\n');
fprintf('    Since Q_{in2,CT}(w) = I_{out1d}(w) * H(w):\n');
fprintf('       |Q_{in2,CT}(w)| / |I_{out1d}(w)| = 2|sin(w*D*Ts/2)| / w   [QED]\n\n');

%% (i) Verify 3.4x ENBW advantage
fprintf('(i) Verifying the 3.4x ENBW advantage:\n\n');

% Boxcar (sinc) prefilter ENBW:
% |H(f)|^2 = (D*Ts)^2 * sinc^2(f*D*Ts)
% |H(0)|^2 = (D*Ts)^2
% ENBW = (1/|H(0)|^2) * integral_0^inf |H(f)|^2 df
%      = integral_0^inf sinc^2(f*D*Ts) df
%      = 1/(2*D*Ts)

fprintf('    Boxcar prefilter:\n');
fprintf('       |H(f)| = D*Ts * sinc(f*D*Ts)\n');
fprintf('       ENBW_boxcar = integral_0^inf sinc^2(u) du / (D*Ts)\n');
fprintf('       Since integral_0^inf sinc^2(u) du = 1/2:\n');
fprintf('       ENBW_boxcar = 1 / (2*D*Ts)\n\n');

% Standard voltage sampling ENBW:
% For 0.1% settling accuracy: e^{-N} = 0.001
% N = ln(1000) = 6.908 time constants
% Available settling time = D*Ts
% Time constant tau = D*Ts / N
% ENBW_RC = 1/(4*tau) = N/(4*D*Ts)

N_settle = log(1000);

fprintf('    Standard voltage sampling (0.1%% settling):\n');
fprintf('       Required settling: e^{-N} = 0.001\n');
fprintf('       N = ln(1000) = %.3f time constants\n', N_settle);
fprintf('       tau = D*Ts / N\n');
fprintf('       ENBW_RC = 1/(4*tau) = N/(4*D*Ts)\n\n');

% Ratio
ratio = N_settle / 2;

fprintf('    Ratio:\n');
fprintf('       ENBW_RC / ENBW_boxcar = [N/(4*D*Ts)] / [1/(2*D*Ts)]\n');
fprintf('                              = N/2\n');
fprintf('                              = %.3f / 2\n', N_settle);
fprintf('                              = %.2f\n', ratio);
fprintf('                              ~ 3.4x  [VERIFIED]\n\n');
fprintf('    The boxcar prefilter achieves %.1fx lower ENBW than\n', ratio);
fprintf('    conventional RC-based voltage sampling, for the same\n');
fprintf('    acquisition time and 0.1%% settling accuracy.\n');

fprintf('\nDone.\n');
