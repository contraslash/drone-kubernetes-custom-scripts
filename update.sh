#!/bin/bash

if [ -z ${PLUGIN_NAMESPACE} ]; then
  PLUGIN_NAMESPACE="default"
fi

if [ -z ${PLUGIN_KUBERNETES_USER} ]; then
  PLUGIN_KUBERNETES_USER="default"
fi

if [ ! -z ${PLUGIN_KUBERNETES_TOKEN} ]; then
  KUBERNETES_TOKEN=$PLUGIN_KUBERNETES_TOKEN
fi

if [ ! -z ${PLUGIN_KUBERNETES_SERVER} ]; then
  KUBERNETES_SERVER=$PLUGIN_KUBERNETES_SERVER
fi

if [ ! -z ${PLUGIN_KUBERNETES_CERT} ]; then
  KUBERNETES_CERT=${PLUGIN_KUBERNETES_CERT}
fi


if [ ! -z ${PLUGIN_KUBERNETES_CLIENT_CERTIFICATE} ]; then
  KUBERNETES_CLIENT_CERTIFICATE=$PLUGIN_KUBERNETES_CLIENT_CERTIFICATE
fi

if [ ! -z ${PLUGIN_KUBERNETES_CLIENT_KEY} ]; then
  KUBERNETES_CLIENT_KEY=$PLUGIN_KUBERNETES_CLIENT_KEY
fi

if [ ! -z ${KUBERNETES_CLIENT_CERTIFICATE} ] && [ ! -z ${KUBERNETES_CLIENT_KEY} ]; then
    echo ${KUBERNETES_CLIENT_CERTIFICATE} | base64 -d > client-certificate.crt
    echo ${KUBERNETES_CLIENT_KEY} | base64 -d > client-key.crt
    cat client-certificate.crt
    echo "-----"
    kubectl config set-credentials default --client-certificate client-certificate.crt --client-key client-key.crt
else
    kubectl config set-credentials default --token=${KUBERNETES_TOKEN}
fi



if [ ! -z ${KUBERNETES_CERT} ]; then
  echo ${KUBERNETES_CERT} | base64 -d > ca.crt
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --certificate-authority=ca.crt
else
  echo "WARNING: Using insecure connection to cluster"
  kubectl config set-cluster default --server=${KUBERNETES_SERVER} --insecure-skip-tls-verify=true
fi

kubectl config set-context default --cluster=default --user=${PLUGIN_KUBERNETES_USER}
kubectl config use-context default

#kubectl get nodes

kubectl version
env
echo "=========="
kubectl get pods
echo "=========="
kubectl get pods --field-selector=status.phase==Running --sort-by=.status.startTime | tail -r
echo "=========="
echo kubectl get pods --field-selector=status.phase==Running --sort-by=.status.startTime | tail -r |grep "${PLUGIN_POD_NAME}" -m 1 |  awk '{print $1}'
SELECTED_POD=$(kubectl get pods --field-selector=status.phase==Running | grep "${PLUGIN_POD_NAME}" -m 1 | awk '{print $1}')
echo "${SELECTED_POD}"
echo "EXECUTING: kubectl exec -it ${SELECTED_POD} -c ${PLUGIN_CONTAINER_NAME} ${PLUGIN_CONTAINER_COMMAND}"
kubectl exec -it ${SELECTED_POD} -c ${PLUGIN_CONTAINER_NAME} ${PLUGIN_CONTAINER_COMMAND}

