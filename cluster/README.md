# In Cluster Services for PKS

These services can be deployed on top of Kubernetes API and generally tested with PKS.

**Folder Contents**

- [gangway](./gangway/README.md) : Heptio [Gangway](https://github.com/heptiolabs/gangway) on PKS
- ingress : Nginx Ingress controller specs
- Logging : Sink Controller spec for PKS to enable pod to remote Syslog log streaming
- Weave-Scope : Weave Scope application
- storageclasses : various storageclass specs