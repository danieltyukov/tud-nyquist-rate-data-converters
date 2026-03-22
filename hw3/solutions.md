# HW3 Solutions — ET4369 Nyquist-Rate Data Converters

---

## Problem 1: Spectral Performance Metrics

**Script:** `hw3_p1.m`

### (a) Spectrum plot
See `p1a_spectrum.png` — 10000-point FFT, x-axis in MHz, y-axis in dBFS.

### (b) Input frequency
**fᵢₙ = 1.27 MHz** (FFT bin 127)

### (c) Performance metrics

| Metric | Value |
|--------|-------|
| SNR    | 58.94 dB |
| SNDR   | 52.90 dB |
| ENOB   | 8.50 bits |
| THD    | −54.15 dB |
| SFDR   | 54.58 dB |

Harmonic levels (dBFS):

| Harmonic | Freq (MHz) | Level (dBFS) |
|----------|-----------|-------------|
| HD2      | 2.54      | −106.5      |
| HD3      | 3.81      | −54.5       |
| HD4      | 5.08      | −90.4       |
| HD5      | 6.35      | −64.3       |
| HD6      | 7.62      | −106.5      |
| HD7      | 8.89      | −103.8      |

### (d) SFDR-limiting non-ideality
The SFDR is determined by **HD3 (3rd harmonic distortion)** at −54.5 dBFS.

HD3 dominance is characteristic of a **symmetric (odd) nonlinearity** — typically caused by signal-dependent on-resistance of the sampling switch. The nonlinear rₒₙ = 1/[μCₒₓ(W/L)(VGS − Vₜ − Vᵢₙ)] produces a cubic transfer function error, which generates predominantly 3rd and 5th harmonics (both of which are visible in the spectrum).

### (e) Additional noise sources
- Ideal SQNR = 6.02 × 10 + 1.76 = **61.96 dB**
- Measured SNR = **58.94 dB** (3 dB worse)
- Ideal noise floor = −98.95 dBFS
- Measured noise floor ≈ −95.85 dBFS

**Yes, there are additional noise sources** beyond quantization noise. The measured total noise power is **4.08× the ideal quantization noise power**, meaning the electronic noise power is approximately **3× the quantization noise power**. These additional sources likely include thermal noise (kT/C sampling noise), comparator noise, and amplifier noise within the ADC.

---

## Problem 2: Clock Bootstrapping

**Script:** `hw3_p2.m`

### Circuit operation
During φ₁ (precharge): Cboot charges to VDD, gate of M₁ pulled to GND.
During φ₂ (track): Cboot bottom plate → Vᵢₙ (source), top plate → gate.

Charge conservation at gate node:
```
    Cboot(VG − Vᵢₙ) + Cpar · VG = Cboot · VDD

         Cboot · VDD − Cpar · Vᵢₙ
    VGS = ─────────────────────────
              Cboot + Cpar
```

### (a) On-resistance variation

| Vᵢₙ (V) | VGS (V) | VOV (V) | rₒₙ (Ω) |
|---------|---------|---------|---------|
| 0.5     | 1.417   | 0.917   | 109.1   |
| 1.0     | 1.333   | 0.833   | 120.0   |

**Percent increase = 10.0%** (relative to minimum rₒₙ at Vᵢₙ = 0.5V)

The Cpar term introduces a residual signal dependence: higher Vᵢₙ → lower VGS → higher rₒₙ.

### (b) Charge injection error variation

Fast gating, 50/50 split:
```
    ΔVout = −WLCₒₓ · VOV / (2 · CL)
```

| Vᵢₙ (V) | VOV (V) | ΔVout (mV) |
|---------|---------|-----------|
| 0.5     | 0.917   | −45.83    |
| 1.0     | 0.833   | −41.67    |

**Peak-to-peak error variation = 4.17 mV**

---

## Problem 3: INL and SFDR

**Script:** `hw3_p3.m`

### (a) Maximum INL (cubic bow)

From the 65536-point FFT spectrum (page 2 of assignment):
- SFDR ≈ 40 dB (HD3 at approximately −40 dBFS)

For a cubic INL (endpoint-corrected): INL(u) = A₃(u³ − u), u ∈ [−1, 1]

Peak of |u³ − u| occurs at u = ±1/√3 with value 2/(3√3).

The HD3-INL relationship:
```
    HD3 = INL_max · 3√3 / (4 · 2ᴮ)

              4 · 2ᴮ
    INL_max = ──────────────────── ≈ 15.8 LSB
              3√3 · 10^(SFDR/20)
```

### (b) Electronic noise σ

- Ideal noise floor: −SQNR − 10log₁₀(N/2) = −67.98 − 45.15 = **−113.13 dBFS**
- Measured noise floor ≈ **−100 dBFS** (from figure)
- P_total/P_quant ≈ 20.6
- Electronic noise power ≈ 19.6× quantization noise
- **σ_electronic ≈ 1.28 LSB**

### (c) ENOB

SNDR is dominated by distortion (HD3):
```
    SNDR ≈ 39.9 dB
    ENOB = (39.9 − 1.76) / 6.02 ≈ 6.3 bits
```

### (d) Commercial product (Lee et al., 10-bit pipeline ADC)

From Fig. 14(b): single-ended 1.0-Vpp input shows cubic S-shaped INL with smooth average amplitude ≈ ±0.9 LSB (caused by switched source follower distortion, per authors).
From Fig. 10(b): SFDR ≈ 62 dBc at ~70 MHz. Fig. 11(d): SFDR = 61.8 dBc at 79 MHz.
```
    HD3 = 0.9 × 3√3 / (4 × 1024) = 0.00114
    SFDR_estimated = −20 log₁₀(0.00114) ≈ 58.8 dBc
    SFDR_measured (from Fig. 10(b), ~70 MHz) ≈ 62 dBc
```
**Agreement within ~3.2 dB** — the estimate is slightly pessimistic because the smooth cubic fit overestimates the true harmonic content (random INL components don't coherently add to HD3).

---

## Problem 4: Switch Nonidealities

**Script:** `hw3_p4.m`

### Device parameters
- WLCₒₓ = W × L × Cₒₓ = 10 × 0.2 × 10 = **20 fF**
- Cₒᵥ = Cₒₗ × W = 0.1 × 10 = **1 fF** (overlap capacitance per terminal)

### (e) kT/C noise σ(V₁)

At t₁ (φ₁ opens): V₁ was tracking 1V through left switch.
```
    σ(V₁)|_{t₁} = √(kT/C₁) = √(4.14×10⁻²¹ / 10⁻¹²) = 64.4 μVrms
```

At t₂ (φ₂ opens): V₁ and V₂ were connected through φ₂ switch.
The noise decomposes into:
- Common mode (from φ₁): σ²(Vcm) = kT/(C₁+C₂)
- Differential (from φ₂): σ²(δV₁) = kT·C₂/[C₁(C₁+C₂)]
- Total: σ²(V₁) = kT/(C₁+C₂) + kT·C₂/[C₁(C₁+C₂)] = **kT/C₁**

```
    σ(V₁)|_{t₂} = √(kT/C₁) = 64.4 μVrms
```

**Both values are identical.** The kT/C noise on a node depends only on the capacitance at that node, independent of the switching history.

### (f) Charge injection (V₁ at t₁)

Left φ₁ switch turns off: VGS = 1.8 − 1.0 = 0.8V, VOV = 0.4V
```
    Qch = WLCₒₓ × VOV = 20 fF × 0.4V = 8 fC
    ΔV₁ = −Qch/(2C₁) = −8 fC / (2 × 1 pF) = −4.0 mV
    V₁(t₁) = 1.0 − 0.004 = 0.996 V
```

### (g) Clock feedthrough (V₁ at t₁)

Gate drops from 1.8V to 0V: ΔVgate = −1.8V
```
    ΔV₁ = ΔVgate × Cₒᵥ/(Cₒᵥ + C₁)
         = −1.8 × 1 fF / (1 fF + 1000 fF)
         = −1.80 mV
    V₁(t₁) = 1.0 − 0.00180 = 0.99820 V
```

---

## Problem 5: Boxcar Sampling

**Script:** `hw3_p5.m`

### (h) Derivation of Equation (2)

Starting from Eq. (1):
```
    Q_{in2,CT}(t) = ∫_{t−DTs}^{t} I_{out1d}(t') dt'
```

This is a convolution Q = I ∗ h where h(τ) = 1 for 0 ≤ τ ≤ DTs.

Fourier transform of the rectangular window:
```
    H(ω) = ∫₀^{DTs} e^{−jωτ} dτ = (1 − e^{−jωDTs}) / (jω)
```

Factoring out e^{−jωDTs/2}:
```
    H(ω) = e^{−jωDTs/2} · 2sin(ωDTs/2) / ω
```

Taking the magnitude:
```
    |Q_{in2,CT}(ω)|       2|sin(ωDTs/2)|
    ─────────────────── = ─────────────────     [QED]
    |I_{out1d}(ω)|               ω
```

### (i) 3.4× ENBW advantage

**Boxcar prefilter ENBW:**
```
    |H(f)|² = (DTs)² sinc²(fDTs)
    ENBW_boxcar = ∫₀^∞ sinc²(u) du / (DTs) = 1/(2DTs)
```

**Standard RC voltage sampling (0.1% settling):**
```
    Required: e^{−N} = 0.001  →  N = ln(1000) = 6.908
    τ = DTs/N
    ENBW_RC = 1/(4τ) = N/(4DTs)
```

**Ratio:**
```
    ENBW_RC         N/(4DTs)       N
    ───────────── = ──────────── = ─── = 6.908/2 = 3.45 ≈ 3.4×  ✓
    ENBW_boxcar     1/(2DTs)       2
```

The boxcar prefilter achieves **3.4× lower effective noise bandwidth** than conventional RC-based voltage sampling, for the same acquisition time and 0.1% dynamic settling accuracy. This means 3.4× less noise power folds into the signal band.
