input_dir="s3://maap-ops-workspace/iangrant94/inputs/gabon"
area="mondah"
hse="1_68"

python run_on_maap.py -u iangrant94 -t gabon_${hse}_${area} -b ${input_dir}/boundaries/${area}_bounding_box.gpkg -c ${input_dir}/config.yaml --hse ${input_dir}/hse/${hse}/hse.tif --k_allom ${input_dir}/k_allom/1/k_allom.tif -a nmbim_biomass_index -v main -j 3000 -i 120
