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
def main(value: float, output_path: Path, dtype: str):
    """Create a global-coverage raster with a single pixel containing VALUE at OUTPUT_PATH."""
    create_uniform_raster(output_path, value, dtype)
    click.echo(f"Created uniform raster with value {value} at: {output_path}")

if __name__ == "__main__":
    main()
