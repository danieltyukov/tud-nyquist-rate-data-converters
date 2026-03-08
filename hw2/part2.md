# Problem 2: Segmented DAC Paper Review

**Paper:** Y.-H. Lin and B. Bult, "A 10-b, 500-MSample/s CMOS DAC in 0.6 mm²," *IEEE J. Solid-State Circuits*, vol. 33, no. 12, pp. 1948–1958, Dec. 1998.

## What application is this DAC intended for?

The DAC is designed for **cable modem headend transmitters** — a frequency-domain application where the DAC must synthesize high-quality sinusoidal tones across the cable modem upstream band (5–65 MHz).

In a cable modem headend, the transmitter generates multiple QAM-modulated carriers simultaneously. The DAC converts the digitally synthesized waveform to analog at high speed ($f_s$ up to 500 MS/s). Since the application is in the frequency domain, **spectral purity (SFDR)** is the primary performance metric rather than time-domain linearity alone.

### Key specifications driven by this application

| Parameter              | Value                          |
|------------------------|--------------------------------|
| Resolution             | 10 bits                        |
| Sampling rate           | up to 500 MS/s                |
| SFDR                   | > 60 dB ($f_s \leq 200$ MS/s) |
| DNL                    | 0.1 LSB                       |
| INL                    | 0.2 LSB                       |
| Power                  | 125 mW at 500 MS/s            |
| Area                   | 0.6 mm²                       |
| Technology             | 0.35 μm, 1P4M, 3.3V standard digital CMOS |

### Architecture: 8+2 segmented current-steering DAC

The DAC uses a segmented architecture with **8 thermometer-coded MSBs** and **2 binary-weighted LSBs**. This is a current-steering topology where matched current sources are switched to the output.

The 8+2 segmentation is chosen as a design trade-off:
- **Thermometer coding** (MSBs) ensures monotonicity, reduces glitch energy, and improves DNL — critical for spectral purity.
- **Binary weighting** (LSBs) reduces decoder complexity and area for the least significant bits where mismatch impact is small.
- The segmentation point is optimized so that the **analog area** (current source array) roughly equals the **digital area** (thermometer decoder), minimizing total die area (see Fig. 9 of the paper). This "optimal point" yields the compact 0.6 mm² layout.

### Why frequency-domain performance matters

For cable modem headend use, the DAC output is filtered and upconverted. Harmonic distortion and intermodulation products from the DAC appear as spurious tones in adjacent channels, degrading system performance. The > 60 dB SFDR requirement ensures these spurs are sufficiently suppressed for reliable QAM transmission across multiple channels.
