input_dir="s3://maap-ops-workspace/iangrant94/inputs/gabon"

python run_on_maap.py -u iangrant94 -t dev_test -b ${input_dir}/boundaries/mondah_bounding_box.gpkg -c ${input_dir}/dev_config.yaml --default-hse 1.5 --default-k-allom 1 -a nmbim_biomass_index -v dev -j 10 -i 5
