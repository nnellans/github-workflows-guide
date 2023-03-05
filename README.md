# Workflow-related

```yaml
# name of the workflow as shown in the GitHub UI:
name: 'string' # optional, default is the path & name of the yaml file

# name to use for each run of the workflow:
run-name: 'string' # optional, default is specific to how your workflow was triggered
```
- `run-name` can use expressions, and can reference the contexts of 'github' and 'inputs'

# Triggers
https://docs.github.com/en/actions/using-workflows/triggering-a-workflow <br />
```yaml
# option 1: single event with no options
on: push

#option 2: multiple events with no options
# first form
on: [push, fork]

# second form
on:
  - push
  - fork

#option 3: events with options
on:
  push:
    branches:
    - blahblah
  issues:
    types:
    - opened

#option 4: if this workflow is used as a template (reusable workflow)
on:
  workflow_call:
    inputs: # input parameters
      inputName1:
        description:
        required: true | false
        type: boolean | number | string # required
        default: something # if omitted, boolean = false, number = 0, string = ""
      inputName2:
    secrets: # input secrets
      secretName1:
        description:
        required: true | false
    outputs: # output values
      outputName1:
        description:
        value:
```

- Only one event needs to occur to trigger the workflow
- If multiple events happen at the same time, then multiple runs of the workflow will trigger

# Permissions for the GITHUB_TOKEN
https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token
- Use this if you want to modify the default permissions granted to the GITHUB_TOKEN
- Optional, the default can be set (by an admin) to either a `permissive` preset or a `restricted` preset (more info at the link above)
- As a good security practice, you should grant the GITHUB_TOKEN the least required access
- When the `permissions` key is used, all unspecified permissions are set to `none`, with the exception of the `metadata` scope, which always gets `read` access.
- Supported scopes for `permissions`: workflow-level, job-level

```yaml
# option 1: full syntax
permissions:
  actions: read | write | none
  checks: read | write | none
  contents: read | write | none
  deployments: read | write | none
  id-token: read | write | none
  issues: read | write | none
  discussions: read | write | none
  packages: read | write | none
  pages: read | write | none
  pull-requests: read | write | none
  repository-projects: read | write | none
  security-events: read | write | none
  statuses: read | write | none

# option 2: shortcut syntax to provide read or write access for all scopes
permissions: read-all | write-all

# option 3: shortcut syntax to disable permissions to all scopes
permissions: {}
```

# Default Settings
https://docs.github.com/en/actions/using-jobs/setting-default-values-for-jobs
- Creates a map of default settings that will be inherited
- Supported scopes for `defaults`: workflow-level, job-level
  - The most specific defaults wins

```yaml
defaults:
  run:
    shell: bash
    working-directory: scripts
```

# Concurrency Settings
https://docs.github.com/en/actions/using-jobs/using-concurrency
- Ensures that only one Workflow (or only one Job) from the specified concurrency group can run at a time
- Optional
- Supported scopes for `concurrency`: workflow-level, job-level

```yaml
# option 1: specify a concurrency group with default settings
concurrency: groupName

# option 2: specify a concurrency group with custom settings
concurrency:
  group: groupName
  cancel-in-progress: true # this will cancel any currently running workflows/jobs first, to ensure this will be the only one that runs
```
- `groupName` can be any string or expression (but limited to the `github` context only)
- Default behavior: If a Workflow/Job in the concurrency group is currently running, then any new Workflows/Jobs will be placed in pending state and will wait for the original Workflow/Job to finish. Only the latest Workflow/Job is kept in the pending state, all others will be cancelled.

# Variables
https://docs.github.com/en/actions/learn-github-actions/variables
- cannot reference other variables in the same map
- Supported scopes for `env`: workflow-level, job-level, step-level
  - The most specific variable wins

```yaml
# defining variables
env:
  KEY: value
  KEY: value

# use a variable inside of a script on the runner by just accessing an environment variable as usual:
linux:  $KEY
windows powershell:  $env:KEY

# use a variable in the workflow yaml:
${{ env.KEY }}

# there are many default environment variables (see link above)
# most also have a matching value in the github context so you can use them in the workflow yaml
$GITHUB_REF and ${{ github.ref }}

# use configuration variables that are defined via the GitHub UI:
${{ vars.CONFIGKEY }}

# use secrets that are defined via the GitHub UI:
${{ secrets.SECRETKEY }}
```

# Jobs / Defining the work

Normal Jobs:
- https://docs.github.com/en/actions/using-jobs/using-jobs-in-a-workflow
```yaml
jobs:
  symbolicJobName: # must be unique, start with a letter or underscore, and only contain letters, numbers, dashes, and underscores
    name: 'string' # friendly name that is shown in the GitHub UI
    runs-on: windows-latest | ubuntu-latest | macos-latest | self-hosted # specifies the Agent to run on
    needs: # Job dependencies
    if: # Job conditions, ${{ ... }} can optionally be used to enclose your condition
    environment: # the environment to deploy to
    continue-on-error: true # allows the Workflow to pass if this Job fails
    timeout-minutes: 10 # max time a Job can run before being cancelled. optional, default is 360
    permissions: # job-level GITHUB_TOKEN permissions
    defaults: # job-level defaults
    concurrency: # job-level concurrency group
    env: # job-level variables
    
    # https://docs.github.com/en/actions/using-jobs/running-jobs-in-a-container
    # run all Steps in this Job on the following Container (only for Steps that don't already specify their own Container)
    # only supported on Microsoft-hosted Ubuntu runners, or self-hosted Linux runners
    # 'run' Steps inside a Container will default to the sh shell, overwrite with jobid.defaults.run, or step.shell
    
    # shortcut syntax
    container: node:14.16
    
    # full syntax
    container:
      image: node:14.16
      credentials:
        username:
        password:
      env:
      ports:
      volumes:
      options:
    
    # https://docs.github.com/en/actions/using-containerized-services/about-service-containers
    # define service containers
    services:
      symbolicServiceName:
        image: nginx
        credentials:
          username:
          password:
        env:
        ports:
        volumes:
        options:
    
    # https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs
    strategy:
      fail-fast:
      max-parallel:
      matrix:
    
    # https://docs.github.com/en/actions/using-jobs/defining-outputs-for-jobs
    outputs: # specify outputs of this Job
    
    # list the Steps of this Job
    steps:

    # Step that uses a GitHub Action
    - id: 'symbolicStepName'
      name: 'string' # friendly name that is shown in the GitHub UI
      if: # Step conditions, ${{ ... }} can optionally be used to enclose your condition
      continue-on-error: true # allows the Job to pass if this Step fails
      timeout-minutes: 10 # max time to run the Step before killing the process
      env: # Step-level variables
      uses: actions/checkout@v3
      with:
        param1: value1
        param2: value2
        args: 'something' # this overwrites the CMD instruction in your Dockerfile
        entrypoint: 'something' # this overwrite the ENTRYPOINT instruction in your Dockerfile

    # Step that runs a single-line Script
    - name: something2
      run: single-line command
      shell: bash | pwsh | python | sh | cmd | powershell
      working-directory: ./temp

    # How to specify a multi-line Script
    - name: something3
      run: |
        multi-line
        command
```

Jobs that calls a Template:
- https://docs.github.com/en/actions/using-workflows/reusing-workflows
- Only the following parameters are supported in such a Job
```
jobs:
  symbolicJobName: # must be unique, start with a letter or underscore, and only contain letters, numbers, dashes, and underscores
    name: 'string' # friendly name that is shown in the GitHub UI
    needs: # Job dependencies
    if: # Job conditions, ${{ ... }} can optionally be used to enclose your condition
    permissions: # job-level GITHUB_TOKEN permissions
    concurrency: # job-level concurrency group
    uses: org/repo/.github/workflows/file.yaml@ref # the Job template to reference
    with: # parameters to pass to the template, must match what is defined in the template
      param1: value1
      param2: value2
    secrets: # secrets to pass to the template, must match what is defined in the template
      param1: ${{ secrets.someSecret }}
      param2: ${{ secretos.someOtherSecret }}
    secrets: inherit # pass all of the secrets from the parent workflow to the template. this includes org, repo, and environment secrets from the parent workflow
```

# Links
- official github actions: https://github.com/orgs/actions/repositories
- official azure actions: https://github.com/marketplace?query=Azure&type=actions&verification=verified_creator
