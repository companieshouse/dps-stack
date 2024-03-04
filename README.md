# dps-stack

This project encapsulates the infrastructure and deployment code for DPS services and includes separate branches for each:

* `infrastructure` - Infrastructure code for building DPS services in AWS
* `deployment` - Deployment code for deploying DPS services to AWS

The remainder of this document contains information that is specific to the branch in which it appears.

## Deployment

This branch (i.e. `deployment`) contains the deployment code responsible for deploying DPS services and contains several Ansible playbooks which are used in CI/CD pipelines to provision servers in AWS:

- [database.yml](database.yml) - provision Informix database server(s), dbspaces, and chunks
- [devices.yml](devices.yml) - discover and configure iSCSI devices
- [nfs.yml](nfs.yml) - configure and mount persistent NFS shares
