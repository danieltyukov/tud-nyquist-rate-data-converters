clear;close all;clc;

% Test signals
pts = 1e4;
x = zeros(pts, 4);

% Sinusoidal test signal x(:, 1)
A = 1;
x(:, 1) = A*cos(2*pi*67/2048*[0:pts-1]);

% Random test signal x(:, 2) requirements: 
% 1. Samples are I.I.D. uniform with zero mean
% 2. Expected instantaneous power of x(:, 2) equals 
%    time averaged power of x(:, 1)
% Add random test signal x(:, 2) here
x(:, 2) = zeros(pts, 1);

% Random test signal x(:, 3) requirements: 
% 1. Samples are I.I.D. Gaussian with zero mean
% 2. Expected instantaneous power of x(:, 3) equals 
%    time averaged power of x(:, 1)
% Add random test signal x(:, 3) here
x(:, 3) = zeros(pts, 1);

% Random test signal x(:, 4) requirements:
% 1. Samples are I.I.D. and drawn from half-wave Gaussian distribution
% 2. Expected instantaneous power of x(:, 4) equals 
%    time averaged power of x(:, 1)
% Add random test signal x(:, 4) here
x(:, 4) = zeros(pts, 1);

% Sweep resolution
B = [4:10];
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
        % x(:, 4) -> unipolar -> y(:, 4)
        y(:, 1) = quantize_bipolar_midrise(x(:, 1), FSR(j), B(i));
        y(:, 2) = quantize_bipolar_midrise(x(:, 2), FSR(j), B(i));
        y(:, 3) = quantize_bipolar_midrise(x(:, 3), FSR(j), B(i));
        y(:, 4) = quantize_bipolar_midrise(x(:, 4), FSR(j), B(i));
        
        eq = y - x;
        SQNR(i, j, :) = 10*log10(std(x, 0, 1).^2./std(eq, 0, 1).^2);
    end
end

semilogx(FSR, squeeze(SQNR(B == 10, :, :)));
grid on;
xlabel('Loading Factor');
ylabel('SQNR [dB]');
title('Range-Precision Trade-Off for B = 10');
legend({'Sinusoidal', 'Uniform', 'Gaussian', 'ReLU Gaussian'});

% Loading factor
LF = FSR/2/(A/sqrt(2));

[SQNR_opt, i] = max(SQNR, [], 2);
LF_opt = LF(i);
SQNR_opt = squeeze(SQNR_opt)
LF_opt = squeeze(LF_opt)
