%% HW3 Problem 2: Clock Bootstrapping
% Bootstrapped sampling switch analysis
clear; clc;

fprintf('=== Problem 2: Clock Bootstrapping ===\n\n');

% Parameters
Cboot = 500e-15;     % 500 fF
CL    = 500e-15;     % 500 fF
Cpar  = 100e-15;     % 100 fF
VDD   = 1.8;         % V
Vt    = 0.5;         % V
WLCox = 50e-15;      % 50 fF
muCoxWL = 10e-3;     % 10 mA/V^2

Vin_min = 0.5;       % V
Vin_max = 1.0;       % V

%% (a) Percent increase in on-resistance
% During phi1 (precharge): Cboot charges to VDD, gate pulled to GND
% During phi2 (track): Cboot bottom -> Vin (source), top -> gate
%
% Charge conservation at gate node when phi2 activates:
%   Cboot*(VG - Vin) + Cpar*VG = Cboot*VDD
%   VG = Cboot*(VDD + Vin) / (Cboot + Cpar)
%
% VGS = VG - Vin = [Cboot*VDD - Cpar*Vin] / (Cboot + Cpar)

fprintf('(a) On-resistance variation:\n');

VGS = @(Vin) (Cboot*VDD - Cpar*Vin) / (Cboot + Cpar);
VOV = @(Vin) VGS(Vin) - Vt;
Ron = @(Vin) 1 ./ (muCoxWL .* VOV(Vin));

VGS_min = VGS(Vin_min);
VGS_max = VGS(Vin_max);
VOV_min = VOV(Vin_min);  % at Vin = 0.5V (this is max VOV, min Ron)
VOV_max = VOV(Vin_max);  % at Vin = 1.0V (this is min VOV, max Ron)

% Note: higher Vin -> lower VGS -> lower VOV -> higher Ron
% So minimum Ron is at Vin_min and maximum Ron is at Vin_max

Ron_at_Vmin = Ron(Vin_min);  % minimum Ron
Ron_at_Vmax = Ron(Vin_max);  % maximum Ron

pct_increase = (Ron_at_Vmax - Ron_at_Vmin) / Ron_at_Vmin * 100;

fprintf('    At Vin = %.1fV: VGS = %.4fV, VOV = %.4fV, Ron = %.1f ohm\n', ...
    Vin_min, VGS_min, VOV_min, Ron_at_Vmin);
fprintf('    At Vin = %.1fV: VGS = %.4fV, VOV = %.4fV, Ron = %.1f ohm\n', ...
    Vin_max, VGS_max, VOV_max, Ron_at_Vmax);
fprintf('    Percent increase = (%.1f - %.1f)/%.1f * 100 = %.1f%%\n\n', ...
    Ron_at_Vmax, Ron_at_Vmin, Ron_at_Vmin, pct_increase);

%% (b) Peak-to-peak error variation from charge injection
% When M1 turns off (fast gating, 50/50 split):
%   Channel charge: Qch = WLCox * (VGS - Vt) = WLCox * VOV
%   Half injected to output (CL):
%   DeltaVout = -Qch/2 / CL = -WLCox * VOV / (2*CL)
%
% VOV depends on Vin, so the error is signal-dependent

fprintf('(b) Charge injection error variation:\n');

DeltaV = @(Vin) -WLCox * VOV(Vin) / (2 * CL);

DeltaV_at_Vmin = DeltaV(Vin_min);
DeltaV_at_Vmax = DeltaV(Vin_max);

pp_error = abs(DeltaV_at_Vmin - DeltaV_at_Vmax);

fprintf('    At Vin = %.1fV: VOV = %.4fV, DeltaVout = %.4f mV\n', ...
    Vin_min, VOV(Vin_min), DeltaV_at_Vmin*1e3);
fprintf('    At Vin = %.1fV: VOV = %.4fV, DeltaVout = %.4f mV\n', ...
    Vin_max, VOV(Vin_max), DeltaV_at_Vmax*1e3);
fprintf('    Peak-to-peak error variation = |%.4f - (%.4f)| = %.4f mV\n', ...
    DeltaV_at_Vmin*1e3, DeltaV_at_Vmax*1e3, pp_error*1e3);

fprintf('\nDone.\n');
