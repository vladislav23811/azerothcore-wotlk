#!/usr/bin/env python3
"""
MPQ Patch Generator for Custom Items
Generates patch-Z.MPQ from DBC files
"""

import sys
import os
import struct
from pathlib import Path

try:
    import pympq
    HAS_PYMPQ = True
except ImportError:
    HAS_PYMPQ = False
    print("Warning: pympq not available. Install with: pip install pympq")

def create_mpq_simple(dbc_dir, output_mpq):
    """Simple MPQ creation (if pympq not available, create basic structure)"""
    if HAS_PYMPQ:
        return create_mpq_pympq(dbc_dir, output_mpq)
    else:
        print("Error: pympq required for MPQ generation")
        print("Install with: pip install pympq")
        return False

def create_mpq_pympq(dbc_dir, output_mpq):
    """Create MPQ using pympq library"""
    try:
        # Create MPQ archive
        mpq = pympq.MPQArchive(output_mpq, create=True)
        
        # Add all DBC files
        dbc_path = Path(dbc_dir)
        if not dbc_path.exists():
            print(f"Error: DBC directory not found: {dbc_dir}")
            return False
        
        added_files = 0
        for dbc_file in dbc_path.glob("*.dbc"):
            local_path = str(dbc_file)
            mpq_path = f"DBFilesClient/{dbc_file.name}"
            
            try:
                mpq.add_file(local_path, mpq_path)
                print(f"Added: {dbc_file.name} -> {mpq_path}")
                added_files += 1
            except Exception as e:
                print(f"Warning: Failed to add {dbc_file.name}: {e}")
        
        mpq.close()
        
        if added_files > 0:
            print(f"Successfully created MPQ patch: {output_mpq}")
            print(f"Added {added_files} DBC file(s)")
            return True
        else:
            print("Warning: No DBC files found to add")
            return False
            
    except Exception as e:
        print(f"Error creating MPQ: {e}")
        return False

def main():
    if len(sys.argv) < 3:
        print("Usage: generate_patch.py <dbc_directory> <output_mpq>")
        print("Example: generate_patch.py dbc/custom patches/patch-Z.MPQ")
        sys.exit(1)
    
    dbc_dir = sys.argv[1]
    output_mpq = sys.argv[2]
    
    # Create output directory if needed
    output_path = Path(output_mpq)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if create_mpq_simple(dbc_dir, output_mpq):
        print(f"\n✓ Patch generated successfully!")
        print(f"  Place {output_mpq} in your WoW client's Data/ folder")
        sys.exit(0)
    else:
        print("\n✗ Failed to generate patch")
        sys.exit(1)

if __name__ == "__main__":
    main()

