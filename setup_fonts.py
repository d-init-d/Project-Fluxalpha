#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Setup script to download fonts from Google Fonts for Flux Alpha.
Downloads all required font families for the 5 predefined font themes.
"""

import os
import sys
import urllib.request
import urllib.error
import json
from pathlib import Path

# Set UTF-8 encoding for Windows console
if sys.platform == 'win32':
    import locale
    if sys.stdout.encoding != 'utf-8':
        sys.stdout.reconfigure(encoding='utf-8')

# Font configuration
FONTS_DIR = Path("flux_alpha/assets/fonts")
FONTS_DIR.mkdir(parents=True, exist_ok=True)

# Google Fonts API base URL
GOOGLE_FONTS_API = "https://fonts.googleapis.com/css2"

# Font families to download with their required weights
FONT_FAMILIES = {
    "Playfair Display": {
        "weights": ["400", "500", "700", "400italic", "700italic"],
        "files": {
            "400": "PlayfairDisplay-Regular.ttf",
            "500": "PlayfairDisplay-Medium.ttf",
            "700": "PlayfairDisplay-Bold.ttf",
            "400italic": "PlayfairDisplay-Italic.ttf",
            "700italic": "PlayfairDisplay-BoldItalic.ttf"
        }
    },
    "Manrope": {
        "weights": ["400", "500", "600", "700"],
        "files": {
            "400": "Manrope-Regular.ttf",
            "500": "Manrope-Medium.ttf",
            "600": "Manrope-SemiBold.ttf",
            "700": "Manrope-Bold.ttf"
        }
    },
    "Lora": {
        "weights": ["400", "500", "700", "400italic", "700italic"],
        "files": {
            "400": "Lora-Regular.ttf",
            "500": "Lora-Medium.ttf",
            "700": "Lora-Bold.ttf",
            "400italic": "Lora-Italic.ttf",
            "700italic": "Lora-BoldItalic.ttf"
        }
    },
    "Inter": {
        "weights": ["400", "500", "600", "700"],
        "files": {
            "400": "Inter-Regular.ttf",
            "500": "Inter-Medium.ttf",
            "600": "Inter-SemiBold.ttf",
            "700": "Inter-Bold.ttf"
        }
    },
    "Cormorant Garamond": {
        "weights": ["400", "500", "700", "400italic", "700italic"],
        "files": {
            "400": "CormorantGaramond-Regular.ttf",
            "500": "CormorantGaramond-Medium.ttf",
            "700": "CormorantGaramond-Bold.ttf",
            "400italic": "CormorantGaramond-Italic.ttf",
            "700italic": "CormorantGaramond-BoldItalic.ttf"
        }
    },
    "Proza Libre": {
        "weights": ["400", "500", "600", "700"],
        "files": {
            "400": "ProzaLibre-Regular.ttf",
            "500": "ProzaLibre-Medium.ttf",
            "600": "ProzaLibre-SemiBold.ttf",
            "700": "ProzaLibre-Bold.ttf"
        }
    },
    "Merriweather": {
        "weights": ["400", "700", "400italic", "700italic"],
        "files": {
            "400": "Merriweather-Regular.ttf",
            "700": "Merriweather-Bold.ttf",
            "400italic": "Merriweather-Italic.ttf",
            "700italic": "Merriweather-BoldItalic.ttf"
        }
    },
    "Mulish": {
        "weights": ["400", "500", "600", "700"],
        "files": {
            "400": "Mulish-Regular.ttf",
            "500": "Mulish-Medium.ttf",
            "600": "Mulish-SemiBold.ttf",
            "700": "Mulish-Bold.ttf"
        }
    },
    "Bitter": {
        "weights": ["400", "500", "700", "400italic", "700italic"],
        "files": {
            "400": "Bitter-Regular.ttf",
            "500": "Bitter-Medium.ttf",
            "700": "Bitter-Bold.ttf",
            "400italic": "Bitter-Italic.ttf",
            "700italic": "Bitter-BoldItalic.ttf"
        }
    },
    "Work Sans": {
        "weights": ["400", "500", "600", "700"],
        "files": {
            "400": "WorkSans-Regular.ttf",
            "500": "WorkSans-Medium.ttf",
            "600": "WorkSans-SemiBold.ttf",
            "700": "WorkSans-Bold.ttf"
        }
    },
    "JetBrains Mono": {
        "weights": ["400", "500", "700"],
        "files": {
            "400": "JetBrainsMono-Regular.ttf",
            "500": "JetBrainsMono-Medium.ttf",
            "700": "JetBrainsMono-Bold.ttf"
        }
    }
}


def get_font_url(family: str, weight: str) -> str:
    """Generate Google Fonts CSS URL for a specific font family and weight."""
    # Convert weight to ital notation if italic
    if "italic" in weight:
        base_weight = weight.replace("italic", "")
        ital_weight = f"ital,wght@1,{base_weight}"
    else:
        ital_weight = f"wght@{weight}"
    
    family_encoded = family.replace(" ", "+")
    return f"{GOOGLE_FONTS_API}?family={family_encoded}:{ital_weight}&display=swap"


def extract_ttf_url_from_css(css_content: str) -> str:
    """Extract the .ttf URL from Google Fonts CSS."""
    # Look for url() containing .ttf
    import re
    match = re.search(r'url\((https://[^)]+\.ttf)\)', css_content)
    if match:
        return match.group(1)
    return None


def download_font(family: str, weight: str, filename: str) -> bool:
    """Download a font file from Google Fonts."""
    filepath = FONTS_DIR / filename
    
    # Skip if file already exists
    if filepath.exists():
        print(f"Skipping {filename} (already exists)")
        return True
    
    try:
        print(f"Downloading {filename}...", end=" ", flush=True)
        
        # Get CSS URL
        css_url = get_font_url(family, weight)
        
        # Fetch CSS with proper User-Agent to get .ttf URL
        req = urllib.request.Request(
            css_url,
            headers={'User-Agent': 'Mozilla/5.0'}
        )
        
        with urllib.request.urlopen(req) as response:
            css_content = response.read().decode('utf-8')
        
        # Extract .ttf URL from CSS
        ttf_url = extract_ttf_url_from_css(css_content)
        
        if not ttf_url:
            print("[FAIL] Could not find .ttf URL in CSS")
            return False
        
        # Download the .ttf file
        urllib.request.urlretrieve(ttf_url, filepath)
        print("[OK]")
        return True
        
    except urllib.error.URLError as e:
        print(f"[FAIL] Error: {e}")
        return False
    except Exception as e:
        print(f"[FAIL] Unexpected error: {e}")
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
            print(f"[FAIL] Cannot create fonts directory: {e}")
            return
    
    # Download fonts
    total_fonts = sum(len(info["weights"]) for info in FONT_FAMILIES.values())
    success_count = 0
    failed_fonts = []
    
    for family, info in FONT_FAMILIES.items():
        print(f"\n--- {family} ---")
        for weight in info["weights"]:
            filename = info["files"][weight]
            if download_font(family, weight, filename):
                success_count += 1
            else:
                failed_fonts.append(filename)
    
    # Summary
    print("\n" + "=" * 60)
    print("Download Summary")
    print("=" * 60)
    print(f"Successfully downloaded: {success_count}/{total_fonts} fonts")
    
    if failed_fonts:
        print(f"\nFailed to download:")
        for font in failed_fonts:
            print(f"  - {font}")
        print("\nPlease check your internet connection and try again.")
        return
    
    print("\n[SUCCESS] All fonts downloaded successfully!")
    print("\nNext steps:")
    print("1. Verify that pubspec.yaml includes all font declarations")
    print("2. Run: flutter pub get")
    print("3. Run: flutter clean")
    print("4. Rebuild your app")


if __name__ == "__main__":
    main()
