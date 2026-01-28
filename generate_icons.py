#!/usr/bin/env python3
"""
Generate app icons for all platforms from the base 1024x1024 icon.
"""

from PIL import Image
import os
from pathlib import Path

# Base icon path
BASE_ICON = "/home/paul/.gemini/antigravity/brain/2bfa791a-46af-42c6-ad60-ca845a625813/proportion_icon_base_1769627222095.png"
PROJECT_ROOT = "/home/paul/Documents/projects/Proportion"

# Load base image
print(f"Loading base icon: {BASE_ICON}")
base_img = Image.open(BASE_ICON)
print(f"Base image size: {base_img.size}")

# Android icon sizes (mipmap)
android_icons = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

print("\n=== Generating Android Icons ===")
for mipmap_dir, size in android_icons.items():
    output_dir = os.path.join(PROJECT_ROOT, "android", "app", "src", "main", "res", mipmap_dir)
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "ic_launcher.png")
    
    resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(output_path, "PNG")
    print(f"✓ Created {mipmap_dir}/ic_launcher.png ({size}x{size})")

# Web icons
print("\n=== Generating Web Icons ===")
web_dir = os.path.join(PROJECT_ROOT, "web", "icons")
os.makedirs(web_dir, exist_ok=True)

# Standard web icons
for size in [192, 512]:
    output_path = os.path.join(web_dir, f"Icon-{size}.png")
    resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(output_path, "PNG")
    print(f"✓ Created Icon-{size}.png ({size}x{size})")

# Maskable icons (with safe zone padding)
# Maskable icons need 20% padding to ensure they're not clipped
for size in [192, 512]:
    # Create a new image with transparent background
    maskable_size = size
    safe_zone = int(size * 0.8)  # Icon should fit in 80% of the canvas
    
    # Create new transparent image
    maskable = Image.new('RGBA', (maskable_size, maskable_size), (0, 0, 0, 0))
    
    # Resize base image to fit in safe zone
    resized_icon = base_img.resize((safe_zone, safe_zone), Image.Resampling.LANCZOS)
    
    # Calculate position to center the icon
    offset = (maskable_size - safe_zone) // 2
    
    # Paste the resized icon centered with padding
    maskable.paste(resized_icon, (offset, offset))
    
    output_path = os.path.join(web_dir, f"Icon-maskable-{size}.png")
    maskable.save(output_path, "PNG")
    print(f"✓ Created Icon-maskable-{size}.png ({size}x{size} with safe zone)")

# Favicon
favicon_path = os.path.join(PROJECT_ROOT, "web", "favicon.png")
favicon = base_img.resize((32, 32), Image.Resampling.LANCZOS)
favicon.save(favicon_path, "PNG")
print(f"✓ Created favicon.png (32x32)")

# Windows ICO (multi-resolution)
print("\n=== Generating Windows Icon ===")
windows_resources_dir = os.path.join(PROJECT_ROOT, "windows", "runner", "resources")
os.makedirs(windows_resources_dir, exist_ok=True)
ico_path = os.path.join(windows_resources_dir, "app_icon.ico")

# Create multiple sizes for ICO
ico_sizes = [16, 32, 48, 256]
ico_images = []
for size in ico_sizes:
    resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
    ico_images.append(resized)

# Save as ICO with multiple sizes
ico_images[0].save(ico_path, format='ICO', sizes=[(s, s) for s in ico_sizes], append_images=ico_images[1:])
print(f"✓ Created app_icon.ico (multi-resolution: {ico_sizes})")

# Linux icon (512x512)
print("\n=== Generating Linux Icon ===")
# Check if linux directory exists and find appropriate location
linux_dir = os.path.join(PROJECT_ROOT, "linux")
if os.path.exists(linux_dir):
    # Try to find the appropriate location for Linux icon
    # Common location is in the runner subdirectory
    linux_icon_dir = os.path.join(linux_dir, "runner")
    if not os.path.exists(linux_icon_dir):
        linux_icon_dir = linux_dir
    
    os.makedirs(linux_icon_dir, exist_ok=True)
    linux_icon_path = os.path.join(linux_icon_dir, "app_icon.png")
    
    linux_icon = base_img.resize((512, 512), Image.Resampling.LANCZOS)
    linux_icon.save(linux_icon_path, "PNG")
    print(f"✓ Created app_icon.png for Linux (512x512)")
else:
    print("⚠ Linux directory not found, skipping Linux icon")

print("\n✅ All icons generated successfully!")
