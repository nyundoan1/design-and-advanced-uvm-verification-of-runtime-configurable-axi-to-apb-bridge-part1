

# Design and Advanced UVM Verification of a Runtime-Configurable AXI-to-APB Bridge

## Project Overview (Graduation Thesis)

Main project scope includes:

- RTL design using **Verilog**
- UVM-based verification environment development
- AXI/APB VIP integration
- Simulation and regression using **QuestaSim**
- Verification Planning (VPlan) with **70 testcases**

This repository focuses on the RTL design, UVM verification environment, testcase development, protocol validation, and regression-based functional verification (**No Coverage Version**).

For the **final completed version** including **Functional Coverage, Code Coverage, FPGA synthesis/implementation, timing analysis, and power evaluation**, please refer to:

🔗 **Part 2 (Final Version With Coverage)**  
https://github.com/nyundoan1/design-and-advanced-uvm-verification-of-runtime-configurable-axi-to-apb-bridge-part2



# 1. Project Directory Structure

The project is organized into separate RTL, verification, simulation, and register-model related directories.

<p align="center">
  <img width="1874" height="695" alt="image" src="https://github.com/user-attachments/assets/f30a10a1-e963-4de5-b08b-db9e0dfed9ab" />
</p>

### Main directories:

- `regmodel/` → Register abstraction model  
- `rtl/` → RTL design files  
- `sequences/` → UVM sequences  
- `sim/` → Simulation scripts / Makefile flow  
- `tb/` → UVM testbench  
- `testcases/` → Test library  
- `vip/` → AXI/APB verification IP


# 2. RTL Design Architecture

The bridge is designed with separate AXI clock domains, APB clock domains and runtime configurable logic via APB Register.

<p align="center">
  <img width="945" height="414" alt="image" src="https://github.com/user-attachments/assets/0e00fad1-7179-4219-b85b-f75e0f48d4a4" />
</p>

<p align="center">
  <img width="1810" height="851" alt="image" src="https://github.com/user-attachments/assets/eb9b3914-34a5-4897-8fc8-d3401afeb937" />
</p>

### Main blocks:

- AXI Clock Domain
- APB Clock Domain
  - APB Master
  - APB Register


# 3. Register Specification

The bridge supports **runtime-configurable APB registers** for dynamic address remapping, memory size allocation, and interrupt handling.

### Register Map Overview

The APB register map defines the primary configuration registers accessible by software.

<p align="center">
  <img width="771" height="143" alt="image" src="https://github.com/user-attachments/assets/c4e0e9fb-82f6-4e6d-bd4b-a4e3f761c981" />
</p>


### BAMS0 Register

This register defines the base address and memory size of **APB Slave 0**.

<p align="center">
  <img width="995" height="212" alt="image" src="https://github.com/user-attachments/assets/feee8a6a-f8cc-4015-90d4-5b0094213440" />
</p>


### BAMS1 Register

This register controls the address mapping of **APB Slave 1**.

<p align="center">
  <img width="991" height="216" alt="image" src="https://github.com/user-attachments/assets/5ca409c3-990d-4baf-9711-6f3f12c992ac" />
</p>


### BAMS2 Register

This register defines the address region of **APB Slave 2**.

<p align="center">
  <img width="989" height="210" alt="image" src="https://github.com/user-attachments/assets/728f62e5-db26-46c7-bf19-69cc40449c67" />
</p>



### Bridge Interrupt Register (BIR)

This register manages bridge-level interrupt handling and decode error status.

<p align="center">
  <img width="991" height="209" alt="image" src="https://github.com/user-attachments/assets/65af3ef3-45de-4d6f-8f5b-42e8ded27963" />
</p>

### Interrupt functions:

- **DecErrSt** → Decode Error Status (RW1C)  
- **DecErrEn** → Decode Error Interrupt Enable



# 4. Verification Plan (VPlan)

A structured verification plan was developed to ensure systematic functional validation of the **Runtime-Configurable AXI-to-APB Bridge**.  
The verification scope focuses on protocol correctness, register behavior, interrupt logic, remap functionality, and directed testcase-based validation.

### Major Verification Categories

- **APB Register Configuration** → Verification of register read/write behavior, reserved region protection, and byte access handling.

<p align="center">
  <img width="1709" height="537" alt="image" src="https://github.com/user-attachments/assets/92c0ae47-6899-4e2c-a08f-ae766d6d65d7" />
</p>

- **AXI Write Transaction** → Validation of AXI write path, burst types, slave decode, and response behavior.

<p align="center">
  <img width="1706" height="618" alt="image" src="https://github.com/user-attachments/assets/89ca2f07-594e-4420-8610-e3a36173d4bc" />
</p>

- **AXI Read Transaction** → Verification of AXI read path, burst handling, response correctness, and slave access.

<p align="center">
  <img width="1709" height="628" alt="image" src="https://github.com/user-attachments/assets/2d270fec-bb64-4653-b35c-4933bfad5d0f" />
</p>

- **Random Read/Write Transaction** → Directed-random scenarios to validate DUT stability under multiple access conditions.

<p align="center">
  <img width="1715" height="184" alt="image" src="https://github.com/user-attachments/assets/4d780edb-8cc5-45c2-b71d-ff45cfd53b0d" />
</p>

- **Interrupt Mechanism** → Verification of interrupt trigger, enable/disable control, clear behavior, and sticky interrupt logic.

<p align="center">
  <img width="1715" height="399" alt="image" src="https://github.com/user-attachments/assets/e5762c0d-ed1f-43a5-a9c4-42795ad0b7f1" />
</p>

- **Dynamic Address Remap** → Validation of runtime remap functionality, old region invalidation, and address decode correctness.

<p align="center">
  <img width="1707" height="492" alt="image" src="https://github.com/user-attachments/assets/6ac9c99a-c03a-440c-b984-c304bc32d52b" />
</p>



### Main Verification Categories

- **APB Register Configuration**
  - Register default value check
  - Read/Write access verification
  - Reserved region protection
  - Byte access behavior

- **AXI Write Transaction Verification**
  - FIXED / INCR / WRAP burst write
  - Slave selection
  - Boundary crossing
  - PSLVERR handling

- **AXI Read Transaction Verification**
  - FIXED / INCR / WRAP burst read
  - Read response validation
  - Slave decode verification
  - Error response checking

- **Random Transaction Verification**
  - Directed-random AXI read/write traffic
  - Address / burst / size randomization
  - DUT stability checking

- **Interrupt Verification**
  - Decode error interrupt
  - Interrupt enable / clear behavior
  - Sticky interrupt validation

- **Dynamic Address Remap Verification**
  - Runtime remap
  - Reserved region protection
  - Old region invalidation
  - Address crossing validation

### Verification Summary

- **6 major verification categories**
- **70 total directed + random-based testcases**
- Protocol validation
- Register-level verification
- Error handling
- Boundary and remap verification
- Functional stability checking


# 5. UVM Testbench Architecture

A reusable UVM-based verification environment was developed.

<p align="center">
  <img width="722" height="474" alt="image" src="https://github.com/user-attachments/assets/1680b0a4-665c-4209-a530-07e3cd2aa61c" />
</p>




# 6. Regression Results
This result confirms stable DUT behavior across register access, AXI/APB protocol handling, burst transactions, interrupt logic, remap verification, and random-based testcase execution.
<p align="center">
  <img width="534" height="665" alt="image" src="https://github.com/user-attachments/assets/3a9013b6-19fd-4de8-b31d-d1759f3e236b" />
  <img width="514" height="555" alt="image" src="https://github.com/user-attachments/assets/5fc346dd-3d05-4dfc-8324-786a9e71e53b" />
  <img width="498" height="193" alt="image" src="https://github.com/user-attachments/assets/a928881b-3f5e-4268-944e-9b7519a7d729" />
</p>

