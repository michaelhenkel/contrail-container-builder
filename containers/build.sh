#!/bin/bash
containers_dir="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
version=$CONTRAIL_VERSION
os_version=$OPENSTACK_VERSION
registry=$CONTRAIL_REGISTRY
repository=$CONTRAIL_REPOSITORY

env_dir="${BASH_SOURCE%/*}"
source build.env

version=${version:-${CONTRAIL_VERSION:-'4.0.2.0-35'}}
os_version=${os_version:-${OPENSTACK_VERSION:-'newton'}}
registry=${registry:-${CONTRAIL_REGISTRY:-'auto'}}
repository=${repository:-${CONTRAIL_REPOSITORY:-'auto'}}

path=$1
opts=$2

echo 'Contrail version: '$version
echo 'OpenStack version: '$os_version
echo 'Contrail registry: '$registry
echo 'Contrail repository: '$repository
if [ -n "$opts" ]; then
  echo 'Options: '$opts
fi

# TODO: rework or remove this
declare -A os_subversions
os_subversions=([newton]=5 [ocata]=3)
export os_subversion="${os_subversions[$os_version]}"

linux=$(awk -F"=" '/^ID=/{print $2}' /etc/os-release | tr -d '"')
was_errors=0

build_container () {
  local dir=${1%/}
  local container_name=`echo ${dir#"./"} | tr "/" "-"`
  local container_name='contrail-'${container_name}
  echo 'Building '$container_name
  if [ $linux == "centos" ]; then
    cat $dir/Dockerfile \
      | sed -e 's/\(^ARG CONTRAIL_REGISTRY=.*\)/#\1/' \
      -e 's/\(^ARG CONTRAIL_VERSION=.*\)/#\1/' \
      -e 's/\(^ARG OPENSTACK_VERSION=.*\)/#\1/' \
      -e 's/\(^ARG OPENSTACK_SUBVERSION=.*\)/#\1/' \
      -e "s/\$OPENSTACK_VERSION/$os_version/g" \
      -e "s/\$OPENSTACK_SUBVERSION/$os_subversion/g" \
      -e 's|^FROM ${CONTRAIL_REGISTRY}/\([^:]*\):${CONTRAIL_VERSION}|FROM '$registry'/\1:'$version'|' \
      > $dir/Dockerfile.nofromargs
    int_opts="-f $dir/Dockerfile.nofromargs"
  fi
  local logfile='build-'$container_name'.log'
  docker build -t ${registry}'/'${container_name}:${version} \
    --build-arg CONTRAIL_VERSION=${version} \
    --build-arg OPENSTACK_VERSION=${os_version} \
    --build-arg OPENSTACK_SUBVERSION=${os_subversion} \
    --build-arg CONTRAIL_REGISTRY=${registry} \
    --build-arg REPOSITORY=${repository} \
    ${int_opts} ${opts} $dir |& tee $logfile
  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    docker push ${registry}'/'${container_name}:${version} |& tee -a $logfile
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
      rm $logfile
    fi
  fi
  if [ -f $logfile ]; then
    was_errors=1
  fi
}

build_dir () {
  local dir=${1%/}
  if [ -f ${dir}/Dockerfile ]; then
    build_container $dir
    return
  fi
  for d in $(ls -d $dir/*/ 2>/dev/null); do
    if [[ $d != "./" && $d == */base* ]]; then
      build_dir $d
    fi
  done
  for d in $(ls -d $dir/*/ 2>/dev/null); do
    if [[ $d != "./" && $d != */base* ]]; then
      build_dir $d
    fi
  done
}

if [ -z $path ] || [ $path = 'all' ]; then
  path=$containers_dir
fi
build_dir $path
if [ $was_errors -ne 0 ]; then
  echo 'Failed to build some containers, see log files'
fi
