// ibex_soc: lowRISC Ibex (RV32IC, RV32M=0). Paths are relative to the repository root.
// Simulation view: CPU, cpu_core wrapper and the AES/SHA3/RSA accelerators.
+incdir+rtl/cpu/ibex
rtl/cpu/ibex/ibex_axi_top_combined.sv
rtl/accelerators/aes/AESEncrypt.v
rtl/accelerators/aes/AddRoundKey.v
rtl/accelerators/aes/KeyExpansionRound.v
rtl/accelerators/aes/MixColumns.v
rtl/accelerators/aes/ShiftRows.v
rtl/accelerators/aes/SubBytes.v
rtl/accelerators/aes/SubTable.v
rtl/accelerators/aes/aes_axi_slave.v
rtl/accelerators/aes/aes_wrapper.v
rtl/accelerators/sha3/SHA3_hardware_new.v
rtl/accelerators/sha3/SHA3_hardware_new_slave_lite_v1_0_S01_AXI.v
rtl/accelerators/sha3/F_permutation.v
rtl/accelerators/sha3/Keccak.v
rtl/accelerators/sha3/Padder.v
rtl/accelerators/sha3/Padder1.v
rtl/accelerators/sha3/rconst2in1.v
rtl/accelerators/sha3/round2in1.v
rtl/accelerators/rsa/RSA_mark03.v
rtl/accelerators/rsa/RSA_mark03_slave_lite_v1_0_S00_AXI.v
rtl/accelerators/rsa/RSA_core.v
rtl/cpu/ibex/cpu_core_ibex.v
