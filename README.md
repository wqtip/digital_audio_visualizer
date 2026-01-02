# Digital Audio Visualizer

A real-time **audio spectrum visualizer** implemented in **SystemVerilog** on an FPGA. Live audio is sampled via an external microphone → a **32-point FFT** is performed → results are rendered on a **640×480 VGA display**.

---
## Demo Video

https://github.com/user-attachments/assets/a713a919-c182-429c-94c2-f1a0b3abd482

---
## Features

* Live audio capture using external microphone & ADC
* Hardware **DC offset correction** with long-term averaging
* **Hann-windowed 32-point radix-2 FFT** implemented from scratch (no IP cores)
* Pipelined **complex butterfly units**
* Fixed-point **frequency magnitude approximation**
* Real-time **VGA output @ 60 Hz**
* Button-controlled display mode: **16 or 32 frequency bars**

---

## System Overview

```
Microphone → XADC → DC Offset Correction → 32-Sample Window
        → Hann Window → FFT32 → Magnitude Scaling
        → Bar Renderer → VGA Output
```
---
## Tools & Platform

* **Language:** SystemVerilog
* **FPGA:** Xilinx Artix-7 (Basys3)
* **Clock:** 100 MHz
* **Display:** VGA

---

## License

MIT License
