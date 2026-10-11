"""Data Ingestion & Organization Script for FloraScan Solanaceae Datasets.

Extracts, filters, and standardizes raw field leaf images for Tomato, Chili,
and Eggplant into a clean ImageFolder layout under `ml/data/raw/`.
Filters out macOS metadata (__MACOSX), .DS_Store, and ignores pre-augmented duplicates.
"""

import hashlib
import io
from pathlib import Path
import shutil
import zipfile

from PIL import Image


def find_file(root_dir: Path, filename: str) -> Path | None:
    """Find a file recursively under root_dir."""
    for p in root_dir.rglob(filename):
        if p.is_file():
            return p
    return None


def organize_eggplant(data_dir: Path, target_dir: Path) -> dict[str, int]:
    """Extract Eggplant raw field dataset."""
    egg_target = target_dir / "eggplant"
    egg_target.mkdir(parents=True, exist_ok=True)
    counts: dict[str, int] = {}

    egg_zip = find_file(data_dir, "Eggplant Leaf Image Dataset.zip")
    if not egg_zip:
        print("[!] Eggplant Leaf Image Dataset.zip not found!")
        return counts

    print(f"[*] Extracting Eggplant dataset from {egg_zip.name}...")
    with zipfile.ZipFile(egg_zip, "r") as zf:
        for member in zf.namelist():
            if "__MACOSX" in member or member.endswith("/") or member.startswith("."):
                continue
            parts = [p for p in member.split("/") if p]
            if len(parts) >= 2:
                class_name = parts[0]
                img_name = parts[-1]
                if not any(img_name.lower().endswith(ext) for ext in [".jpg", ".jpeg", ".png"]):
                    continue

                class_dest = egg_target / class_name
                class_dest.mkdir(parents=True, exist_ok=True)
                dest_file = class_dest / img_name
                if not dest_file.exists():
                    with zf.open(member) as src, open(dest_file, "wb") as dst:
                        shutil.copyfileobj(src, dst)
                    counts[class_name] = counts.get(class_name, 0) + 1

    return counts


def organize_tomato(data_dir: Path, target_dir: Path) -> dict[str, int]:
    """Extract raw Tomato field dataset from Pakistan Mendeley bundle."""
    tom_target = target_dir / "tomato"
    tom_target.mkdir(parents=True, exist_ok=True)
    counts: dict[str, int] = {}

    tom_zip = find_file(data_dir, "Tomato_Leaf_Disease_Dataset_Pakistan.zip")
    if not tom_zip:
        print("[!] Tomato_Leaf_Disease_Dataset_Pakistan.zip not found!")
        return counts

    print(f"[*] Extracting Tomato raw field dataset from {tom_zip.name}...")
    prefix = "Tomato Dataset/Dataset (raw)/"
    with zipfile.ZipFile(tom_zip, "r") as zf:
        for member in zf.namelist():
            if not member.startswith(prefix) or member.endswith("/"):
                continue
            rel_path = member[len(prefix):]
            parts = [p for p in rel_path.split("/") if p]
            if len(parts) >= 2:
                class_name = parts[0]
                img_name = parts[-1]
                if not any(img_name.lower().endswith(ext) for ext in [".jpg", ".jpeg", ".png"]):
                    continue

                class_dest = tom_target / class_name
                class_dest.mkdir(parents=True, exist_ok=True)
                dest_file = class_dest / img_name
                if not dest_file.exists():
                    with zf.open(member) as src, open(dest_file, "wb") as dst:
                        shutil.copyfileobj(src, dst)
                    counts[class_name] = counts.get(class_name, 0) + 1

    return counts


def organize_tomato_supplement(data_dir: Path, target_dir: Path) -> dict[str, int]:
    """Extract and merge supplementary processed Tomato dataset (PlantVillage / Mendeley).

    Enforces Single Source of Truth (SSOT) class mapping, SHA-256 deduplication,
    image integrity verification, and ignores unsupported classes (e.g. Bacterial spot)
    to protect the 20-class production taxonomy.
    """
    tom_target = target_dir / "tomato"
    tom_target.mkdir(parents=True, exist_ok=True)
    counts: dict[str, int] = {}

    # Canonical class mapping to SSOT registry folder names
    class_mapping = {
        "Tomato___Early_blight": "Tomato_Early_blight_leaf",
        "Tomato___Late_blight": "Tomato_leaf_late_blight",
        "Tomato___healthy": "Tomato_Healthy_leaf",
        "Tomato___Leaf_Mold": "Tomato_mold_leaf",
        "Tomato___Septoria_leaf_spot": "Tomato_Septoria_leaf_spot",
    }

    # Locate zip file: check for Dataset-*.zip or zip containing Tomato___Early_blight
    supp_zip: Path | None = None
    for p in data_dir.rglob("*.zip"):
        if "Dataset" in p.name or "Tomato" in p.name:
            try:
                with zipfile.ZipFile(p, "r") as zf:
                    if any("Tomato___Early_blight" in m for m in zf.namelist()):
                        supp_zip = p
                        break
            except Exception:
                continue

    if not supp_zip:
        print("[!] Supplementary Tomato zip not found in data directory.")
        return counts

    print(f"[*] Ingesting supplementary Tomato dataset from {supp_zip.name}...")

    # Pre-index existing image hashes to guarantee zero duplicates (SSOT / Defensive)
    existing_hashes: set[str] = set()
    for img_file in tom_target.rglob("*"):
        if img_file.is_file() and img_file.suffix.lower() in [".jpg", ".jpeg", ".png"]:
            try:
                with open(img_file, "rb") as f:
                    existing_hashes.add(hashlib.md5(f.read()).hexdigest())
            except Exception:
                pass

    with zipfile.ZipFile(supp_zip, "r") as zf:
        for member in zf.namelist():
            if member.endswith("/") or "__MACOSX" in member or member.startswith("."):
                continue
            parts = [p for p in member.split("/") if p]
            if len(parts) >= 3:
                split_tag = parts[-3]
                source_class = parts[-2]
                img_name = parts[-1]

                if source_class not in class_mapping:
                    continue
                if not any(img_name.lower().endswith(ext) for ext in [".jpg", ".jpeg", ".png"]):
                    continue

                target_folder_name = class_mapping[source_class]
                class_dest = tom_target / target_folder_name
                class_dest.mkdir(parents=True, exist_ok=True)

                img_bytes = zf.read(member)
                img_hash = hashlib.md5(img_bytes).hexdigest()
                if img_hash in existing_hashes:
                    continue

                # Defensive check: verify image validity
                try:
                    with Image.open(io.BytesIO(img_bytes)) as pil_img:
                        pil_img.verify()
                except Exception:
                    continue

                dest_file = class_dest / f"pv_{split_tag}_{img_name}"
                if not dest_file.exists():
                    with open(dest_file, "wb") as dst:
                        dst.write(img_bytes)
                    existing_hashes.add(img_hash)
                    counts[target_folder_name] = counts.get(target_folder_name, 0) + 1

    return counts


def organize_chili(data_dir: Path, target_dir: Path) -> dict[str, int]:
    """Extract and merge Chili datasets (Jamalpur Original + Bangladesh)."""
    chili_target = target_dir / "chili"
    chili_target.mkdir(parents=True, exist_ok=True)
    counts: dict[str, int] = {}

    # 1. Copy original 6 classes from Jamalpur dataset
    orig_dir = None
    for p in data_dir.rglob("Chili Leaf Disease Original Dataset"):
        if p.is_dir() and (p / "Bacterial Spot").is_dir():
            orig_dir = p
            break

    if orig_dir:
        print(f"[*] Ingesting Jamalpur Original Chili classes from {orig_dir}...")
        for class_folder in orig_dir.iterdir():
            if class_folder.is_dir() and not class_folder.name.startswith("."):
                class_name = class_folder.name
                dest_class = chili_target / class_name
                dest_class.mkdir(parents=True, exist_ok=True)

                for img_path in class_folder.iterdir():
                    if img_path.is_file() and any(
                        img_path.name.lower().endswith(ext) for ext in [".jpg", ".jpeg", ".png"]
                    ):
                        dest_file = dest_class / img_path.name
                        if not dest_file.exists():
                            shutil.copy2(img_path, dest_file)
                            counts[class_name] = counts.get(class_name, 0) + 1

    # 2. Extract Anthracnose and supplemental classes from Bangladesh dataset
    bangladesh_zips = {
        "Anthracnose.zip": "Anthracnose",
        "Cercospora Leaf Spot.zip": "Cercospora Leaf Spot",
        "Leaf Curl Disease.zip": "Curl Virus",
        "Fresh Leaf.zip": "Healthy Leaf",
    }

    for zip_name, target_class in bangladesh_zips.items():
        zpath = find_file(data_dir, zip_name)
        if not zpath:
            continue
        print(f"[*] Extracting {zip_name} into {target_class}...")
        dest_class = chili_target / target_class
        dest_class.mkdir(parents=True, exist_ok=True)

        with zipfile.ZipFile(zpath, "r") as zf:
            for member in zf.namelist():
                if "__MACOSX" in member or member.endswith("/") or member.startswith("."):
                    continue
                parts = [p for p in member.split("/") if p]
                if not parts:
                    continue
                img_name = parts[-1]
                if not any(img_name.lower().endswith(ext) for ext in [".jpg", ".jpeg", ".png"]):
                    continue

                dest_file = dest_class / f"bg_{img_name}"
                if not dest_file.exists():
                    with zf.open(member) as src, open(dest_file, "wb") as dst:
                        shutil.copyfileobj(src, dst)
                    counts[target_class] = counts.get(target_class, 0) + 1

    return counts


def main() -> None:
    ml_dir = Path(__file__).resolve().parent.parent
    data_dir = ml_dir / "data"
    raw_dir = data_dir / "raw"

    print("=" * 60)
    print("FloraScan: Ingesting & Organizing Raw Solanaceae Datasets")
    print("=" * 60)

    eggplant_counts = organize_eggplant(data_dir, raw_dir)
    tomato_counts = organize_tomato(data_dir, raw_dir)
    tomato_supp_counts = organize_tomato_supplement(data_dir, raw_dir)
    chili_counts = organize_chili(data_dir, raw_dir)

    print("\n" + "=" * 60)
    print("INGESTION SUMMARY PER CROP & CLASS")
    print("=" * 60)

    total_images = 0

    print("\n--- EGGPLANT ---")
    for cls, count in sorted(eggplant_counts.items()):
        print(f"  {cls:<30}: {count:>5} images")
        total_images += count

    print("\n--- TOMATO (PAKISTAN FIELD BASE) ---")
    for cls, count in sorted(tomato_counts.items()):
        print(f"  {cls:<30}: {count:>5} images")
        total_images += count

    print("\n--- TOMATO (SUPPLEMENTARY PLANTVILLAGE / MENDELEY) ---")
    for cls, count in sorted(tomato_supp_counts.items()):
        print(f"  {cls:<30}: {count:>5} images")
        total_images += count

    print("\n--- CHILI ---")
    for cls, count in sorted(chili_counts.items()):
        print(f"  {cls:<30}: {count:>5} images")
        total_images += count

    print("\n" + "-" * 60)
    print(f"TOTAL INGESTED RAW FIELD IMAGES: {total_images:,}")
    print(f"TARGET DIRECTORY: {raw_dir}")
    print("=" * 60)


if __name__ == "__main__":
    main()
