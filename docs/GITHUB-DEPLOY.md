# What GitHub Actions verifies

`.github/workflows/ci.yml` runs on pushes and pull requests to main/master. It
checks types/lint/format, builds the image, starts two Compose replicas and runs
health/API smoke assertions. Failure logs are collected before cleanup. The load
threshold fixtures exercise pass/fail decisions without a running deployment.

This workflow does not publish an image or deploy a public service. Deployment
requires a separate reviewed destination, credentials, TLS, backups where needed,
and a rollback strategy. Do not add deployment secrets merely to run these checks.
The Compose smoke job builds its own image because hosted jobs have separate Docker
daemons; the preceding build job is a build verification, not an image transfer.
