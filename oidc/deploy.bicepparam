using 'deploy.bicep'

param name = 'identityName'
param location = 'EastUS2'
param tags = {
  tagName1: 'tagValue1'
  tagName2: 'tagValue2'
}
param fedCreds = [

  // Example showing the default GitHub subject claim template
  // This is the "mutable" format for repos created before July 15, 2026
  {
    name: 'GitHubActions-FederatedCredential-default-mutable'
    audiences: ['api://AzureADTokenExchange']
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:<OwnerName>/<RepoName>:environment:<EnvName>'        // Example pointing at an environment
    subject: 'repo:<OwnerName>/<RepoName>:pull_request'                 // Example pointing at pull requests
    subject: 'repo:<OwnerName>/<RepoName>:ref:refs/heads/<BranchName>'  // Example pointing at a branch
    subject: 'repo:<OwnerName>/<RepoName>:ref:refs/tags/<TagName>'      // Example pointing at a tag
  }

  // Example showing the default GitHub subject claim template
  // This is the "immutable" format for repos created after July 15, 2026
  // Also applies to old repos that have been renamed, transferred, or that opt-in to the immutable format
  {
    name: 'GitHubActions-FederatedCredential-default-immutable'
    audiences: ['api://AzureADTokenExchange']
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:<OwnerName>@<OwnerID>/<RepoName>@<RepoID>:environment:<EnvName>'        // Example pointing at an environment
    subject: 'repo:<OwnerName>@<OwnerID>/<RepoName>@<RepoID>:pull_request'                 // Example pointing at pull requests
    subject: 'repo:<OwnerName>@<OwnerID>/<RepoName>@<RepoID>:ref:refs/heads/<BranchName>'  // Example pointing at a branch
    subject: 'repo:<OwnerName>@<OwnerID>/<RepoName>@<RepoID>:ref:refs/tags/<TagName>'      // Example pointing at a tag
  }

  // Example showing when a custom GitHub subject claim template is used
  {
    name: 'GitHubActions-FederatedCredential-custom'
    audiences: ['api://AzureADTokenExchange']
    issuer: 'https://token.actions.githubusercontent.com'
    subject: '<claim1>:<value>:<claim2>:<value>:<claimN>:<value>'
  }

  // Example showing a "Flexible" Federated Credential that uses a Claims Matching Expression
  {
    name: 'GitHubActions-FederatedCredential-flexible'
    audiences: ['api://AzureADTokenExchange']
    issuer: 'https://token.actions.githubusercontent.com'
    claimsMatchingExpression: {
      languageVersion: 1
      value: 'claims[\'sub\'] matches \'*\' and claims[\'repository_owner_id\'] eq \'<OwnerID>\''
    }
  }

]
