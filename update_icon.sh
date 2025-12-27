#!/bin/bash
# Script to update app icon from assets folder

ICON_SOURCE="assets/app_icon.png"

if [ ! -f "$ICON_SOURCE" ]; then
    echo "Error: Icon file not found at $ICON_SOURCE"
    echo "Please place your app icon as 'app_icon.png' in the assets folder"
    exit 1
fi

echo "Updating app icons..."

# Icon sizes for different densities
# mdpi: 48x48
# hdpi: 72x72
# xhdpi: 96x96
# xxhdpi: 144x144
# xxxhdpi: 192x192

# Check if ImageMagick is available
if command -v convert &> /dev/null; then
    echo "Using ImageMagick to resize icons..."
    convert "$ICON_SOURCE" -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    convert "$ICON_SOURCE" -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    convert "$ICON_SOURCE" -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    convert "$ICON_SOURCE" -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    convert "$ICON_SOURCE" -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    echo "Icons updated successfully!"
elif command -v magick &> /dev/null; then
    echo "Using ImageMagick (magick) to resize icons..."
    magick "$ICON_SOURCE" -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    magick "$ICON_SOURCE" -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    magick "$ICON_SOURCE" -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    magick "$ICON_SOURCE" -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    magick "$ICON_SOURCE" -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    echo "Icons updated successfully!"
else
    echo "Warning: ImageMagick not found. Copying source icon to all densities."
    echo "For best results, please install ImageMagick or manually resize the icon:"
    echo "  mdpi: 48x48, hdpi: 72x72, xhdpi: 96x96, xxhdpi: 144x144, xxxhdpi: 192x192"
    cp "$ICON_SOURCE" android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    cp "$ICON_SOURCE" android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    cp "$ICON_SOURCE" android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    cp "$ICON_SOURCE" android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    cp "$ICON_SOURCE" android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    echo "Icons copied (may need manual resizing)"
fi



