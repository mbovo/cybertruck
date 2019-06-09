#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELL=$(tput setaf 3)
BLUE=$(tput setaf 4)
OFF=$(tput sgr0)

function install_pyreq(){
  echo -e "\t+ ${YELL}Install python libs${BLUE}"
  pip install -r ${BASEDIR}/scripts/requirements.txt
  shasum -a 256 ${BASEDIR}/scripts/requirements.txt | cut -d " " -f 1 > ${BASEDIR}/.venv/requirements.txt.lock
  echo "${OFF}"
}

function install_ansreq(){
  echo -e "\t+ ${YELL}Install ansible roles${BLUE}"
  ansible-galaxy install -r ${BASEDIR}/scripts/requirements.yml
  echo "${OFF}"
}

function ansible_setup(){
  set -e
  if [ -r ${BASEDIR}/.venv/bin/activate ]; then
    echo -e "${BLUE}\t- Python3 env${GREEN}  OK"
    source ${BASEDIR}/.venv/bin/activate
    #echo -e "\t $(which python)"
    #echo -e "\t $(which pip)"
    # "\t $(which ansible)"
    #echo "${OFF}"
  else
    echo -e "${BLUE}\t+ Python3 env${YELL}  setup...${BLUE}"
    python3 -m venv ${BASEDIR}/.venv
    echo -e "\t+ ${YELL}Enter virtualenv${BLUE}"
    source ${BASEDIR}/.venv/bin/activate
    echo -e "\t\t $(which python)"
    echo -e "\t\t $(which pip)"
    echo -e "\t+ ${YELL}Installing pip${BLUE}"
    pip install --upgrade pip
    echo "${OFF}"
  fi
  if [ -r ${BASEDIR}/scripts/requirements.txt ]; then
    if [ -r ${BASEDIR}/.venv/requirements.txt.lock ]; then
      oldsum=$(cat ${BASEDIR}/.venv/requirements.txt.lock)
      newsum=$(shasum -a 256 ${BASEDIR}/scripts/requirements.txt | cut -d " " -f 1)
      if [ "$oldsum" != "$newsum" ]; then
        install_pyreq
      fi
    else
      install_pyreq
    fi
  fi
  if [ -r ${BASEDIR}/scripts/requirements.yml ]; then
        install_ansreq
  fi
  ANSIBLE_PYTHON_INTERPRETER=$(which python)
}

function usage(){
        echo
        echo "Usage $(basename $0) (-s stage) [-c configfile] [-t tags] [-Dh]"
        echo
        echo -e "\t -s stage" 
        echo -e "\t -c configfile" 
        echo -e "\t -t tags"
        echo -e "\t -D Debug, more verbose output"
        echo -e "\t -h Print this help"
        echo
        exit 1
}

function preflight(){
  set +e
  abrt=0
  echo "-------------------------"
  echo "${BLUE}+ Preflight checks"
  
  P3=$(which python3)
  echo -en "${BLUE}\t- Python3     "
  if [ $? -gt 0 ]; then
  echo "${RED} NOT FOUND"
    abrt=1
  else
    echo "${GREEN} OK"
  fi
  
  echo -en "${BLUE}\t- Terraform   "
  TF=$(which terraform)
  if [ $? -gt 0 ]; then
    echo "${RED} NOT FOUND"
    abrt=1
  else
    echo "${GREEN} OK"
  fi

  echo -en "${BLUE}\t- Helm        "  
  HELM=$(which helm)
  if [ $? -gt 0 ]; then
    echo "${RED} NOT FOUND"
    abrt=1
  else
    HELMVER=$(helm version --short -c | grep -qi "v3")
    if [ $? -gt 0 ]; then
      echo "${RED} Invalid version v2"
      abrt=1
    else
      echo "${GREEN} OK"
    fi
  fi
  
  echo -en "${BLUE}\t- kubectl     "
  KCTL=$(which kubectl)
  if [ $? -gt 0 ]; then
    echo "${RED} NOT FOUND"
    abrt=1
  else
    echo "${GREEN} OK"
  fi

  echo -en "${BLUE}\t- gcloud      "
  KCTL=$(which gcloud)
  if [ $? -gt 0 ]; then
    echo "${RED} NOT FOUND"
    abrt=1
  else
    echo "${GREEN} OK"
  fi

  ansible_setup

  if [ $abrt -gt 0 ]; then
    echo "${YELL} Aborted:"
    echo "${OFF} You have errors during preflight checks, if you know what are you doing you can skip them with -F"
    exit 1
  fi
  echo "${OFF}-------------------------"
}