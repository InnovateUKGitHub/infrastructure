# BISDigital Infrastructure

Thank you for visiting the BIS Digital Infrastructure repository. We are in
very early phases of establishing our technical strategy, but have decided to
commit to an early release procedure. 

We have carefully selected the technology based on current trends in
infrastructure, and those are:

  * Immutable
  * Serverless
  * 12 factor
  * Cloud

Each project has its own implementations in the technology and is documented
accordingly. Please refer to the documentation embedded herein. 

The platform of choice is RHEL7. 

## vagrant

Vagrant is the first tier of development. This directory is the home of vagrant
implementations. Each directory within is specific to each project.

## ansible

Ansible is the configuration management engine of choice. It is used to push
instructions to cloud providers and ensure idempotent configuration of each
platform. The ansible directory is inclusive of all projects as they are 
implemented as playbooks and roles.

The vagrant-dotvm plugin allows YAML to be used for modelling infrastructures.
It also extends `vagrant` to use a group command. Groups are simply tags to
name machines and operate on them as one entity. Therefore, one may use
`vagrant group <cmd> <group>`. Please see enclosed documentation.
