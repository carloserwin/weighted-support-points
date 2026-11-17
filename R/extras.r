compute_cache_weighted <- function(X, Y, r_y, v) {
  r_x <- colSums(X^2)
  dist2_xy <- outer(r_x, r_y, "+") - 2 * (t(X) %*% Y)
  #dist_xy <- sqrt(pmax(dist2_xy, 0))
  dist_xy <- sqrt(pmax(dist2_xy, 1e-10))
  dist2_xx <- outer(r_x, r_x, "+") - 2 * (t(X) %*% X)
  #dist_xx <- sqrt(pmax(dist2_xx, 0))
  dist_xx <- sqrt(pmax(dist2_xx, 1e-10))
  # Weighted attraction term (weights on Y)
  S_xy <- sum(colSums(dist_xy) * v)  # sum_m v_m * sum_i ||x_i - y_m||
  # Repulsion term (uniform in x, same as original)
  S_xx <- sum(dist_xx[lower.tri(dist_xx)])  # same as before
  list(dist_xy = dist_xy, dist_xx = dist_xx, S_xy = S_xy, S_xx = S_xx)
}
compute_cache_weighted2 <- function(X, Y, r_y, v, c_eps = 1) {
  # X: d x n, Y: d x N, r_y = colSums(Y^2), v: length N
  r_x <- colSums(X^2)
  # escala y epsilon relativo (no fijo)
  s   <- median(sqrt(pmax(r_x, 0)))
  eps <- c_eps * sqrt(.Machine$double.eps) * if (is.finite(s) && s > 0) s else 1
  # d^2(X,Y) = r_x + r_y - 2 X^T Y
  G_xy    <- crossprod(X, Y)
  dist2_xy <- outer(r_x, r_y, "+") - 2 * G_xy
  dist_xy  <- sqrt(pmax(dist2_xy, 0) + eps^2)  # sqrt suavizado
  # d^2(X,X)
  G_xx    <- crossprod(X)
  dist2_xx <- outer(r_x, r_x, "+") - 2 * G_xx
  diag(dist2_xx) <- 0
  dist_xx  <- sqrt(pmax(dist2_xx, 0) + eps^2)
  # Sums
  S_xy <- sum(colSums(dist_xy) * v)          # ∑_m v_m ∑_i ||x_i - y_m||
  S_xx <- sum(dist_xx[lower.tri(dist_xx)])   # ∑_{i>j} ||x_i - x_j||
  list(dist_xy = dist_xy, dist_xx = dist_xx, S_xy = S_xy, S_xx = S_xx, eps = eps)
}

Mi_weighted <- function(i, X, Y, cache, N, n, v) {
  # Término de atracción (con pesos en las Y's)
  weights_y <- v / cache$dist_xy[i, ]  # v_m / ||x_i - y_m||
  q_i <- sum(weights_y)
  attraction <- Y %*% weights_y
  
  # Término de repulsión (uniforme en X, sin factor N)
  delta_x <- matrix(X[, i], nrow(X), n) - X
  weights_x <- 1/cache$dist_xx[i, ]
  weights_x[i] <- 0  # evitar singularidad
  repulsion <- (1/n)*rowSums(sweep(delta_x, 2, weights_x, "*"))
  
  # Actualización final
  (attraction + repulsion) / q_i
}
esp_ccp_weighted <- function(Y, X0, v, max_iter, tol, my_cores) {
  d <- nrow(Y)
  N <- ncol(Y)
  n <- ncol(X0)
  X <- X0
  r_y <- colSums(Y^2)  # static
  cache <- compute_cache_weighted2(X, Y, r_y, v, c_eps = 1) 
  MC_old <- (2/n)*cache$S_xy - (2/n^2)*cache$S_xx
  for (l in 1:max_iter) {
    X_new <- do.call(cbind, parallel::mclapply(1:n, function(i) 
      Mi_weighted(i, X, Y, cache, N, n, v), mc.cores = my_cores))
    
    cache <- compute_cache_weighted2(X_new, Y, r_y, v, c_eps = 1)
    MC_new <- (2/n)*cache$S_xy - (2/n^2)*cache$S_xx
    delta <- abs(MC_new - MC_old)
    cat(sprintf("Iter %d - MC: %.6f - ΔMC: %.2e\n", l, MC_new, delta))
    X <- X_new
    MC_old <- MC_new
    if (delta < tol) {
      break
    }
  }
  list(X = X, iter_conv = l, MC = MC_old)
}
stick_breaking <- function(N, alpha) {
  v <- rbeta(N - 1, 1, alpha)
  w <- numeric(N)
  s <- 1
  for (k in 1:(N - 1)) {
    w[k] <- v[k]*s
    s <- s*(1 - v[k])
  }
  w[N] <- s  
  w/sum(w)
}
gen.rmeasure <- function(Y, cv) {
  N <- ncol(Y)
  theta <- runif(1, 0.7, 0.9)
  N0 <- max(ceiling(0.6 * N), rbinom(1, N, theta))
  id <- sample.int(N, N0, replace = FALSE)
  Yt <- Y[, id, drop = FALSE]
  kappa <- (N0 - 1)/(cv^2) - 1
  a <- kappa/N0  
  wt <- rgamma(N0, shape = a, rate = 1)
  wt <- wt / sum(wt)
  list(Yt = Yt, wt = wt)
}
