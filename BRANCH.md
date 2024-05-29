# Repository Branching Strategy

## Overview

This guide documents the branching strategy for this repository.
Follow the instructinos in the sections below when creating or merging branches.

## Branch Naming

The following sections describe the naming shceme that will be used for branches.

### Topic Branch

This branch is used to represnt active work on a ticket.
It should be named with a prefix matching the Jira ticket ID with a short description
(e.g. `JIRA-123-work-to-do`).

### In Development and Future Work

The branch named `dev` will exist to hold completed work for the next planned release
prior to testing.

### Ready for Testing

There will be two QA testing branches.
The branch named `test` will be used for work ready for QA testing through the normal process.
The branch named `emergency-test` will follow `main` and exist to test critical patches.

### Stable and Tested

The branch named `stable` will be hold all commits that have passed testing but
that have not yet been deployed to the live system. This branch should hold only
merge commits from the QA tesing system.

### Live State of Deployments

The `main` branch will represent the live state of deployment. This branch should
hold only merge commits from `stable` or `emergency-test`; each merge commit
will betagged with the release version.

## Creating and Merging Branches

Use the following instructions when creating a new topic branch.

### Planned Work

This is the normal work flow.

#### Creating the Branch

Create new planned work from the latest stable point:

```bash
git fetch
git switch -c "${TICKET_ID}-${DESCRIPTION}" origin/stable
git push -u origin "${TICKET_ID}-${DESCRIPTION}"
```

Perform work and make additional commits to this new branch as needed.
DO NOT merge other branches into a topic branch.

#### Merging the Branch

When work is complete and tested locally, perform the following prior to creating a PR:

```bash
git fetch
git rebase origin/stable "${TICKET_ID}-${DESCRIPTION}"
# resolve conflicts if needed
git push -f origin "${TICKET_ID}-${DESCRIPTION}"
```

Create a PR from `${TICKET_ID}-${DESCRIPTION}` into `dev` on github.

#### Post PR

After the PR is approved and merged, QA will periodically create a PR from `dev` into `test`.
If the automated testing attached as required actions for this PR succeed,
merges will from `dev` to `test` and `test` to `stable`.

### Emergency Bug Fixes

This workflow is for emergency fixes only. Use these steps if and only if `main` is in a
broken state or an emergency security patch needs to be deployed.

#### Creating the Branch

Create the branch directly from the deplyed tag:

```bash
git fetch
git switch -c "${TICKET_ID}-${DESCRIPTION}" "${TAG}"
git push -u origin "${TICKET_ID}-${DESCRIPTION}"
```

Test this locally as thoroughly as possible.

#### Merging for Immediate Testing

Perform the following steps prior to creating a PR.

```bash
git switch emergency-test
git pull
git merge --ff-only origin/main
git push origin emergency-test
```

If this fails to update the emergency test branch, STOP and seek help.

Create a PR from `${TICKET_ID}-${DESCRIPTION}` into `emergency-test` on github.
This should automatically kick off the QA testing.
Once QA testing is successful and the PR is approved, merge and then perform the following:

```bash
git switch main
git pull
git merge --ff-only origin/emergency-test
git tag -a -m "${DESCRIPTION}" "${NEW_TAG}"
git push origin main
git push origin "${NEW_TAG}"
```

Update the deployed environment from the newly created tag.
