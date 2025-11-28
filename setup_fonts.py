#!/usr/bin/env python3
"""
Setup script to download fonts from Google Fonts for Flux Alpha.
Downloads Playfair Display, Manrope, and JetBrains Mono font files.
"""

import os
import urllib.request
import urllib.error
from pathlib import Path

# Font configuration
FONTS_DIR = Path("flux_alpha/assets/fonts")
FONTS_DIR.mkdir(parents=True, exist_ok=True)

# Google Fonts download URLs
# Using the official Google Fonts API CDN
FONTS_TO_DOWNLOAD = [
    # Playfair Display - Serif
    {
        "url": "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/PlayfairDisplay-Regular.ttf",
        "filename": "PlayfairDisplay-Regular.ttf"
    },
    {
        "url": "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/PlayfairDisplay-Bold.ttf",
        "filename": "PlayfairDisplay-Bold.ttf"
    },
    # Manrope - Sans
    {
        "url": "https://github.com/google/fonts/raw/main/ofl/manrope/Manrope-Regular.ttf",
        "filename": "Manrope-Regular.ttf"
    },
    {
        "url": "https://github.com/google/fonts/raw/main/ofl/manrope/Manrope-Medium.ttf",
        "filename": "Manrope-Medium.ttf"
    },
    {
        "url": "https://github.com/google/fonts/raw/main/ofl/manrope/Manrope-Bold.ttf",
        "filename": "Manrope-Bold.ttf"
    },
    # JetBrains Mono - Mono
    {
        "url": "https://github.com/google/fonts/raw/main/ofl/jetbrainsmono/JetBrainsMono-Regular.ttf",
        "filename": "JetBrainsMono-Regular.ttf"
    },
    {
        "url": "https://github.com/google/fonts/raw/main/ofl/jetbrainsmono/JetBrainsMono-Bold.ttf",
        "filename": "JetBrainsMono-Bold.ttf"
    },
]

def download_font(url: str, filepath: Path) -> bool:
    """Download a font file from the given URL."""
    try:
        print(f"Downloading {filepath.name}...", end=" ", flush=True)
        urllib.request.urlretrieve(url, filepath)
        print("✓")
        return True
    except urllib.error.URLError as e:
        print(f"✗ Error: {e}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return False

def main():
    print("=" * 60)
    print("Flux Alpha Font Setup Script")
    print("=" * 60)
    print(f"\nTarget directory: {FONTS_DIR.absolute()}\n")
    
    # Check if directory exists or can be created
    if not FONTS_DIR.exists():
        try:
            FONTS_DIR.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            print(f"✗ Cannot create fonts directory: {e}")
            return
    
    # Download fonts
    success_count = 0
    failed_fonts = []
    
    for font_info in FONTS_TO_DOWNLOAD:
        filepath = FONTS_DIR / font_info["filename"]
        
        # Skip if file already exists
        if filepath.exists():
            print(f"Skipping {font_info['filename']} (already exists)")
            success_count += 1
            continue
        
        if download_font(font_info["url"], filepath):
            success_count += 1
        else:
            failed_fonts.append(font_info["filename"])
    
    # Summary
    print("\n" + "=" * 60)
    print("Download Summary")
    print("=" * 60)
    print(f"Successfully downloaded: {success_count}/{len(FONTS_TO_DOWNLOAD)} fonts")
    
    if failed_fonts:
        print(f"\nFailed to download:")
        for font in failed_fonts:
            print(f"  - {font}")
        print("\nPlease check your internet connection and try again.")
        return
    
    print("\n✓ All fonts downloaded successfully!")
    print("\nNext steps:")
    print("1. Verify that pubspec.yaml includes all font declarations")
    print("2. Run: flutter pub get")
    print("3. Run: flutter clean")
    print("4. Rebuild your app")

if __name__ == "__main__":
    main()


