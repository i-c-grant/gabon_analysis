#!/bin/bash

# Base S3 path
BASE_PATH="s3://maap-ops-workspace/iangrant94/dps_output/nmbim_biomass_index/main"

# Sites to process
SITES=("mondah_v2" "rabi" "mabounie" "lope") 

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

hse=1_15

# Process each site
for site in "${SITES[@]}"; do
    echo "Processing ${site}..."
    echo "Downloading files from ${site}..."
    # Download all .bz2 files from the site's directory
    aws s3 cp "${BASE_PATH}/gabon_${hse}_${site}/" "$TEMP_DIR/${site}/" --recursive --exclude "*" --include "*.bz2"
    
    # Decompress all .bz2 files
    echo "Decompressing files from ${site}..."
    find "$TEMP_DIR/${site}" -name "*.bz2" -exec bzip2 -d {} \;
    echo "Finished processing ${site}"
done

# Merge all .gpkg files into a single output
ogrmerge.py -single -o gabon_output/combined_gabon_output_${hse}.gpkg $(find "$TEMP_DIR" -name "*.gpkg")

echo "Processing complete."
