import numpy as np
import rasterio
from pathlib import Path
import click

def create_uniform_raster(output_path: Path, value: float, dtype: str = "float32"):
    """Create a global-coverage raster with a single pixel containing the given value."""
    with rasterio.open(
        output_path,
        "w",
        driver="GTiff",
        height=1,
        width=1,
        count=1,
        dtype=dtype,
        crs="EPSG:4326",
        transform=rasterio.Affine(360.0, 0.0, -180.0, 0.0, -180.0, 90.0),
        nodata=np.nan
    ) as dst:
        dst.write(np.array([[value]]), 1)

@click.command()
@click.argument("value", type=float)
@click.argument("output_path", type=click.Path(path_type=Path))
@click.option("--dtype", default="float32", help="Data type for the raster (default: float32)")
def create_uniform_raster_cli(value: float, output_path: Path, dtype: str):
    """Create a global-coverage raster with a single pixel containing VALUE at OUTPUT_PATH."""
    create_uniform_raster(output_path, value, dtype)
    click.echo(f"Created uniform raster with value {value} at: {output_path}")

if __name__ == "__main__":
    # Create in tests/input directory
    output_dir = Path(__file__).parent/"input"
    output_dir.mkdir(exist_ok=True)
    
    # Create all test rasters
    nan_raster_path = output_dir/"nan_raster.tif"
    create_nan_raster(nan_raster_path)
    print(f"Created NaN raster at: {nan_raster_path}")
    
    hse_raster_path = output_dir/"hse.tif"
    create_hse_raster(hse_raster_path)
    print(f"Created HSE raster at: {hse_raster_path}")
    
    k_allom_raster_path = output_dir/"k_allom.tif"
    create_k_allom_raster(k_allom_raster_path)
    print(f"Created K_allom raster at: {k_allom_raster_path}")
    
    # Add CLI command
    create_uniform_raster_cli()
