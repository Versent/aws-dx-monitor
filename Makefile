
# Tag Variables for local run
STACK_NAME ?= "vms-hosted-dx-monitor"
OWNER ?= "MLCLENCDEV"
COSTCENTRE ?= "MLCLENCDEV"
PROJECT ?= "ENC"
ENVIRONMENT ?= "development"
CONFIDENTIALITY ?= "nonsensitive"
COMPLIANCE ?= "none"
LOGRETENTION ?= "7"
ARTIFACTBUCKET := "aws-dx-monitor-artifactbucket-apse2"

OUT_FILE?=./handler.zip
ENV?=dev

DELIVERABLE=$(abspath $(OUT_FILE))

.PHONY: deps package deploy clean default

default: deps install build package deploy

deps: ##=> Install all the dependencies to build
	$(info [+] Installing deps...")
	$(info checking bucket ${ARTIFACTBUCKET}")
	@pip install pipenv cfnlint
	@aws s3api head-bucket --bucket "${ARTIFACTBUCKET}" >/dev/null || aws s3 mb "s3://${ARTIFACTBUCKET}"

install: ##=> Run pipenv install
	$(info [+] Running pipenv install...")
	@pipenv install --dev

build:
	$(info [+] Build zip file...")
	$(eval VENV = $(shell pipenv --venv))
	$(eval PYMAJORVERSION = $(shell pipenv run python -c 'import sys; print(str(sys.version_info[0])+"."+str(sys.version_info[1]))'))
	@echo ${DELIVERABLE}
	@echo ${VENV}/lib/python${PYMAJORVERSION}/site-packages 
	@cd ${VENV}/lib/python${PYMAJORVERSION}/site-packages && zip -q -r9 ${DELIVERABLE} ./enum/__init__.py ./enum/LICENSE
	@zip -r9 -q ${DELIVERABLE} ./aws-dx-monitor.py

package:
	aws cloudformation package \
	--template-file SAM.yml \
	--output-template-file deploy.out.yml \
	--s3-bucket ${ARTIFACTBUCKET}

deploy:
	aws cloudformation deploy \
	--template-file deploy.out.yml \
	--stack-name  ${STACK_NAME} \
	--parameter-overrides Environment=${ENVIRONMENT}\
	--tags Owner=${OWNER} \
		CostCentre=${COSTCENTRE} \
		Application=aws-dx \
		Project=${PROJECT} \
		Environment=${ENVIRONMENT} \
		Confidentiality=${CONFIDENTIALITY} \
		Compliance=${COMPLIANCE} \
		LogRetentionPolicy=${LOGRETENTION} \
	--capabilities CAPABILITY_NAMED_IAM \
	--no-fail-on-empty-changeset

clean:
	rm ${DELIVERABLE} || true
	rm deploy.out.yml || true
