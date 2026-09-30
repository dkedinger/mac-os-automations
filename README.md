# Mac Quick Actions

Small right-click tools for Finder on macOS. Each one installs in a couple of clicks and needs no technical setup.

## Image Management

| Quick Action | What it does | Download |
|---|---|---|
| [**Convert to WebP**](workflows/image-management/convert-to-webp/) | Turns selected images into web-ready `.webp` copies. | [Convert to WebP.zip](workflows/image-management/convert-to-webp/Convert%20to%20WebP.zip) |

Click an action's name for details on what it does and how to remove it.

---

## Installing a Quick Action

1. Click the download link in the table above, then click the **Download raw file** button (the down-arrow icon) on the page that opens.
2. Unzip the file and double-click the `.workflow` file, then click **Install**.
3. In Finder, right-click a file and choose **Quick Actions** → the action's name.

**If macOS says the file can't be opened:** right-click it and choose **Open**, or go to **System Settings → Privacy & Security** and click **Open Anyway**.

**If the action doesn't appear in the menu:** right-click any file, choose **Quick Actions → Customize…**, and tick the action.

**To uninstall:** delete the action from `~/Library/Services/`. (In Finder, press **⌘⇧G** and paste that path to get there.)

---

## For maintainers

### Layout

```
workflows/
  <category>/                 e.g. image-management
    <action>/                 e.g. convert-to-webp
      <Name>.workflow/        the Automator bundle (source of truth)
      <Name>.zip              generated – what people download
      script.zsh              generated – the embedded shell script, for reading/diffs
      README.md               what the action does, requirements, how to remove it
scripts/
  build.sh                    regenerates every .zip and script.zsh
```

Folder names are lowercase-with-hyphens so links stay clean; the `.workflow` keeps its human-readable name because that is what appears in the Quick Actions menu.

### Adding a Quick Action

1. Build and save it in Automator (type: **Quick Action**), then copy the `.workflow` from `~/Library/Services/` into `workflows/<category>/<action>/`.
2. Add a `README.md` next to it (copy an existing one as a template).
3. Run `./scripts/build.sh` to generate the `.zip` and `script.zsh`.
4. Add a row to the table above, under its category heading (add a new heading for a new category).
5. Commit the `.workflow`, `.zip`, `script.zsh`, and READMEs together.

When you edit an existing action, re-run `./scripts/build.sh` so the download stays in sync with the `.workflow`.
