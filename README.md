# dps-stack

This project encapsulates the infrastructure and deployment code for DPS services and includes separate branches for each:

* `infrastructure` - Infrastructure code for building DPS services in AWS
* `deployment` - Deployment code for deploying DPS services to AWS

The remainder of this document contains information that is specific to the branch in which it appears.

## Deployment

This branch (i.e. `deployment`) contains the deployment code responsible for deploying DPS services and is composed of multiple Ansible roles which are used primarily in CI to provision Informix database servers and deploy groups of DPS services to a given environment.

Refer to the documentation for each of the following roles for more information:

* [database](roles/database/README.md) - for provisioning Informix database server(s), dbspaces, chunks
* [devices](roles/devices/README.md) - for database storage iSCSI device discovery and configuration
* [nfs](roles/nfs/README.md) - for configuring and mounting NFS shares
