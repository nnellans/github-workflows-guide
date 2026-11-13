# GitHub Actions - Azure Federated Credentials using OpenID Connect 
This repo contains an example [Bicep template](deploy.bicep) that will deploy an Azure User-Assigned Managed Identity.  It will also create zero or more Federated Credentials for this identity.

These Federated Credentials can be used by your GitHub Actions workflow.  In the example [parameter file](deploy.bicepparam), you'll find examples on how to create Federated Credentials.

## GitHub - Deployment Steps
1. First, create the Managed Identity and the Federated Credential
   - Use [any method](https://www.nathannellans.com/post/all-about-bicep-deploying-bicep-files) you'd like to deploy the Bicep template, one option is the Azure CLI:

     ```
     az deployment group create -g resourceGroupName -f deploy.bicep -p deploy.bicepparam
     ```
   - Use a good value for the Federated Credential `name` as this can not be changed later.
2. Assign the new Managed Identity to an RBAC role on an Azure resource that it will need access to.
3. Update your GitHub repo as required.
