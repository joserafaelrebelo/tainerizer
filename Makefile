CUDA ?= 12.8
FLAVOR ?= runtime
GUI ?= 0

SERVICE := cuda$(subst .,,$(CUDA))-$(FLAVOR)
COMPOSE_FILES := -f compose.yaml
ifeq ($(GUI),1)
COMPOSE_FILES += -f compose.gui.yaml
endif

.PHONY: setup build run shell config docker-run apptainer-build apptainer-run slurm-submit

setup:
	./scripts/setup.sh

build:
	docker compose build $(SERVICE)

run:
	GUI=$(GUI) ./scripts/run_docker.sh $(SERVICE)

shell: run

config:
	docker compose $(COMPOSE_FILES) config --services

docker-run:
	./scripts/run_docker.sh $(SERVICE)

apptainer-build:
	./scripts/build_apptainer.sh $(SERVICE)

apptainer-run:
	./scripts/run_apptainer.sh

slurm-submit:
	sbatch ./scripts/slurm_job.sh