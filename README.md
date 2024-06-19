# NRI Plugins

## Install Topology-Aware Policy with Last Level Cache (LLC) Affinity ##

**Prerequisites**
* Developer Environment:
    *	Go1.22+
    *	Docker v26.1.3
    *	make
* Orchestration Worker Node:
    *	CRI-O 1.26+ (OpenShift 4.13+)
    *	ContainerD 1.7+ (Kubernetes 1.24+)
* Orchestration Control-Plane:
    *	Helm v3.0+

**Installation**\
*Developer Environment*
On the developer node, clone the NRI-Plugin repository:
```
git clone https://github.com/AMDEPYC/nri-plugins.git
```

Change directory to the cloned repository and build the container images using the following command:
```
make build-images
```

Upon successful build, the following docker images will be present:
```console
REPOSITORY                                                      TAG              IMAGE ID       SIZE
ghcr.io/containers/nri-plugins/nri-plugins-operator-bundle      v0.0.0-unknown   e339b02e1f61   141kB
ghcr.io/containers/nri-plugins/nri-plugins-operator             v0.0.0-unknown   583e23c85218   574MB
config-manager                                                  v0.0.0-unknown   868776e81a56   6.38MB
nri-sgx-epc                                                     v0.0.0-unknown   5f995c15156b   19.7MB
nri-memtierd                                                    v0.0.0-unknown   2b2d63fdcc07   25.9MB
nri-memory-qos                                                  v0.0.0-unknown   92a060d207a3   19.7MB
nri-resource-policy-template                                    v0.0.0-unknown   f31a75abb1a2   64.2MB
nri-resource-policy-balloons                                    v0.0.0-unknown   e1ad39c1f87b   64.6MB
nri-resource-policy-topology-aware                              v0.0.0-unknown   da2533a94762   64.8MB
```

Tag the config-manager and nri-resource-policy-topology-aware docker images to be pushed to your Github or Docker container registry:
```
docker tag config-manager:v0.0.0-unknown <Registry-Host>/config-manager:unstable
docker tag nri-resource-policy-topology-aware:v0.0.0-unknown <Registry-Host>/nri-resource-policy-topology-aware:unstable
```

Push the two container images to your container repository:
```
docker push <Registry-Host>/config-manager:unstable
docker push <Registry-Host>/nri-resource-policy-topology-aware:unstable
```

*Control-Plane*
On the control-plane, create a values.yaml to populate the helm chart:
```
initContainerImage:
  name: <Registry-Host>/config-manager
  tag: unstable
  pullPolicy: IfNotPresent

image:
  name: <Registry-Host>/nri-resource-policy-topology-aware
  tag:  unstable
  pullPolicy: IfNotPresent
```
Ensure the image names point to your repository.

Install the NRI Topology-Aware Policy with LLC affinity:
```
helm install -n kube-system llc -f values.yaml deployments/helm/topology-aware --set nri.patchRuntimeConfig=true
```

Verify the NRI Topology Aware Policy is running in the kube-system namespace:
```
kubectl get pods -n kube-system
```

Any Guaranteed Pod will now automatically be deployed using the NRI Topology-Aware Policy with LLC affinity on the worker-node.

To uninstall the NRI Topology-Aware Policy:
```
helm delete -n kube-system llc
```

To enable debugging of the NRI Topology Aware Policy or change the Reserved CPUs, change the values.yaml file to reflect the following and redeploy:
```
initContainerImage:
  name: <Registry-Host>/config-manager
  tag: unstable
  pullPolicy: IfNotPresent

image:
  name: <Registry-Host>/nri-resource-policy-topology-aware
  tag:  unstable
  pullPolicy: IfNotPresent

  config:
    reservedResources:
      cpu: 750m
    log:
      debug:
        - '*'
      source: true
      klog:
        skip_headers: true
  
  extraEnv:
    LOGGER_DEBUG: all
```

Run the following command to view the debug logs of the NRI Topology Aware Policy:
```
kubectl logs -n kube-system <nri-resource-policy-topology-aware-xxxxx>
```

This repository also contains a collection of community maintained NRI plugins.

Currently following plugins are available:

| Name                | Type              |
|---------------------|:-----------------:|
| [Topology Aware][1] | resource policy   |
| [Balloons][2]       | resource policy   |
| [Memtierd][3]       | memory management |
| [Memory-qos][4]     | memory management |
| [SGX-EPC][5]        | memory management |

[1]: https://containers.github.io/nri-plugins/stable/docs/resource-policy/policy/topology-aware.html
[2]: https://containers.github.io/nri-plugins/stable/docs/resource-policy/policy/balloons.html
[3]: https://containers.github.io/nri-plugins/stable/docs/memory/memtierd.html
[4]: https://containers.github.io/nri-plugins/stable/docs/memory/memory-qos.html
[5]: https://containers.github.io/nri-plugins/stable/docs/memory/sgx-epc.html

See the [NRI plugins documentation](https://containers.github.io/nri-plugins/) for more information.
