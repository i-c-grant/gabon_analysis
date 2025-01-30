input_dir="s3://maap-ops-workspace/iangrant94/inputs/gabon"

python run_on_maap.py -u iangrant94 -t 1_29_full_gabon_1_35 -b ${input_dir}/boundaries/gabon.gpkg -c ${input_dir}/config.yaml --hse ${input_dir}/hse/1_35/hse.tif --k_allom ${input_dir}/k_allom/1/k_allom.tif -a nmbim_biomass_index -v main -j 3000 -i 120
