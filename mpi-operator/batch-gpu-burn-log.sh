#!/bin/bash

mkdir -p logs/gpu-burn-logs
pods=$(kubectl get pods -n mpi-operator| grep 'gpu-burn' | grep 'work' | grep 'Completed' | awk '{print $1}')

for pod in $pods; do
  node_name=$(kubectl get pod $pod -o=jsonpath='{.spec.nodeName}')
  echo "kubectl logs -n mpi-operator -f $pod > logs/gpu-burn-logs/${node_name}_gpu_burn.log"
  kubectl logs -n mpi-operator -f $pod > logs/gpu-burn-logs/${node_name}_gpu_burn.log
done
