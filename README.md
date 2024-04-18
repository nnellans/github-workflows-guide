# GitHub Workflow Guide

> [!WARNING]
> This is an advanced guide and assumes you already know the basics of GitHub Workflows.  Think of this more like an advanced cheat sheet.  I went through the documentation and captured any notes that I felt were important, and organized them into the README file you see here.  If you are new to GitHub Workflows, then I would suggest going through the GitHub docs first.

> [!IMPORTANT]
> This is a live document.  Some of the sections are still a work in progress.  I will be continually updating it over time.

---
# Table of Contents
- [Workflow Settings](#workflow-settings)
- [Triggers](#triggers)
- [Permissions for the GitHub Token](#permissions-for-the-github_token)
- [Default Settings](#default-settings)
- [Concurrency Settings](#concurrency-settings)
- [Variables](#variables)
- [Secrets](#secrets)
- [Jobs and Steps](#jobs--defining-the-work)
  - [Normal Jobs](#normal-jobs)
  - [Calling a Reusable Workflow](#jobs-that-call-a-reusable-workflow-job-level-template)
- [Reusable Actions vs. Reusable Workflows](#reusable-actions-vs-reusable-workflows)
- [Workflow Commands](#workflow-commands)
- [Links](#links)

---

# Workflow Settings

```yaml
# name of the workflow as shown in the GitHub UI
name: 'string' # optional, default is the path & name of the yaml file

# name to use for each run of the workflow
run-name: 'string' # optional, default is specific to how your workflow was triggered
```
- `run-name` can use expressions, and can reference the contexts of `github` and `inputs`

# Triggers
[Documentation - Triggering a Workflow](https://docs.github.com/en/actions/using-workflows/triggering-a-workflow)

```yaml
# option 1: single event with no options
on: push

# option 2: multiple events with no options
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
  schedule:
    - cron: '30 5,17 * * *'

#option 4: manual trigger where you can specify a max of 10 inputs
on:
  workflow_dispatch:
    inputs:
      someInputName:
        description:
        required: true | false
        default: 'defaultValue'
        type: boolean | number | string | choice
        options: # only when type: choice
          - option1
          - option2
      someOtherInput:
        description:
        required: true
        type: string

#option 5: if this workflow is used as a reusable workflow (job-level template)
on:
  workflow_call:
    inputs: # input parameters
      inputName1:
        description:
        required: true | false
        type: boolean | number | string # required
        default: something # if omitted, boolean = false, number = 0, string = ""
    secrets: # input secrets
      secretName1:
        description:
        required: true | false
    outputs: # output values
      outputName1:
        description:
        value:
```

- If multiple events are specified, only 1 event needs to occur to trigger the workflow
- If multiple events happen at the same time, then multiple runs of the workflow will trigger

# Permissions for the GITHUB_TOKEN
[Documentation - Permissions for the GitHub Token](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token)
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

More Info:
- When you enable GitHub Actions, a GitHub App will be installed on your repo
- The GITHUB_TOKEN secret is used to hold an installation access token for that app
- Before each job begins, GitHub fetches an unique installation access token for the job
  - The token expires when a job finishes or after a maximum of 24 hours.
  - The token can authenticate on behalf of the GitHub App installed on your repo
  - The token's permissions are limited to the repo that contains your workflow

# Default Settings
[Documentation - Setting Default Values for Jobs](https://docs.github.com/en/actions/using-jobs/setting-default-values-for-jobs)
- Creates a map of default settings that will be inherited downstream
- Supported scopes for `defaults`: workflow-level, job-level
  - The most specific defaults wins

```yaml
defaults:
  run:
    shell: bash
    working-directory: scripts
```

# Concurrency Settings
[Documentation - Using Concurrency](https://docs.github.com/en/actions/using-jobs/using-concurrency)
- Ensures that only one Workflow (or only one Job) from the specified concurrency group can run at a time
- Optional
- Supported scopes for `concurrency`: workflow-level, job-level

```yaml
# option 1: specify a concurrency group with default settings
concurrency: groupName

# option 2: specify a concurrency group with custom settings
concurrency:
  group: groupName
  cancel-in-progress: true # this will cancel any currently running workflows/jobs first
```
- `groupName` can be any string or expression (but limited to the `github` context only)
- Default behavior: If a Workflow/Job in the concurrency group is currently running, then any new Workflows/Jobs will be placed into a pending state and will wait for the original Workflow/Job to finish. Only the most recent Workflow/Job is kept in the pending state, and all others will be cancelled.

# Variables
[Documentation - Variables](https://docs.github.com/en/actions/learn-github-actions/variables)
### Environment Variables
- Cannot reference other variables in the same map
- Supported scopes for `env`: workflow-level, job-level, step-level
  - The most specific variable wins

```yaml
# defining environment variables (workflow-level)
env:
  KEY1: value
  KEY2: value

# defining environment variables (job-level)
jobs:
  someJobId:
    env:
      KEY1: value
      KEY2: value

# defining environment variables (step-level)
jobs:
  someJobId:
    steps:
      - name: someStepName
        env:
          KEY1: value
          KEY2: value

# use an environment variable in the workflow yaml:
${{ env.KEY }}

# use an environment variable inside of a script by just accessing the shell variable as usual:
linux:  $KEY
windows powershell:  $env:KEY
windows cmd:  %KEY%

# there are many default environment variables (see link above)
# most also have a matching value in the github context so you can use them in the workflow yaml
$GITHUB_REF and ${{ github.ref }}
```

### Configuration Variables
- Defined in the GitHub UI
- Can be shared by multiple Workflows
- Supported scopes for `vars`: organization-level, repo-level, repo environment-level
  - The most specific variable wins
- Configuration variable naming restrictions:
  - Can only contain alphanumeric characters or underscores
  - Must not start with the `GITHUB_` prefix or a number
  - Case insensitive
  - Must be unique at the level they are created at
- Configuration variable limits: 1,000 per Organization, 500 per Repo, 100 per Repo Environment

```yaml
# use a configuration variable in the workflow yaml:
${{ vars.KEY }}

# use a configuration variable inside of a script by just accessing the shell variable as usual:
linux:  $KEY
windows powershell:  $env:KEY
windows cmd:  %KEY%
```

---

# Secrets
[Documentation - Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- Defined in the GitHub UI
- Can be shared by multiple Workflows
- Supported scopes for `secrets`: organization-level, repo-level, repo environment-level
  - The most specific variable wins
- Secrets naming restrictions:
  - Can only contain alphanumeric characters or underscores
  - Must not start with the `GITHUB_` prefix or a number
  - Case insensitive
  - Must be unique at the level they are created at
- Secrets limits: 1,000 per Organization, 100 per Repo, 100 per Repo Environment
- Avoid using structured data (like JSON) as the value of your Secret. This helps to ensure that GitHub can properly redact your Secret in logs.
- Secrets cannot be directly referenced in `if:` conditionals
  - Instead, consider setting secrets as Job-level environment variables, then referencing the environment variables to conditionally run Steps in the Job

```yaml
# Actions can't directly use secrets that are defined via the GitHub UI
# However, you can use the secret as an input or environment variable
steps:
  - name: Hello world action
    env:   # Set the secret as an environment variable
      SOME_VAR: ${{ secrets.Key }
    uses: action/something@v1
    with:  # Set the secret as a value to an input
      someInput: ${{ secrets.Key }}
```

# Jobs / Defining the work

## Normal Jobs:
[Documentation - Using Jobs in a Workflow](https://docs.github.com/en/actions/using-jobs/using-jobs-in-a-workflow)

```yaml
jobs:
  symbolicJobName: # must be unique, start with a letter or underscore, and only contain letters, numbers, dashes, and underscores
    name: 'string' # friendly name that is shown in the GitHub UI
    runs-on: windows-latest | ubuntu-latest | macos-latest | self-hosted # specifies the Agent to run on
    needs: # Job dependencies
    if: # Job conditions, ${{ ... }} can optionally be used to enclose your condition
    continue-on-error: true # allows the Workflow to pass if this Job fails
    timeout-minutes: 10 # max time a Job can run before being cancelled. optional, default is 360
    permissions: # job-level GITHUB_TOKEN permissions
    defaults: # job-level defaults
    concurrency: # job-level concurrency group
    env: # job-level variables
      KEY: value
    
    environment: # see more below
    container: # see more below
    services: # see more below
    strategy: # see more below
    outputs: # see more below
    
    # list the Steps of this Job
    steps:

      # Use a GitHub Action
      - id: 'symbolicStepName' # optional
        name: 'string' # optional. friendly name that is shown in the GitHub UI
        if: # Step conditions, ${{ ... }} can optionally be used to enclose your condition
        continue-on-error: true # allows the Job to pass if this Step fails
        timeout-minutes: 10 # max time to run the Step before killing the process
        env: # Step-level variables
          KEY: value
        # option 1: use a public action
        uses: actions/checkout@v3 # owner/repo@ref, or owner/repo/folder@ref, where ref can be a branch, tag, or SHA
        # option 2: use an action file from a checked out repo
        uses: ./.github/actions/someFolder # make sure to checkout the repo first, no ref is supported as it uses the ref that you checked out
        # option 3: use an action from a public container image (only on Linux runners)
        uses: docker://alpine:3.8 # from Docker Hub
        uses: docker://ghcr.io/owner/image # from GitHub Packages Container Registry
        uses: docker://gcr.io/cloud-builders/gradle # from Google Container Registry
        # parameters to pass to the action, must match what is defined in the action
        with:
          param1: value1
          param2: value2
          # when using an action from a public container image (option 3)
          args: 'something' # this overwrites the CMD instruction in your Dockerfile
          entrypoint: 'something' # this overwrite the ENTRYPOINT instruction in your Dockerfile

      # Run a single-line Script
      - name: something2
        run: single-line command
        shell: bash | pwsh | python | sh | cmd | powershell
        working-directory: ./temp

      # Run a multi-line Script
      - name: something3
        run: |
          multi-line
          command
```

### Job.Environment
[Documentation - Using Environments for Deployment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- Specifies a GitHub environment to deploy to

```yaml
jobs:
  symbolicJobName:

    # option 1 - specify just an environment name
    environment: envName

    # option 2 - specify environment name and url
    environment:
      name: envName
      url: someUrl
```
- `envName` can be a string or any expression (except for the `secrets` context)

### Job.Container
[Documentation - Running Jobs in a Container](https://docs.github.com/en/actions/using-jobs/running-jobs-in-a-container)
- Defines a container that will run all Steps in this Job

```yaml
jobs:
  symbolicJobName:

    # option 1 - shortcut syntax specifying just the image
    container: node:14.16

    # option 2 - full syntax
    container:
      image: node:14.16
      credentials: # used to login to the container registry
        username:
        password:
      env: # specify environment variables inside the container
        KEY: value
      ports: # array of ports to expose on the container
        - 8080:80 # maps port 8080 on the docker host to port 80 on the container
      volumes: # array of volumes for the container to use, you can specify named Docker volumes, anonymous Docker volumes, or bind mounts on the host
        - source:destinationPath
      options: --cpus 1 # specifies additional options for the docker create command, --network is not supported
```
- Optional, if omitted the Job will run directly on the Agent and not inside a Container
- Only for Steps that don't already use their own Container
- Only supported on Microsoft-hosted Ubuntu runners, or self-hosted Linux runners
- `run` Steps inside of a Container will default to the `sh` shell, but you can override with `jobid.defaults.run` or `step.shell`

### Job.Services
[Documentation - About Service Containers](https://docs.github.com/en/actions/using-containerized-services/about-service-containers)
- Defines service container(s) that are used by your Job

```yaml
jobs:
  symbolicJobName:
    services:
      symbolicServiceName: # label used to access the service container
        image: nginx
        credentials: # used to login to the container registry
          username:
          password:
        env: # specify environment variables inside the service container
          KEY: value
        ports: # an array of ports to expose on the service container
          - 80
        volumes: # array of volumes for the container to use, you can specify named Docker volumes, anonymous Docker volumes, or bind mounts on the host
          - source:destinationPath
        options: --cpus 1 # specifies additional options for the docker create command, --network is not supported
```
- Optional
- Only supported on Microsoft-hosted Ubuntu runners, or self-hosted Linux runners
- Not supported inside a composite action

### Job.Strategy
[Documentation - Using a Matrix for your Jobs](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- Use variables to make one Job run multiple different times

```yaml
jobs:
  symbolicJobName:
    strategy:
      fail-fast: boolean # optional, default is true
      max-parallel: 5 # max number of matrix Jobs to run in parallel. optional, default is to run all Jobs in parallel (if enough runners are available)
      matrix: # the variables that will define the different permutations
        KEY1: [valueA, valueB]
        KEY2: [valueX, valueY, valueZ]
        include: # an extra list of objects to include
        exclude: # an extra list of objects to exclude
```
- Optional
- A different Job will run for each combination of KEYs, in this example that would be 6 different Jobs
- There is a max of 256 Jobs
- This will create a `matrix` context which lets you use `matrix.KEY1` and `matrix.KEY2` to reference the current iteration
- `exclude` is processed first before `include`, this allows you to add back combinations that were previously excluded
- When `fail-fast` is set to `true`, if any job in the matrix fails, then all in-progress and queued jobs in the matrix will be cancelled

### Job.Outputs
[Documentation - Defining Outputs for Jobs](https://docs.github.com/en/actions/using-jobs/defining-outputs-for-jobs)
- Specify outputs of this Job

```yaml
jobs:
  symbolicJobName:
    outputs: # map of outputs for this job
      key: value
      key: value
```
- These `outputs` are available to all downstream Jobs that **depend** on this Job
- Max of 1 MB per Output, and 50 MB total per Workflow
- Any expressions in an Output are evaluated at the end of a Job
- Any secrets in an Output are redacted and not sent to GitHub Actions

## Jobs that call a reusable workflow (job-level template):
[Documentation - Reusing Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- Only the following parameters are supported in such a Job

```yaml
jobs:
  symbolicJobName: # must be unique, start with a letter or underscore, and only contain letters, numbers, dashes, and underscores
    name: 'string' # friendly name that is shown in the GitHub UI
    needs: # Job dependencies
    if: # Job conditions, ${{ ... }} can optionally be used to enclose your condition
    permissions: # job-level GITHUB_TOKEN permissions
    concurrency: # job-level concurrency group
    # option 1: a reusable workflow from another repo (public or private)
    uses: org/repo/.github/workflows/file.yaml@ref # where ref can be a branch, tag, or SHA
    # option 2: a reusable workflow file from the same repo
    uses: ./.github/workflows/file.yaml # no ref is supported, it uses the same ref that triggered the parent workflow
    # parameters to pass to the template, must match what is defined in the template
    with:
      param1: value1
      param2: value2
    secrets: # secrets to pass to the template, must match what is defined in the template
      param1: ${{ secrets.someSecret }}
      param2: ${{ secrets.someOtherSecret }}
    secrets: inherit # pass all of the secrets from the parent workflow to the template. this includes org, repo, and environment secrets from the parent workflow
```

# Reusable Actions vs. Reusable Workflows
This list of features changes quite often. For example, Reusable Workflows being able to call other Reusable Workflows is fairly new.

| | Reusable Actions | Reusable Workflows |
| --- | --- | --- |
| Scope | Step-level | Job-level |
| Supports `env` variables<br />defined in parent Workflow | Yes | No |
| Input types | none (string) | boolean, number, string |
| Input Secrets | No[^1] | Yes |
| Supports Service Containers | No | Yes |
| Can specify Agent<br />(`runs-on`) | No | Yes |
| Filename | Must be `action.yml`<br />(so, 1 per folder) | Can be anything `.yml`<br />(so, many per folder) |
| Nesting | 10 levels | 4 levels |
| Logging | Summarized | Logging for each Job and Step |

[^1]: You can not directly pass GitHub Secrets to an Action. However, you could use a Secret for the value of one of the Action's input parameters, or you could use a Secret as the value of an environment variable that the Action could then read.

> [!TIP]
> - Example [action-composite.yaml](./action-composite.yaml) file showing the complete syntax for a reusable Composite Action
> - Example [action-docker.yaml](./action-docker.yaml) file showing the complete syntax for a reusable Docker Action
> - Example [action-javascript.yaml](./action-javascript.yaml) file showing the complete syntax for a reusable JavaScript Action

---

# Workflow Commands
[Documentation - Workflow Commands](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions)
- These are special commands that can be used to communicate with the runner machine
- They can do multiple different things, such as set environment variables, set output values, set debug messages, and more
- Depending on the specific Workflow Command, it can be used in one of two ways:
  - Using the `echo` command with a specific format
  - Writing to a file

```bash
# Some examples (all using Bash), see the docs for a full reference

# Print a debug message to the log
echo "::debug::This is a debug message"

# Masking a string value so it's not shown in the logs
echo "::add-mask::This value will be masked"

# Setting an environment variable
echo "KEY=value" >> "$GITHUB_ENV"

# Setting an output parameter
echo "KEY=value" >> "$GITHUB_OUTPUT"
```

> [!WARNING]
> For reusable workflows, any variables you set in the `env` context inside of the reusable workflow will NOT be available in the parent workflow. To get around this, the reusable workflow could create an `output` which can then be consumed by the parent workflow.

> [!WARNING]
> A masked value can NOT be passed from one Job to another Job in GitHub Actions
> - [GitHub Discusson](https://github.com/orgs/community/discussions/13082) on this topic
> - The [official docs](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#example-masking-and-passing-a-secret-between-jobs-or-workflows) want you to use a secret store, such as Azure KeyVault, to solve this problem. In effect, Job 1 uploads the value to the secret store, and then Job 2 downloads the value from the secret store.

---

# Links
- official github actions: https://github.com/orgs/actions/repositories
- official azure actions: https://github.com/marketplace?query=Azure&type=actions&verification=verified_creator
