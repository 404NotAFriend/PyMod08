#!/usr/bin/env python3


import importlib.util
import sys
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import numpy as np
    import pandas as pd

REQUIRED_PACKAGES: list[tuple[str, str]] = [
    ("pandas", "Data manipulation ready"),
    ("numpy", "Numerical computation ready"),
    ("matplotlib", "Visualization ready"),
]


def check_dependency(package: str, description: str) -> bool:
    spec = importlib.util.find_spec(package)
    if spec is None:
        print(f"[MISSING] {package} - {description}")
        print(f"Install with: pip install {package}")
        return False
    version = __import__(package).__version__
    print(f"[OK] {package} ({version}) - {description}")
    return True


def check_all_dependencies() -> bool:
    print("Checking dependencies:")
    results = [check_dependency(pkg, desc) for pkg, desc in REQUIRED_PACKAGES]
    return all(results)


def print_missing_dependencies_help() -> None:
    print()
    print("Some required dependencies are missing.")
    print("Install them with pip:")
    print("  pip install -r requirements.txt")
    print("Or with Poetry:")
    print("  poetry install")


def generate_matrix_data(n_points: int = 1000) -> "np.ndarray":
    import numpy as np

    rng = np.random.default_rng(seed=42)
    trend = np.linspace(0, 10, n_points)
    noise = rng.normal(loc=0.0, scale=1.5, size=n_points)
    return trend + noise


def analyze_matrix_data(values: "np.ndarray") -> "pd.DataFrame":
    import pandas as pd

    frame = pd.DataFrame({"signal": values})
    frame["rolling_mean"] = frame["signal"].rolling(window=20).mean()
    return frame


def plot_matrix_data(frame: "pd.DataFrame", output_path: str) -> None:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots()
    ax.plot(frame["signal"], label="signal", alpha=0.5)
    ax.plot(frame["rolling_mean"], label="rolling mean", linewidth=2)
    ax.set_title("Matrix Data Analysis")
    ax.set_xlabel("data point")
    ax.set_ylabel("value")
    ax.legend()
    fig.savefig(output_path)
    plt.close(fig)


def compare_pip_and_poetry() -> None:
    print()
    print("Dependency management comparison:")
    for pkg, _ in REQUIRED_PACKAGES:
        version = __import__(pkg).__version__
        print(f"  {pkg}: {version}")
    print()
    print("pip (requirements.txt): flat pinned list, no lockfile,")
    print("  you resolve version conflicts manually.")
    print("Poetry (pyproject.toml): structured dependency table,")
    print("  poetry.lock pins the full resolved tree for")
    print("  reproducible installs.")


def main() -> None:
    print("LOADING STATUS: Loading programs...")
    print()
    if not check_all_dependencies():
        print_missing_dependencies_help()
        sys.exit(1)

    print()
    print("Analyzing Matrix data...")
    values = generate_matrix_data()
    print(f"Processing {len(values)} data points...")
    frame = analyze_matrix_data(values)

    print("Generating visualization...")
    output_path = "matrix_analysis.png"
    plot_matrix_data(frame, output_path)

    compare_pip_and_poetry()

    print()
    print("Analysis complete!")
    print(f"Results saved to: {output_path}")


if __name__ == "__main__":
    main()
