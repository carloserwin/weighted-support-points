# MNIST example for "Weighted Support Points from Random Measures:
# An Interpretable Alternative for Generative Modeling"
#
# Run from the repository root:
#   Rscript experiments/example1.r
# Optional: WSP_CORES=16 WSP_SEED=123 Rscript experiments/example1.r

if (!requireNamespace("imager", quietly = TRUE)) {
  stop("Package 'imager' is required. Install it with install.packages('imager').")
}

source(file.path("R", "extras.r"))
dir.create("outputs", showWarnings = FALSE, recursive = TRUE)

# A fixed seed makes the released example repeatable. The seed used for the
# figures in the manuscript was not recorded in the original script.
seed <- suppressWarnings(as.integer(Sys.getenv("WSP_SEED", "123")))
if (is.na(seed)) stop("WSP_SEED must be an integer.")
set.seed(seed)

# Forked parallelism (parallel::mclapply) is not supported on Windows.
requested_cores <- suppressWarnings(as.integer(Sys.getenv("WSP_CORES", "4")))
if (is.na(requested_cores) || requested_cores < 1L) {
  stop("WSP_CORES must be a positive integer.")
}
available_cores <- parallel::detectCores()
if (is.na(available_cores)) available_cores <- 1L
my_cores <- if (.Platform$OS.type == "windows") 1L else min(requested_cores, available_cores)
message("Random seed: ", seed, "; CPU workers: ", my_cores)

# Author-prepared MNIST subset with digits 6 and 9, one image per column.
# The RDS contains raw integer pixel intensities in [0, 255].
data_file <- file.path("data", "Y_MNIST_digits.RDS")
if (!file.exists(data_file)) stop("Missing input data: ", data_file)
Y <- readRDS(data_file)
if (!is.matrix(Y) || !identical(dim(Y), c(784L, 11867L)) ||
    !is.numeric(Y) || anyNA(Y) || any(Y < 0 | Y > 255)) {
  stop("Unexpected MNIST data: expected a 784 x 11867 numeric matrix with values in [0, 255].")
}
Y <- Y / 255

max_iter <- 1000L
tol <- 1e-5
cv <- 0.4

# Generate one configuration using the algorithm and the CV-calibrated
# random measure. Pixel values are clipped and rounded after optimization.
run_configuration <- function(n) {
  X0 <- matrix(runif(n * nrow(Y)), nrow = nrow(Y), ncol = n)
  ranm <- gen.rmeasure(Y, cv)
  elapsed <- system.time({
    res <- esp_ccp_weighted(ranm$Yt, X0, ranm$wt,
                            max_iter, tol, my_cores)
  })[["elapsed"]]
  list(pixels = round(pmin(pmax(255 * res$X, 0), 255)),
       elapsed_seconds = elapsed, iterations = res$iter_conv)
}

# Both figures are 5 x 10 grids of grayscale 28 x 28 digits.
# The pixel-to-image orientation matches the original manuscript script.
write_grid <- function(images, filename, type) {
  if (type == "pdf") {
    grDevices::pdf(filename, width = 10, height = 5)
  } else {
    grDevices::tiff(filename, width = 10, height = 5,
                    units = "in", res = 300, compression = "lzw")
  }
  on.exit(grDevices::dev.off())
  graphics::par(mfrow = c(5, 10), mar = rep(0, 4),
                oma = rep(0, 4), mai = rep(0, 4))
  for (i in seq_len(ncol(images))) {
    img <- matrix(images[, i], nrow = 28, ncol = 28, byrow = FALSE)
    plot(imager::as.cimg(img), axes = FALSE, asp = 1)
  }
}

# Figure 1: five independent runs, each with n = 10 support points.
results_10 <- lapply(seq_len(5), function(j) {
  message("Figure 1: run ", j, " of 5 (n = 10)")
  run_configuration(10L)
})
images_10 <- do.call(cbind, lapply(results_10, `[[`, "pixels"))
write_grid(images_10, file.path("outputs", "figure1.pdf"), "pdf")
write_grid(images_10, file.path("outputs", "figure1.tiff"), "tiff")

# Figure 2: a single run with n = 50 support points.
message("Figure 2: single run (n = 50)")
result_50 <- run_configuration(50L)
write_grid(result_50$pixels, file.path("outputs", "figure2.pdf"), "pdf")
write_grid(result_50$pixels, file.path("outputs", "figure2.tiff"), "tiff")

# Execution times depend strongly on the number of cores and hardware.
elapsed <- data.frame(
  figure = c(rep("figure1", 5), "figure2"),
  run = c(seq_len(5), 1L),
  n = c(rep(10L, 5), 50L),
  iterations = c(vapply(results_10, `[[`, integer(1), "iterations"),
                 result_50$iterations),
  elapsed_seconds = c(vapply(results_10, `[[`, numeric(1), "elapsed_seconds"),
                      result_50$elapsed_seconds)
)
utils::write.csv(elapsed, file.path("outputs", "timings.csv"), row.names = FALSE)
message("Done. Figures and timings saved under outputs/.")
