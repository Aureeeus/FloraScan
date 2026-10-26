import os
import json
from PIL import Image

raw_dir = os.path.join('ml', 'data', 'raw')
out_dir = os.path.join('mobile', 'assets', 'pathology_reference')
os.makedirs(out_dir, exist_ok=True)

with open('mobile/assets/models/pathology_registry.json') as f:
    data = json.load(f)
    classes = data['classes']

print(f"Processing {len(classes)} classes...")

for item in classes:
    class_id = item['id']
    folder_rel = item['folder']
    folder_path = os.path.join(raw_dir, folder_rel)
    
    if not os.path.isdir(folder_path):
        print(f"ERROR: Missing folder {folder_path}")
        continue
    
    # Get all valid image files
    files = [f for f in sorted(os.listdir(folder_path)) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
    if not files:
        print(f"ERROR: No images in {folder_path}")
        continue
    
    # Pick the first valid image (or one around index 0 or 1 that opens cleanly)
    chosen_path = None
    for fname in files:
        fpath = os.path.join(folder_path, fname)
        try:
            with Image.open(fpath) as img:
                img.verify()
            chosen_path = fpath
            break
        except Exception as e:
            print(f"Skipping corrupt {fpath}: {e}")
            continue
            
    if not chosen_path:
        print(f"ERROR: No valid image found for {class_id}")
        continue
        
    out_file = os.path.join(out_dir, f"{class_id}.jpg")
    with Image.open(chosen_path) as img:
        img = img.convert('RGB')
        # Center crop to square if aspect ratio is not 1:1, then resize to 512x512
        w, h = img.size
        min_dim = min(w, h)
        left = (w - min_dim) // 2
        top = (h - min_dim) // 2
        right = left + min_dim
        bottom = top + min_dim
        img = img.crop((left, top, right, bottom))
        img = img.resize((512, 512), Image.Resampling.LANCZOS)
        img.save(out_file, 'JPEG', quality=85, optimize=True)
        
    size_kb = os.path.getsize(out_file) / 1024
    print(f"Created {class_id}.jpg ({size_kb:.1f} KB) from {os.path.basename(chosen_path)}")

print("Done extracting reference photos!")
