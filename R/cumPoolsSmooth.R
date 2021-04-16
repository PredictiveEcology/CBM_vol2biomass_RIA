#' Smooth the cumPools data.table
#'
#' This uses the Chapman Richards equation to smooth the curves that are
#' in \code{colsToUse}.
#' @param cumPoolsRaw Data.table with a numeric column called \code{age} and
#'   columns called \code{colsToUse}.
#' @param colsToUse A character vector of columns to smooth.
#' @param colsToUseNew A character vector of column names for the new smoothed columns
#' @export
#' @author Celine Boisvenue and Eliot McIntire
#' @return
#' A data.table with original columns plus new columns named \code{colsToUseNew}.
cumPoolsSmooth <- function(cumPoolsRaw, colsToUse = c("totMerch", "fol", "other"),
                           colsToUseNew = paste0(colsToUse, "_New"))  {
  cpr <- cumPoolsRaw # no copy -- just convenicne
  cpr[, (colsToUse) := lapply(.SD, as.numeric), .SDcols = colsToUse]

  outInd <- character()

  outerInd <- 0
  lenUniqueID_ecozone <- length(unique(cpr[["gcids"]]))

  cpr[, (colsToUseNew) := {
    outerInd <<- outerInd + 1
    N <- .N
    # Find blip, first minimum after that blip, and real maximum
    # blipInd -- calculate 2nd derivative (using diff(diff())), pad with 2 zeros (b/c diff removes 1 value each time)
    blipInd <- which.max(abs(c(0, 0, diff(diff(totMerch)))))
    # firstMin is the lowest value to the right of blipInd -- if it is next index, fine, or if well right, also fine
    firstMin <- which.min(totMerch[seq(blipInd+1, N - 40)]) + blipInd
    # realMax is the first maximum after the first minimum after the blipInd
    realMax <- which.max(totMerch[seq(firstMin+1, N)]) + firstMin
    firstInflection <- tail(which(0.12 * totMerch[realMax] > totMerch), 1)

    ## ORig
    ind <- seq(N)
    wts <- rep(1L, N)
    wts[unique(pmin(N, realMax + -10:10))] <- 100
    wts[ind > (realMax + 40) ] <- 0
    outInd <<- .BY
    SD <- .SD
    print(paste0(outerInd, " of ", lenUniqueID_ecozone, ": ", outInd))
    SD <- copy(.SD)
    SD[, override := .I > firstInflection & .I < firstMin]
    SD[override == TRUE, (colsToUse) := NA]
    SD[is.na(totMerch),
       (colsToUse) := list(
         approx(SD$age, SD$totMerch, xout = SD$age[is.na(SD$totMerch)])$y,
         approx(SD$age, SD$fol, xout = SD$age[is.na(SD$fol)])$y,
         approx(SD$age, SD$other, xout = SD$age[is.na(SD$other)])$y
       )
    ]
    newVals <- lapply(colsToUse, function(c2u) {
      Astart <- get(c2u)[realMax]
      for(ii in 1:2000) {
        # Chapman Richards
        nlsout <- try(nlrob(as.formula(paste(c2u, "~ A * (1 - exp(-k * age))^p")),
                            data = SD, #maxit = 200,
                            weights = wts,
                            # control = nls.control(maxiter = 150, tol = 1e-05, minFactor = 1e-8),
                            start = list(A = Astart, k = runif(1, 0.0001, 0.1), p = runif(1, 1, 60)),
                            trace = FALSE), silent = TRUE)
        if (!is(nlsout, "try-error"))
          break
      }
      fittedNew <- fitted(nlsout)
      diffr <- c(diff(ifelse(get(c2u) > fittedNew, 1, -1)), 0)
      lastCrossing <- tail(which(diffr != 0), 1)
      newVals <- ifelse(ind >= lastCrossing, get(c2u), fittedNew)
      newVals
    })

    newVals
  }, by = "gcids"]
}
