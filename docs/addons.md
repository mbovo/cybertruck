# Cybertruck Addons

An `addon` is simply a modular procedure to install or configure something specific into the kubernetes cluster. It can use variables from `kubernetes.defaults` (see [configuration](configuration.md)) and custom ones.

Technically speaking an addon is an [ansible role](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) and can do everything ansible is capable to do in order to perform its installation/configuration steps.

Looking to the addons key in the configuration files you can see it is a list of objects with the following syntax:

- `role` is a the ansible role name to load
- `namespace` is the target namespace into kubernetes cluster
- `vars` is an optional map of variables used internally (when write the ansible role use this field as an optional and possibile not defined one )

```yaml
kubernets:
  addons:
    - role: ingress-kind-proxy
      namespace: ingress
      vars:
        releaseName: ingress
        publishAddr: "10.10.10.50"
```
