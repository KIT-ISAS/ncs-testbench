# general configuration
SHELL = /bin/bash
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-print-directory

# simulations
# notice the naming scheme! each entry in CONFIGS corresponds to both an
# variable with the same name and a variable prefixed with CONFIGS_ and GROUPS_
CFGDIR=$(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

CONFIGS = FOURHOP

FOURHOP = eval-fourhop.ini
FOURHOP_RESULTDIR = results-fourhop
FOURHOP_GROUPS = 2
FOURHOP_GROUP1 = MultiBottleneck_Mock_4FlowsCross
FOURHOP_GROUP2 = MultiBottleneck_Mock_Manyflows

# commands
SIMULATIONCMD = ../run-testbench -u Cmdenv
# -f cocc/eval-singlehop.ini
# -c configuration
# -r run
#run_limit=$( $sim_command -s -c $configuration -q numruns )
EXTRACTCMD = ../extract_csv.sh
COMPRESSCMD = pixz
CALL_SUBMK = +$(MAKE) -f $(firstword $(MAKEFILE_LIST))

# targets
.PHONY: all

all: $(foreach cfgfile,$(CONFIGS),$($(cfgfile)))

#######################################
# automatic rule generation starts here
#######################################
# flow:
# iterate over configfiles, create rule *.ini->*.ini-group-prefix (or -config if not part of a group)
# for each group: create rule *.ini-group-prefix->*.ini-config
# for each config: create rule *.ini-config and *.ini-config.run
#	these run submakes for *.ini-configs.[run]


# add rules for *.ini-config
# add rules *.ini-config.run
#1: ini, 2: configuration, 3: result-name
define PROCESS_CONFIG =
$(1)-$(2):
	@echo "[$(1) $(2)] starting"
	@$(CALL_SUBMK) $$$$( \
		limit=$$$$($(SIMULATIONCMD) -f $(CFGDIR)/$(1) -c $(2) -s -q numruns); \
		for ((run=0; run < limit; run++)); do \
			echo -n "$(1)-$(2).$$$$run "; \
		done )
	@echo "[$(1) $(2)] extracting CSV"
	@cd "$($(3))" && ../$(EXTRACTCMD) "$(2)"
	@echo "[$(1) $(2)] compressing CSV"
	@cd "$($(3))" && $(COMPRESSCMD) "$(2).csv"
	@echo "[$(1) $(2)] done"

# rule for individual run
$(1)-$(2).%:
	@mkdir -p logs
	@echo "[$(1) $(2)] starting run $$*/$$(words $$(MAKECMDGOALS))"
	@$(SIMULATIONCMD) -f $(CFGDIR)/$(1) -c $(2) -r $$* > logs/$(1)-$(2)-$$*.log 2>&1
	@echo "[$(1) $(2)] finished run $$*/$$(words $$(MAKECMDGOALS))"

endef


# create rule *.ini-group-prefix->*.ini-config
# ... each config is passed to PROCESS_CONFIG to add further rules
# $1: ini, $2: group-name, $3: result-name
define PROCESS_GROUP =
# full group, format: prefix size
# add rule group-prefix -> group-configurations
$(1)-$(firstword $($(2))): $(foreach i,$(shell seq $(lastword $($(2)))),$(1)-$(firstword $($(2)))$(i))
	

# setup each group configuration
$(foreach i,$(shell seq $(lastword $($(2)))), \
	$(call PROCESS_CONFIG,$(1),$(firstword $($(2)))$(i),$(3)) \
)
endef

# test if passed group is a real group or just a single config
# ... and pass on for further processing
# $1: ini, $2: group-name, $3: result-name
define TEST_GROUP =
$(if $(filter 2,$(words $($(2)))), \
	$(call PROCESS_GROUP,$(1),$(2),$(3)), \
	$(if $(filter 1,$(words $($(2)))), \
		$(call PROCESS_CONFIG,$(1),$($(2)),$(3)), \
		$(error neither a group nor a config: $(2)) \
	) \
)
endef


# create rule *.ini->*.ini-group-prefix (or -config if not part of a group)
# ... and hand over to PROCESS_GROUP to add further rules as required
# $1: config
define PROCESS_CFGFILE =
#rule from .ini to group prefixes
$($(1)): $(foreach group,$(shell seq $($(1)_GROUPS)),$($(1))-$(firstword $($(1)_GROUP$(group))))
	

#process all groups
$(foreach group,$(shell seq $($(1)_GROUPS)), \
	$(call TEST_GROUP,$($(cfgfile)),$(1)_GROUP$(group),$(1)_RESULTDIR) \
)
endef


#process all inis
$(foreach cfgfile,$(CONFIGS), \
	$(eval $(call PROCESS_CFGFILE,$(cfgfile))) \
)

