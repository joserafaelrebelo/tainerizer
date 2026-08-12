CUDA ?= 12.8
FLAVOR ?= runtime

SERVICE := cuda$(subst .,,$(CUDA))-$(FLAVOR)

.PHONY: setup build run shell config docker-run apptainer-build apptainer-run slurm-submit

setup:
	./scripts/setup.sh

build:
	docker compose build $(SERVICE)

run:
	docker compose run --rm $(SERVICE)

shell: run

config:
	docker compose config --services

docker-run:
	./scripts/run_docker.sh $(SERVICE)

apptainer-build:
	./scripts/build_apptainer.sh $(SERVICE)

apptainer-run:
	./scripts/run_apptainer.sh

slurm-submit:
	sbatch ./scripts/slurm_job.sh