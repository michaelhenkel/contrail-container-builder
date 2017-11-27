#!/bin/bash
cmd=`echo $1 | tr "-" "_"`
function cmd_up(){
  docker-compose pull
  docker-compose up -d
}
function cmd_down(){
  docker-compose down
}
function cmd_ps(){
  docker-compose ps
}
function cmd_rest(){
  echo docker-compose $2
  docker-compose $2
}
case $2 in
  up)
    dc_cmd=cmd_up
    ;;
  down)
    dc_cmd=cmd_down
    ;;
  ps)
    dc_cmd=cmd_ps
    ;;
  *)
    dc_cmd=cmd_rest $2
    #echo -e "\n    wrong option
    #e.g. ./ctrl.sh contrail-controller up/down"
    #exit 1
    ;;
esac
contrail_controller=(database config webui control)
function cmd_contrail_controller(){
  for role in ${contrail_controller[@]}
  do
    cd contrail-controller/$role
    ${dc_cmd}
    cd -
  done
}
function cmd_contrail_controllerdb(){
  cd contrail-controller/database
  ${dc_cmd}
  cd -
}
function cmd_contrail_analyticsdb(){
  cd contrail-analyticsdb
  ${dc_cmd}
  cd -
}
function cmd_contrail_analytics(){
  cd contrail-analytics
  ${dc_cmd}
  cd -
}
function cmd_all(){
  cmd_contrail_controller
  cmd_contrail_analyticsdb
  cmd_contrail_analytics
}
cmd_${cmd}
