---
title: Publishing to PyPI (maintainers)
description: Trusted publishing from GitHub Actions for coconet-python on TestPyPI and PyPI.
---

Releases use **trusted publishing** (OpenID Connect): GitHub Actions proves the workflow’s identity to **TestPyPI** and **PyPI** without long-lived API tokens. Configure the workflow file **`.github/workflows/publish-pypi.yml`** as the trusted workflow on both indexes (exact filename PyPI expects is `publish-pypi.yml`).

## GitHub

1. **Settings** → **Environments** → **New environment** → name it **`pypi`** (must match `jobs.publish.environment` in the workflow).
2. Optional: add protection rules (required reviewers, wait timer) before the job can request the OIDC token.

## TestPyPI

1. Create [test.pypi.org](https://test.pypi.org) account and project **`coconet-python`** if needed.
2. **Project** → **Settings** → **Publishing** → **Add a new pending publisher** (or trusted publisher).
3. Choose **GitHub** as the publisher; set **repository** and owner to match this repo.
4. **Workflow name:** `publish-pypi.yml` (filename under `.github/workflows/`).
5. **Environment:** `pypi` (same as GitHub).

## PyPI

1. **Project** → **Settings** → **Publishing** on [pypi.org](https://pypi.org).
2. Add the **same** GitHub publisher: same repo, workflow `publish-pypi.yml`, environment **`pypi`**.

PyPI and TestPyPI each store their own trusted-publisher record; both must be configured for the two-step CI (TestPyPI → smoke install → PyPI).

## When publishing runs

- **GitHub Release** published → workflow runs on that release’s commit.
- **workflow_dispatch** → manual run (use with care; still uploads whatever version is in `pyproject.toml` on the selected branch).

## Troubleshooting

- **`id-token: write`** must be granted on the **job** (the workflow sets this).
- If uploads fail with credential or OIDC errors, run locally with `uv publish --trusted-publishing always` for clearer messages ([uv note](https://docs.astral.sh/uv/guides/package/#publishing-your-package)).
- **Version reuse:** a given version can only be uploaded once per index; bump `version` in `pyproject.toml` before a new release.

See also: [uv + GitHub Actions](https://docs.astral.sh/uv/guides/integration/github/#publishing-to-pypi), [PyPI trusted publishers](https://docs.pypi.org/trusted-publishers/).
