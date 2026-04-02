# CoCoNet user documentation (Jekyll)

Build and preview locally:

```bash
cd documentation
bundle install
bundle exec jekyll serve --livereload
```

Open http://127.0.0.1:4000 — for a GitHub **project site**, mimic Pages with:

```bash
bundle exec jekyll serve --baseurl "/YOUR_REPO_NAME"
```

## Publish on GitHub Pages

1. In the GitHub repository, go to **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to **GitHub Actions**.
3. Push to the default branch; the workflow **Deploy documentation to GitHub Pages** uploads the `documentation/_site` artifact.

If this is your first Pages deployment, wait for the workflow to finish; the site URL is shown on the workflow summary and on the Pages settings page (`https://<owner>.github.io/<repo>/` for project sites).

## Customisation

- Update `repo_web_url` in `_config.yml` if you fork the project (footer link).
- Edit Markdown under this directory; navigation is defined in `_layouts/default.html`.
