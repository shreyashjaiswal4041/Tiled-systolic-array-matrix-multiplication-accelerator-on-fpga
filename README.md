
# Tiled Systolic Array Accelerator for Matrix Multiplication
**Author:** Shreyash Jaiswal  
**Institution:** Indian Institute of Information Technology (IIIT), Pune  
**Target Hardware:** Xilinx Artix-7 FPGA (Nexys DDR 4)  
**Performance:** 2.77ms for 256x256 MatMul @ 100MHz

---

## 🚀 Project Overview
This project implements a **8x8 Systolic Array Architecture** designed to accelerate large-scale matrix multiplication through spatial parallelism and data-flow optimization. By tiling 128x128 matrices into 8x8 blocks, the hardware minimizes the **Von Neumann bottleneck**, achieving a **4x speedup** over optimized NumPy implementations on a modern CPU.

### Key Features
* **Architecture:** 64 Processing Elements (PE) arranged in a 2D mesh.
* **Arithmetic:** 8-bit fixed-point multiplication with 32-bit accumulation for overflow protection.
* **Memory:** Dual-port BRAM utilizing a 128-bit wide data bus for simultaneous Row/Column streaming.
* **Verification:** Bit-true verification achieved with 99.5% correlation between RTL and Python Golden Models.

---

## 🏗 System Architecture

### 1. Processing Element (PE)
The core of the system is the Multiply-Accumulate (MAC) unit. Each PE features:
* **Stationary Data Flow:** Horizontal and vertical registers for data propagation.
* **Pipelined Valid Bit:** Ensures the accumulator only triggers when valid data reaches the specific grid coordinate.
* **DSP Integration:** Forced mapping to FPGA **DSP48** slices for high-performance arithmetic.

### 2. Tiling FSM
To handle 256x256 matrices on an 8x8 array, the controller manages:
* **BRAM Latency Compensation:** 3-cycle delay alignment between address request and PE valid-gate.
* **Automatic Reset:** 20-cycle pre-load phase to clear accumulators before new tile processing.
* **Output Snapshot:** Captures a stable 32-bit result for Seven-Segment display mapping.



---

## 📊 Performance & Utilization

### Timing Comparison
| Platform | Environment | Execution Time |
| :--- | :--- | :--- |
| **CPU** | NumPy (Python 3.10) | 11.22 ms |
| **FPGA (Ours)** | **Systolic Array @ 100MHz** | **2.77 ms** |

### Resource Utilization (Implemented Design)
| Resource | Used | Utilization % |
| :--- | :--- | :--- |
| **LUTs** | ~1,500 | ~2.3% |
| **Registers** | ~1,200 | ~1.0% |
| **DSP48 Slices** | **64** | **26.6%** |
| **BRAM (Tile)** | 3.5 | ~2.5% |

---

## 🛠 Setup & Usage

### 1. Prerequisites
* Vivado Design Suite (2022.1 or later)
* Python 3.x (for verification scripts)

### 2. Hardware Implementation
1.  Add `tiled_top.v`, `systolic_array_8x8.v`, and `pe.v` to your project.
2.  Import the `matrix_data.coe` file into a Block Memory Generator IP (Dual Port, 128-bit width, 2-cycle latency).
3.  Run **Synthesis** and **Implementation**.
4.  Generate Bitstream and program the FPGA.

### 3. Verification
Run the bit-true mirror script to verify hardware outputs:
```bash
python3 verify_output.py
```
*Note: Target Hardware Output for PE(0,0) is `0x41A41C`.*

