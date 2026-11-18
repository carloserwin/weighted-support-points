# Weighted Support Points from Random Measures

R code and an MNIST example accompanying the manuscript:

**Weighted Support Points from Random Measures: An Interpretable Alternative for Generative Modeling**

Peiqi Zhao, Carlos E. Rodríguez, Ramsés H. Mena, and Stephen G. Walker.

## Repository contents

```text
R/extras.r                   Weighted-support-point algorithm and helpers
experiments/example1.r       MNIST experiment (Figures 1 and 2)
data/Y_MNIST_digits.RDS      MNIST digits 6 and 9 matrix
outputs/                     Generated figures and execution times
```

The code implements the general weighted-support-point method. The more computationally intensive CelebA-HQ example from the paper is **not** included.

## Requirements

- R, including the standard `parallel` package.
- The R package `imager`, used for plotting the resulting digits.

Install the required graphics package in R:

```r
install.packages("imager")
```

The implementation uses `parallel::mclapply`. On Windows, the example uses one worker, since forked multicore execution is not supported. On macOS or Linux, it can use additional workers depending on the resources available.

## Running the MNIST experiment

From the repository root:

```sh
Rscript experiments/example1.r
```

By default, the script uses a random seed of **123** and up to **4 CPU workers**. For a 16-core run on a compatible machine:

```sh
WSP_CORES=16 Rscript experiments/example1.r
```

To use a different seed:

```sh
WSP_SEED=2026 Rscript experiments/example1.r
```

The script generates:

- `outputs/figure1.pdf` and `outputs/figure1.tiff`: five independent realizations, each with 10 support points (5 × 10 grid).
- `outputs/figure2.pdf` and `outputs/figure2.tiff`: one realization with 50 support points (5 × 10 grid).
- `outputs/timings.csv`: the iteration counts and elapsed times for each run.

The example uses uniform initial support-point coordinates on [0,1], a target CV of **0.4**, a maximum of **1,000 iterations**, and a convergence tolerance of **1e-5**.

## Input data

The example needs `data/Y_MNIST_digits.RDS`, an author-prepared matrix of **784 × 11867** containing flattened 28 × 28 MNIST images of digits 6 and 9. Raw pixel values range from 0 to 255; the script rescales them to [0,1].

**Current status:** the RDS data file has not yet been uploaded to this repository. Place it in `data/` before running the example. The matrix has no class labels or original filtering script, so the stated classes cannot be checked from the RDS alone. Check dataset attribution and redistribution terms before posting it.

## Reproducibility notes

The original example did not record the seed used to generate the figures published in the manuscript. Therefore, the provided default seed makes new runs repeatable, but is not claimed to reproduce the exact images in the manuscript.

The released algorithm includes a bookkeeping correction: when the stopping tolerance is met, the function returns the last computed support-point matrix and objective value. The CCP update formula is unchanged.

The authors report approximate wall-clock times of one minute per run with 10 support points and four minutes for 50 support points when using 16 CPU cores. Runtime is hardware-dependent.

**Validation status:** files have been inspected, but the complete R experiment has not yet been executed and checked in this preparation environment.

## Scope

This repository provides the method implementation and the MNIST illustration, but does not reproduce the CelebA-HQ experiment. No software license has yet been selected by the authors.
