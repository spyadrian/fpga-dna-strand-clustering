# Project name
PROJECT_NAME = fpga-dna-strand-clustering

# Paths
VIVADO = vivado
TCL_SCRIPT = scripts/create_project.tcl
XPR_FILE = $(PROJECT_NAME)/$(PROJECT_NAME).xpr

# Rules
help:
	@echo "Usage :"
	@echo "make create-project  - Create Vivado project"
	@echo "make open-project    - Open Vivado project"
	@echo "make clean           - Clean Vivado project"

create-project:
	@$(VIVADO) -notrace -mode batch -source $(TCL_SCRIPT)

open-project:
	$(VIVADO) -notrace $(PROJECT_NAME)/$(PROJECT_NAME).xpr

clean:
	rm -rf $(PROJECT_NAME) .Xil *.jou *.log *.str


.PHONY: help create-project open-project clean
