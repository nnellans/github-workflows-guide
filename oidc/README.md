# Configuring OpenID Connect in Azure

This repo contains an example [Bicep template](deploy.bicep) that will deploy an Azure User-Assigned Managed Identity.  It will also create zero or more Federated Credentials for this identity.

These Federated Credentials allow you to use OpenID Connect within your GitHub workflows to authenticate with Azure.  In the example [parameter file](deploy.bicepparam), you'll find multiple examples on how to create Federated Credentials for usage by GitHub.

## GitHub - Deployment Steps

1. First, create the Managed Identity and the Federated Credential(s)
   - Use [any method](https://www.nathannellans.com/post/all-about-bicep-deploying-bicep-files) you'd like to deploy the Bicep template, one option is the Azure CLI:

     ```
     az deployment group create -g resourceGroupName -f deploy.bicep -p deploy.bicepparam
     ```
   - Use a good value for the Federated Credential `name` as this can not be changed later.
2. Assign some Azure RBAC roles to your new identity (whatever resources it will need permissions to)
3. In your GitHub Workflow use the Azure/login action to log into Azure using the new identity using password-less OIDC authentication.  [Check the docs](https://github.com/Azure/login#login-with-openid-connect-oidc-recommended) for more info.
4. Your GitHub Workflow can now run commands to interact with Azure resources.

## Note on Azure Portal

The Azure Portal currently doesn't show these credentials for a Managed Identity, you can use the Az CLI in this case:  `az cli identity federated-credential list`
