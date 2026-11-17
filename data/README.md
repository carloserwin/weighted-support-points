# MNIST image subset

The manuscript uses an author-prepared subset of MNIST consisting of digit images 6 and 9, reshaped to a 784 x 11867 matrix with one flattened 28 x 28 image per column.

The experiment expects `data/Y_MNIST_digits.RDS`. The source RDS file is not included here yet. It has raw pixel intensities between 0 and 255, and the R script divides its values by 255 before optimization.

The RDS data supplied by the authors contains no class labels or original data-preparation script, so digit membership cannot be verified from the matrix alone. Please check appropriate MNIST attribution and any applicable redistribution conditions before posting the dataset.
