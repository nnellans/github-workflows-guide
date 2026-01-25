# GitHub Workflow Guide

- Version: 1.2.0
- Author:
  - Nathan Nellans
  - Email: me@nathannellans.com
  - Web:
    - https://www.nathannellans.com
    - https://github.com/nnellans/github-workflows-guide

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
- [YAML Anchors & Aliases](#yaml-anchors--aliases)
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
[Documentation - Triggering a workflow](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow)

[Documentation - Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)

```yaml
# option 1: single event with no options
on: push

# option 2: multiple events with no options
on:
  - push
  - fork

# option 3: events with options
on:
  push:
    branches:
      - blahblah
  issues:
    types:
      - opened
  schedule:
    - cron: '30 5,17 * * *'

# option 4: manual trigger where you can specify a max of 25 inputs
on:
  workflow_dispatch:
    inputs:
      someInputName:
        description:
        required: true | false
        default: 'defaultValue'
        type: boolean | number | string | choice | environment
        options: # only when type: choice
          - option1
          - option2
      someOtherInput:
        description:
        required: true
        type: string

# option 5: if this workflow is used as a reusable workflow (job-level template)
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
[Documentation - Modifying the permissions for the GITHUB_TOKEN](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token#modifying-the-permissions-for-the-github_token)

[Documentation - Workflow Syntax - Permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)

- Use this if you want to modify the default permissions granted to the `GITHUB_TOKEN`
- Optional, the default can be set in the repo settings (by an admin) to either a `permissive` preset or a `restricted` preset
- As a good security practice, you should grant the `GITHUB_TOKEN` the least required access
- When the `permissions` key is used, all unspecified permissions are set to `none`, with the exception of the `metadata` scope, which always gets `read` access.
- Supported scopes for `permissions`: workflow-level, job-level

```yaml
# option 1: full syntax
permissions:
  actions: read | write | none
  artifact-metadata: read | write | none
  attestations: read | write | none
  checks: read | write | none
  contents: read | write | none
  deployments: read | write | none
  discussions: read | write | none
  id-token: read | write | none
  issues: read | write | none
  models: read | none
  packages: read | write | none
  pages: read | write | none
  pull-requests: read | write | none
  security-events: read | write | none
  statuses: read | write | none

# option 2: shortcut syntax to provide read or write access for all scopes
permissions: read-all | write-all

# option 3: shortcut syntax to disable permissions to all scopes
permissions: {}
```

More Info:
- When you enable GitHub Actions, then a GitHub App will be installed on your repo
  - The `GITHUB_TOKEN` secret is used to hold an installation access token for that app
- Before each job begins, GitHub fetches an unique installation access token for the job
  - The token expires when a job finishes or after a maximum of 24 hours.
  - The token can authenticate on behalf of the GitHub App installed on your repo
  - The token's permissions are limited to the repo that contains your workflow
- [My blog post all about GitHub Apps and the `GITHUB_TOKEN`](https://www.nathannellans.com/post/github-apis-github-tokens-and-github-action-workflows)

# Default Settings
[Documentation - Setting a default shell and working directory](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/set-default-values-for-jobs)
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
[Documentation - Control the concurrency of workflows and jobs](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
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
[Documentation - Store information in variables](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables)
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
[Documentation - Using secrets in GitHub Actions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)
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
[Documentation - Using jobs in a workflow](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-jobs)

```yaml
jobs:
  symbolicJobName: # must be unique, start with a letter or underscore, and only contain letters, numbers, dashes, and underscores
    name: 'string' # friendly name that is shown in the GitHub UI
    runs-on: windows-latest | ubuntu-slim | ubuntu-latest | macos-latest | self-hosted # specifies the Agent to run on
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
    snapshot: # see more below
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
        # there is currently no way to authenticate to the specified registry, so be careful of rate limits. also, that means private registries are not supported
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
[Documentation - Managing environments for deployment](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)
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
[Documentation - Running jobs in a container](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/run-jobs-in-a-container)
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

### Job.Snapshot
[Documentation - Using custom images](https://docs.github.com/en/actions/how-tos/manage-runners/larger-runners/use-custom-images)
- For creating custom images that you can use with GitHub-hosted larger runners
- Lets you preinstall tools, dependencies, and configurations into your runner image
- Each job that includes the `snapshot` keyword creates a separate image
- Each successful run of a job that includes the `snapshot` keyword creates a new version of that image

```yaml
jobs:
  symbolicJobName:

    # option 1 - string syntax
    # just specify an image name, this either creates a new image (1.0.0) or adds a new (minor) version to the existing image
    # can not specify a version number with this syntax
    snapshot: customImageName

    # option 2 - mapping syntax
    # lets you specify a version number, only major & minor versions are supported, patch version are not supported
    snapshot:
      image-name: customImageName
      version: 2.*
```

### Job.Services
[Documentation - Communicating with Docker service containers](https://docs.github.com/en/actions/tutorials/use-containerized-services/use-docker-service-containers)
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
[Documentation - Running variations of jobs in a workflow](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations)
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
[Documentation - Passing information between jobs](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs)
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
[Documentation - Reuse Workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)

[Documentation - Reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations)

- Only the following parameters are supported in such a Job

```yaml
jobs:
  symbolicJobName: # must be unique, start with a letter or underscore, and only contain letters, numbers, dashes, and underscores
    name: 'string' # friendly name that is shown in the GitHub UI
    needs: # Job dependencies
    if: # Job conditions, ${{ ... }} can optionally be used to enclose your condition
    permissions: # job-level GITHUB_TOKEN permissions
    concurrency: # job-level concurrency group
    strategy: # define a matrix for parallel jobs
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
| Filename | Must be `action.yml`<br />(so, 1 per folder) | Can be anything `.yml`<br />(must be in `.github/workflows/` -<br />no subfolders) |
| Nesting | 10 levels | 10 levels |
| Logging | Summarized | Logging for each Job and Step |

[^1]: You can not directly pass GitHub Secrets to an Action. However, you could use a Secret for the value of one of the Action's input parameters, or you could use a Secret as the value of an environment variable that the Action could then read.

> [!TIP]
> - Example [action-composite.yaml](./action-composite.yaml) file showing the complete syntax for a reusable Composite Action
> - Example [action-docker.yaml](./action-docker.yaml) file showing the complete syntax for a reusable Docker Action
> - Example [action-javascript.yaml](./action-javascript.yaml) file showing the complete syntax for a reusable JavaScript Action

---

# Workflow Commands
[Documentation - Workflow commands for GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands)
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
> - [GitHub Discussion](https://github.com/orgs/community/discussions/13082) on this topic
> - The [official docs](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#example-masking-and-passing-a-secret-between-jobs-or-workflows) want you to use a secret store, such as Azure KeyVault, to solve this problem. In effect, Job 1 uploads the value to the secret store, and then Job 2 downloads the value from the secret store.

### Multi-Line Values

If you need to mask a sensitive, multi-line value, then you can do the following:

```bash
SENSITIVE="$(command that outputs a sensitive, multi-line value)"
while read -r line
do
  echo "::add-mask::${line}"
done <<< "$SENSITIVE"

# In this example, the sensitive value will be assigned to the variable called SENSITIVE
# The command used on line 1 will be logged in plain-text, so it must not include sensitive values (but, this is a plain-text YAML file, so you would never do that in the first place, right?)
# The value assigned to the variable is then read, line-by-line, and a mask is applied to each line's value

# An example of a safe command you could use:
SENSITIVE="$(az keyvault secret show --name MySecretName --vault-name MyVaultName --query value --output tsv)"
```

If you need to set an environment variable or an output to use a multi-line value, then you can do the following:

```bash
# Make sure the delimiter you're using won't occur on a line of its own within the value
{
  echo 'KEY<<DELIMETER'
  command(s) that produce multiple lines of output
  echo DELIMETER
} >> "$GITHUB_ENV"
```

---

# YAML Anchors & Aliases
[Documentation - YAML anchors and aliases](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations)
- GitHub Actions supports a limited set of YAML features like anchors and aliases
- Use `&symbolicName` to define the anchor (the section you want to capture)
- Use `*symbolicName` to define one or more aliases, where each one will be a copy of the anchor
- YAML Merge Keys, specified by `<<:` are not yet supported by GitHub. This means each anchor must be copied exactly as-is, with no way to add an override of a single value

```yaml
jobs:

  firstSymbolicJobName:
    env: &anchorName # this defines the section that will become the anchor
      KEY1: value1
      KEY2: value2
      KEY3: value3

  secondSymbolicJobName:
    env: *anchorName # this defines an alias (the values in the anchor will be copied here)
```

---

# Links
- official github actions: https://github.com/orgs/actions/repositories
- official azure actions: https://github.com/marketplace?query=Azure&type=actions&verification=verified_creator
