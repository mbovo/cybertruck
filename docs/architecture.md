# Architecture

Cybertruck is meant to be:

- `Composable` driven by a configuration file provided.
- `Easy` hide the complexity of installation/configuration but without "black magic" effect.
- `Understandable` all the automation should be written using standard tools ... Everyone should be able to extend without specific training.

This is the reason why this project right now is a bunch of stuff glued together by ansible and some bash magic.

The `cluster` entrypoint is a bash script which do the following:

- ensure requirements are installed and executables are in PATH
- create a python virtualenv
- install ansible and some libraries into the newly created virtualenv
- enter the virtualenv and execute an ansible playbook

Which ansible playbook will be executed is given by the stage `-s` flag of the script. Playbooks are located into `./ansible/playbooks`

## Cluster Creation

The `create.yml` playbook simply include the `setup.yml` playbok from the directory of the cluster type chosen in configuration file.
For instance if you have selected `gke` cluster type the `setup.yml` included by ansible is located to `./gke/setup.yml`
Here you can insert everything you need to bring up a cluster. In the case of GKE another tool will be used: terraform.

## Cluster Deletion

Similar to creation phase there is a `teardown.yml` playbook included by `ansible/playbooks/delete.yml` located in the subdirectory named like the cluster type.

## Cluster Configuration

The `configure` stage is quite atypical. It will perform all other steps reading from values in configuration file.
Let see how it proceed:

First of all it includes the logic that handle `namespaces` creation and configuration. Then the logic to handle `helm` charts installation, the logic for `kubectl_raw` commands and last the custom `addons` behaviors.
As you can see there are many `ansible tags` you can use to narrow the execution only to a subset of configuration steps (like in `cluster -s configure -t namespaces`)

These logic are located in specific roles (`ansible/roles/`) and are meant not to be edited by end user, with the exception of [addons](addons.md)

```yaml
- import_role:
    name: "namespaces"
  tags:
    - namespaces
    - ns

- import_role:
    name: helm
  tags:
    - helm
    - charts

- import_role:
    name: kubectl
  tags:
    - raw
    - kubectl

- include_role:
    name: "{{ currentAddon.role }}"
  loop: "{{ kubernetes.addons }}"
  loop_control:
    loop_var: currentAddon
  tags:
    - addons
```
