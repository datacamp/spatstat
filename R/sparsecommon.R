#'
#'    sparsecommon.R
#'
#'  Utilities for sparse arrays
#'
#'  $Revision: 1.5 $  $Date: 2017/02/22 08:00:18 $
#'

#'  .............. completely generic ....................


inside3Darray <- function(d, i, j, k) {
  stopifnot(length(d) == 3)
  if(length(dim(i)) == 2 && missing(j) && missing(k)) {
    stopifnot(ncol(i) == 3)
    j <- i[,2]
    k <- i[,3]
    i <- i[,1]
  }
  ans <- inside.range(i, c(1, d[1])) &
         inside.range(j, c(1, d[2])) &
         inside.range(k, c(1, d[3]))
  return(ans)
}

#'  .............. sparse3Darray ....................


mapSparseEntries <- function(x, margin, values, conform=TRUE, across) {
  # replace the NONZERO entries of sparse matrix or array
  # by values[l] where l is one of the slice indices
  dimx <- dim(x)
  if(inherits(x, "sparseMatrix")) {
    x <- as(x, Class="TsparseMatrix")
    if(length(x$i) == 0) {
      # no entries
      return(x)
    }
    stopifnot(margin %in% 1:2)
    check.nvector(values, dimx[margin], things=c("rows","columns")[margin],
                  oneok=TRUE)
    if(length(values) == 1) values <- rep(values, dimx[margin])
    i <- x@i + 1L
    j <- x@j + 1L
    yindex <- switch(margin, i, j)
    y <- sparseMatrix(i=i, j=j, x=values[yindex],
                      dims=dimx, dimnames=dimnames(x))
    return(y)
  }
  if(inherits(x, "sparse3Darray")) {
    if(length(x$i) == 0) {
      # no entries
      return(x)
    }
    ijk <- cbind(i=x$i, j=x$j, k=x$k)
    if(conform) {
      #' ensure common pattern of sparse values
      #' in each slice on 'across' margin
      nslice <- dimx[across]
      dup <- duplicated(ijk[,-across,drop=FALSE])
      ijk <- ijk[!dup, , drop=FALSE]
      npattern <- nrow(ijk)
      #' repeat this pattern in each 'across' slice
      ijk <- apply(ijk, 2, rep, times=nslice)
      ijk[, across] <- rep(seq_len(nslice), each=npattern)
    }
    if(!is.matrix(values)) {
      # vector of values matching margin extent
      check.nvector(values, dimx[margin],
                    things=c("rows","columns","planes")[margin],
                    oneok=TRUE)
      if(length(values) == 1) values <- rep(values, dimx[margin])
      yindex <- ijk[,margin]
      y <- sparse3Darray(i=ijk[,1],
                         j=ijk[,2],
                         k=ijk[,3],
                         x=values[yindex],
                         dims=dimx, dimnames=dimnames(x))
      return(y)
    } else {
      #' matrix of values.
      force(across)
      stopifnot(across != margin) 
      #' rows of matrix must match 'margin'
      if(nrow(values) != dimx[margin])
        stop(paste("Number of rows of values", paren(nrow(values)),
                   "does not match array size in margin", paren(dimx[margin])),
             call.=FALSE)
      #' columns of matrix must match 'across'
      if(ncol(values) != dimx[across])
        stop(paste("Number of columns of values", paren(ncol(values)),
                   "does not match array size in 'across'",
                   paren(dimx[across])),
             call.=FALSE)
      # map
      yindex <- ijk[,margin]
      zindex <- ijk[,across]
      y <- sparse3Darray(i=ijk[,1], j=ijk[,2], k=ijk[,3],
                         x=values[cbind(yindex,zindex)],
                         dims=dimx, dimnames=dimnames(x))
      return(y)
    } 
  }
  stop("Format of x not understood")
}


applySparseEntries <- local({

  applySparseEntries <- function(x, f, ...) {
    ## apply vectorised function 'f' only to the nonzero entries of 'x'
    if(inherits(x, "sparseMatrix")) {
      x <- applytoxslot(x, f, ...)
    } else if(inherits(x, "sparse3Dmatrix")) {
      x <- applytoxentry(x, f, ...)
    } else {
      x <- f(x, ...)
    }
    return(x)
  }

  applytoxslot <- function(x, f, ...) {
    xx <- x@x
    n <- length(xx)
    xx <- f(xx, ...)
    if(length(xx) != n)
      stop(paste("Function f returned the wrong number of values:",
                 length(xx), "instead of", n),
           call.=FALSE)
    x@x <- xx
    return(x)
  }
  
  applytoxentry <- function(x, f, ...) {
    xx <- x$x
    n <- length(xx)
    xx <- f(xx, ...)
    if(length(xx) != n)
      stop(paste("Function f returned the wrong number of values:",
                 length(xx), "instead of", n),
           call.=FALSE)
    x$x <- xx
    return(x)
  }
  
  applySparseEntries
})

