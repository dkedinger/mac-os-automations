# Mac Quick Actions

Small right-click tools for Finder on macOS. Each one installs in a couple of clicks and needs no technical setup.

| Quick Action | What it does | Download |
|---|---|---|
| **Convert to WebP** | Turns selected images into web-ready `.webp` copies. | [Convert to WebP.zip](convert-to-webp/Convert%20to%20WebP.zip) |

---

## Installing a Quick Action

1. Click the download link in the table above, then click the **Download raw file** button (the down-arrow icon) on the page that opens.
2. Unzip the file and double-click the `.workflow` file, then click **Install**.
3. In Finder, right-click a file and choose **Quick Actions** → the action's name.

**If macOS says the file can't be opened:** right-click it and choose **Open**, or go to **System Settings → Privacy & Security** and click **Open Anyway**.

**If the action doesn't appear in the menu:** right-click any file, choose **Quick Actions → Customize…**, and tick the action.

**To uninstall:** delete the action from `~/Library/Services/`. (In Finder, press **⌘⇧G** and paste that path to get there.)

---

## Convert to WebP

Right-click one or more images → **Quick Actions → Convert to WebP**. A `.webp` copy is saved next to each original. The originals are left untouched.

- **Supported files:** PNG, JPG, TIFF, GIF, HEIC (iPhone photos), and BMP. Files that are already WebP or AVIF are skipped.
- **Quality:** 80. If a `.webp` with the same name already exists, it's replaced.
- **First run:** you'll be asked to download Google's free WebP converter (`cwebp`). Click **Download**. It's a one-time setup that takes a few seconds and needs no password or Homebrew. If you already have `cwebp` through Homebrew, this step is skipped.
- **Results:** a notification tells you how many images were converted, and any files that couldn't be converted are listed by name.

To fully remove it, also delete the downloaded converter at `~/Library/Application Support/MESH/webp-tools`.

The script inside the workflow is also saved as [`convert-to-webp/script.zsh`](convert-to-webp/script.zsh) so it's easy to read.
