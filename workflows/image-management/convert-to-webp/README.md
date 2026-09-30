# Convert to WebP

**Download:** [Convert to WebP.zip](Convert%20to%20WebP.zip) · see [installing a Quick Action](../../../README.md#installing-a-quick-action)

Right-click one or more images → **Quick Actions → Convert to WebP**. A `.webp` copy is saved next to each original. The originals are left untouched.

- **Supported files:** PNG, JPG, TIFF, GIF, HEIC (iPhone photos), and BMP. Files that are already WebP or AVIF are skipped.
- **Quality:** 80. If a `.webp` with the same name already exists, it's replaced.
- **First run:** you'll be asked to download Google's free WebP converter (`cwebp`). Click **Download**. It's a one-time setup that takes a few seconds and needs no password or Homebrew. If you already have `cwebp` through Homebrew, this step is skipped.
- **Results:** a notification tells you how many images were converted, and any files that couldn't be converted are listed by name.

To fully remove it, also delete the downloaded converter at `~/Library/Application Support/MESH/webp-tools`.

The script inside the workflow is also saved as [`script.zsh`](script.zsh) so it's easy to read.
