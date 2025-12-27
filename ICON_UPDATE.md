# App Icon Update Instructions

## Icon Requirements
- Format: PNG with transparency
- Recommended size: 1024x1024 pixels (square)
- Name: `app_icon.png` (place in `assets/` folder)

## Update Process

1. Place your icon file in the `assets/` folder as `app_icon.png`
2. Run the update script:
   ```bash
   ./update_icon.sh
   ```

Alternatively, if you have icon files with different names or in different locations, you can manually copy them:

```bash
# Copy your icon to all density folders
cp your_icon.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png
cp your_icon.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png
cp your_icon.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
cp your_icon.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
cp your_icon.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

## Icon Sizes
- mdpi: 48x48 pixels
- hdpi: 72x72 pixels
- xhdpi: 96x96 pixels
- xxhdpi: 144x144 pixels
- xxxhdpi: 192x192 pixels

For best results, use ImageMagick to automatically resize:
```bash
sudo apt-get install imagemagick  # On Ubuntu/Debian
brew install imagemagick          # On macOS
```



