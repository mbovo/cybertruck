# Google Kubernetes Engine

This repo contains all stuff in order to bring up a kubernetes cluster on google GKE to test the demo presented during meetup
This tutorial leverages the Google Cloud Platform to streamline provisioning of the compute infrastructure required to bootstrap a Kubernetes GKE cluster. [Sign up](https://cloud.google.com/free/) for \$300 in free credits.

[Estimated cost](https://cloud.google.com/products/calculator/#id=b1213460-d8ed-4764-98a7-c9088d3b0a1d) about 1.43€ / day

## Requirements

In order to use terraform gcs backend you need to create a storage bucket on your google project:

https://console.cloud.google.com/storage/browser

The bucket **must** be named `gke-from-scratch-terraform-state`

The user account used to handle the terraform process must be granted with the following roles:

```bash
Amministratore ambienti e oggetti Storage
Amministratore Compute
Amministratore risorse organizzazione Compute
Amministratore Kubernetes Engine
Amministratore cluster Kubernetes Engine
Utente account di servizio
```

## Usage

### Prepare terraform and check the plan

```bash
terraform init
```

```bash
terraform plan -var-file=vars.tfvars -var credential_file=$HOME/.config/gcloud/application_default_credentials.json
```

Please note you have to provide google cloud credential file, please see https://cloud.google.com/docs/authentication/production

### Apply the infrastructure

```bash
terraform plan -var-file=vars.tfvars -var credential_file=$HOME/.config/gcloud/application_default_credentials.json
```

### Retrieve kubeconfig

```bash
gcloud container clusters get-credentials cybertruck-cluster --zone europe-north1 --project cybertruck
```

### Destroy and Cleanup

Remember to cleanup the infrastructure in order to avoid extra billing

```bash
terraform destroy -var-file=vars.tfvars -var credential_file=$HOME/.config/gcloud/application_default_credentials.json
```
