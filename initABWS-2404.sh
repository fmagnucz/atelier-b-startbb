#!/bin/bash

# 1. Check if the current directory is empty
# 'ls -A' lists all files including hidden ones, excluding . and ..
if [ "$(ls -A)" ]; then
     echo "Error: Directory is not empty! Execution aborted."
     exit 1
fi

# 2. Prompt for the Atelier B 24.04.2 path
echo "Please enter the installation path for Atelier B 24.04.2:"
read -r ATELIERB_PATH

# 3. Check if the input is empty or the path does not exist
if [ -z "$ATELIERB_PATH" ]; then
    echo "Error: The path cannot be empty!"
    exit 1
fi

if [ ! -d "$ATELIERB_PATH" ]; then
    echo "Error: The directory '$ATELIERB_PATH' does not exist."
    exit 1
fi

# 4. Create the 'bdb' and 'Archives' directories
mkdir -p "bdb" "Archives"

# 5. Get the absolute path of the 'bdb' directory
BDB_ABS_PATH=$(realpath "bdb")

# 6. Create the 'AtelierB' configuration file
cat <<EOF > AtelierB
!===========================================================================
! AtelierB Global resources
!===========================================================================
!
! Tools resources
!
ATB*ATB*Logic_Solver_Command:krt -a c70000d3000e100g10000h10000m10000000n130000o110400s60000t1100x5000y5500
ATB*ATB*TypeChecker_Command:TC.kin
ATB*ATB*Xref_Command:xref
ATB*ATB*Proof_Obligations_Generator_Command:PO.kin
ATB*ATB*Proof_Obligations_Generator_NG_Command:pog
ATB*ATB*Proof_Obligations_Generator_EvB_Command:pogevb
ATB*ATB*Proof_Obligations_Generator_NG:TRUE
ATB*ATB*Binst_Command:binst
ATB*ATB*Prover_Command:MU.kin
ATB*ATB*KParser_Command:pk -a m20000
ATB*ATB*Predicate_Prover_Command:PP.kin
ATB*ATB*BED_Command:bed
ATB*ATB*Read_PMI_Command:READPMI.kin
ATB*ATB*ML_Command:ML.kin
ATB*ATB*ComenC_Translator_Command:b2c
ATB*ATB*Delta_Component_Command:DELTA3.kin
ATB*ATB*Bart_Refiner_Command:bart
ATB*ATB*BBeautifuler_Command:BBeautifuler
ATB*ATB*Print_Command:bprint
ATB*ATB*Bxml_Command:bxml
ATB*ATB*B_Compiler_Command:bcomp
ATB*ATB*External_Proof_Command:extprove
ATB*ATB*Replay_External_Proof_Command:extreplay
ATB*ATB*Proof_Metrics:extmetrics
ATB*ATB*Rust_Translator_Command:b2rust

!===========================================================================
! TypeChecker Resource : Enable Local Operations
!===========================================================================
ATB*TC*Enable_Local_Operations:TRUE

! Set to true not to use prover extensions defined in the 3.7 version
ATB*PR*Pr_3_6_compatibility:FALSE

!===========================================================================
! Resources to use third-party provers
!===========================================================================
ATB*Proof*Why3Writer:po2why
ATB*Proof*Pog_Smt_Simplified_Encode:pog2smt
ATB*Proof*Pog_Smt_PP_Encode:ppTransSmt
ATB*Proof*Smt_Simplified_Read_Status:simple_smt_solver_reader
ATB*Proof*Smt_Read_Status:smt_solver_reader
ATB*Proof*Pog_TPTP_PP_Encode:ppTransTPTP
ATB*Proof*TPTP_Read_Status:tptp_reader
ATB*Proof*Pog_Why_Encode:pog2why
ATB*Proof*AltErgo_Read_Status:altergo_reader
!===========================================================================
! Installation path dependent resources
!===========================================================================
ATB*BART*RefinerFile:${ATELIERB_PATH}/share/bart/PatchRaffiner.rmf
ATB*B2RUST*Configuration_Directory:${ATELIERB_PATH}/share/b2rust/config/
ATB*ATB*Atelier_Database_Directory:${BDB_ABS_PATH}
EOF

echo "Success: 'bdb' and 'Archives' directories, and 'AtelierB' config file have been created."
