# CLAUDE.md

MultiNest — Bayesian inference library with nested sampling.

## Build

```bash
cd MultiNest_v3.12_CMake/multinest
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

- CMake ≥ 3.10, gfortran, LAPACK/OpenBLAS, OpenMPI (optional)
- Object libraries (`multinest_obj`, `multinest_mpi_obj`) compile source once, shared by static + shared targets — avoids Fortran `.mod` race conditions
- `POSITION_INDEPENDENT_CODE ON` on object libs ensures shared library links correctly
- macOS: math library is part of libSystem (no separate `-lm`)
- CI: GitHub Actions matrix builds `linux-x86_64` + `macos-arm64`, releases on version tags

## Key files

- `src/CMakeLists.txt` — library build logic
- `Formula/multinest.rb` — Homebrew formula
- `.github/workflows/build-and-release.yml` — CI/CD
