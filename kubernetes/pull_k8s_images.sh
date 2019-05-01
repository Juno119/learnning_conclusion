#!/bin/bash
set -e
KUBE_VERSION=v1.14.0
KUBE_PAUSE_VERSION=3.1
ETCD_VERSION=3.3.10
DNS_VERSION=1.3.1
GCR_URL=k8s.gcr.io
PRIVATE_URL=junolu

images=(
 kube-apiserver:${KUBE_VERSION}
 kube-controller-manager:${KUBE_VERSION}
 kube-scheduler:${KUBE_VERSION}
 kube-proxy:${KUBE_VERSION}
 pause:${KUBE_PAUSE_VERSION}
 etcd:${ETCD_VERSION}
 coredns:${DNS_VERSION}
)



for imageName in ${images[@]} ; 
do

    docker pull $PRIVATE_URL/$imageName

    docker tag  $PRIVATE_URL/$imageName $GCR_URL/$imageName

    docker rmi $PRIVATE_URL/$imageName

done

docker images
