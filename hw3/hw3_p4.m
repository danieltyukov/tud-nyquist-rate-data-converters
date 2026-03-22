%% HW3 Problem 4: Switch Nonidealities
% Switched-capacitor circuit with charge injection and clock feedthrough
clear; clc;

fprintf('=== Problem 4: Switch Nonidealities ===\n\n');

% Switch parameters (all switches identical NMOS)
W = 10e-6;           % 10 um
L = 0.2e-6;          % 0.2 um
Cox = 10e-15/1e-12;  % 10 fF/um^2 = 10e-3 F/m^2
Vt = 0.4;            % V
Col = 0.1e-15/1e-6;  % 0.1 fF/um = 0.1e-9 F/m

% Derived
WLCox = W * L * Cox;           % gate oxide capacitance
Cov = Col * W;                 % overlap capacitance per terminal
fprintf('Switch parameters:\n');
fprintf('    WLCox = %.0f fF\n', WLCox*1e15);
fprintf('    Cov (overlap per terminal) = %.1f fF\n', Cov*1e15);

% Circuit
C1 = 1e-12;          % 1 pF
C2 = 2e-12;          % 2 pF
Vsource = 1.0;       % 1V source
Vclk_high = 1.8;     % V
Vclk_low = 0;        % V

% Physical constants
k = 1.381e-23;       % Boltzmann constant
T = 300;             % room temperature

fprintf('    C1 = %.0f pF, C2 = %.0f pF\n', C1*1e12, C2*1e12);
fprintf('    Vsource = %.1f V\n\n', Vsource);

%% Circuit operation
% Phase phi1 (ON): left phi1 switch connects 1V to V1, right phi1 connects V2 to ref
% Phase phi2 (ON): phi2 switch connects V1 to V2 (charge sharing)
%
% Timing:
%   phi1 high -> phi1 falls at t=t1 -> phi2 rises -> phi2 falls at t=t2

%% (e) Standard deviation of V1 at t1 and t2
fprintf('(e) kT/C noise on V1:\n');

% At t1 (phi1 turns off):
% V1 was connected to 1V source through phi1 switch
% When switch opens, kT/C noise is sampled on C1
sigma_V1_t1 = sqrt(k*T/C1);
fprintf('    At t1 (phi1 opens): sigma(V1) = sqrt(kT/C1)\n');
fprintf('       = sqrt(%.3e / %.1e) = sqrt(%.3e)\n', k*T, C1, k*T/C1);
fprintf('       = %.1f uVrms\n', sigma_V1_t1*1e6);

% At t2 (phi2 turns off):
% During phi2, V1 and V2 were connected (charge sharing).
% Both C1 and C2 were floating (phi1 OFF).
% Total charge Q = C1*V1 + C2*V2 is conserved (set at t1 with kT/C noise).
%
% Noise analysis:
%   Common mode noise (from phi1): sigma^2(Vcm) = kT/(C1+C2)
%   Differential noise (from phi2): sigma^2(dV1) = kT*C2/[C1*(C1+C2)]
%   Total: sigma^2(V1) = kT/(C1+C2) + kT*C2/[C1*(C1+C2)]
%                       = kT/[C1*(C1+C2)] * [C1 + C2] = kT/C1
%
% Result: sigma(V1) at t2 = sqrt(kT/C1) -- same as at t1!
% This is a fundamental result: kT/C noise depends only on the
% capacitance at the node, independent of circuit history.

sigma_V1_t2 = sqrt(k*T/C1);
fprintf('\n    At t2 (phi2 opens): sigma(V1) = sqrt(kT/C1)\n');
fprintf('       = %.1f uVrms\n', sigma_V1_t2*1e6);
fprintf('    Note: sigma(V1) is the SAME at both t1 and t2.\n');
fprintf('    This is because the kT/C noise on a node depends only\n');
fprintf('    on the total capacitance at that node (C1), regardless\n');
fprintf('    of the switching history.\n');

%% (f) Charge injection on V1 at t1
% At t1, phi1 switches turn off (fast gating, 50/50 split)
% Left phi1 switch: connects 1V source to V1
%   Before turn-off: VG = 1.8V, VS = VD = 1V (V1 tracking 1V)
%   Channel charge: Qch = WLCox * (VGS - Vt)
%   VGS = 1.8 - 1.0 = 0.8V
%   Qch = WLCox * VOV = WLCox * 0.4V
%   Half injected to V1 side: DeltaQ = -Qch/2 (negative = electrons)
%   DeltaV1 = -WLCox*(VGS-Vt)/(2*C1)

fprintf('\n(f) Charge injection on V1 at t1:\n');

VGS_f = Vclk_high - Vsource;  % gate at 1.8V, source at 1V
VOV_f = VGS_f - Vt;

fprintf('    VGS = %.1fV - %.1fV = %.1fV\n', Vclk_high, Vsource, VGS_f);
fprintf('    VOV = %.1fV - %.1fV = %.1fV\n', VGS_f, Vt, VOV_f);
fprintf('    Qch = WLCox * VOV = %.0f fF * %.1f V = %.0f fC\n', ...
    WLCox*1e15, VOV_f, WLCox*VOV_f*1e15);

DeltaV1_ci = -WLCox * VOV_f / (2 * C1);
V1_t1_ci = Vsource + DeltaV1_ci;

fprintf('    DeltaV1 = -WLCox*VOV/(2*C1) = -%.0f fF * %.1f / (2 * %.0f fF)\n', ...
    WLCox*1e15, VOV_f, C1*1e15);
fprintf('    DeltaV1 = %.4f V = %.2f mV\n', DeltaV1_ci, DeltaV1_ci*1e3);
fprintf('    V1(t1) = %.1f + (%.4f) = %.4f V\n', Vsource, DeltaV1_ci, V1_t1_ci);

%% (g) Clock feedthrough on V1 at t1
% When phi1 drops from 1.8V to 0V, gate voltage change couples
% through overlap capacitance Cov to V1.
% At t1, V1 is connected only to C1 (source disconnected).
%
% DeltaV1 = DeltaVgate * Cov / (Cov + C1)
% DeltaVgate = 0 - 1.8 = -1.8V

fprintf('\n(g) Clock feedthrough on V1 at t1:\n');

DeltaVgate = Vclk_low - Vclk_high;  % -1.8V

DeltaV1_cf = DeltaVgate * Cov / (Cov + C1);
V1_t1_cf = Vsource + DeltaV1_cf;

fprintf('    DeltaVgate = %.1f - %.1f = %.1f V\n', Vclk_low, Vclk_high, DeltaVgate);
fprintf('    Cov = %.1f fF, C1 = %.0f fF\n', Cov*1e15, C1*1e15);
fprintf('    DeltaV1 = %.1f * %.1f / (%.1f + %.0f)\n', ...
    DeltaVgate, Cov*1e15, Cov*1e15, C1*1e15);
fprintf('    DeltaV1 = %.6f V = %.4f mV\n', DeltaV1_cf, DeltaV1_cf*1e3);
fprintf('    V1(t1) = %.1f + (%.6f) = %.6f V\n', Vsource, DeltaV1_cf, V1_t1_cf);

fprintf('\nDone.\n');
