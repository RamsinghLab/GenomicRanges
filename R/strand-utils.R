### =========================================================================
### Strand utilities
### -------------------------------------------------------------------------


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Some "strand" and "strand<-" methods
###

setMethod("strand", "missing", function(x) factor(levels=c("+","-","*")))
setMethod("strand", "NULL", function(x) strand())

setMethod("strand", "character",
    function(x)
    {
        lvls <- levels(strand())
        if (!all(x %in% lvls))
            stop("strand values must be in '", paste(lvls, collapse="' '"), "'")
        factor(x, levels=lvls)
    }
)

setMethod("strand", "factor",
    function(x)
    {
        if (any(is.na(x)))
            stop("NA not a valid strand value, use \"*\" instead")
        lvls <- levels(strand())
        x_levels <- levels(x)
        if (identical(x_levels, lvls))
            return(x)
        invalid_levels <- setdiff(x_levels, lvls)
        if (length(invalid_levels) != 0L)
            stop("invalid strand levels in 'x': ",
                 paste(invalid_levels, collapse=", "))
        factor(x, levels=lvls)
    }
)

setMethod("strand", "integer",
    function(x)
    {
        lvls <- c(1L, -1L, NA)
        if (!all(x %in% lvls))
            stop("strand values must be in '", paste(lvls, collapse="' '"), "'")
        ans <- rep.int(strand("*"), length(x))
        ans[x ==  1L] <- "+"
        ans[x == -1L] <- "-"
        ans
    }
)

setMethod("strand", "logical",
    function(x)
    {
        ans <- rep.int(strand("*"), length(x))
        ans[!x] <- "+"
        ans[ x] <- "-"
        ans
    }
)

setMethod("strand", "Rle",
    function(x)
    {
        x_runValue <- runValue(x)
        if (!(is.character(x_runValue) ||
              is.factor(x_runValue) ||
              is.integer(x_runValue) ||
              is.logical(x_runValue)))
            stop("\"strand\" method for Rle objects only works on a ",
                 "character-, factor-, integer-, or logical-Rle object")
        runValue(x) <- strand(x_runValue)
        x
    }
)

setMethod("strand", "DataTable",
    function(x)
    {
        ans <- x[["strand"]]
        if (is.null(ans)) {
            ans <- rep.int(strand("*"), nrow(x))
        } else {
            ans <- strand(ans)
        }
        ans
    }
)

setReplaceMethod("strand", "DataTable", function(x, value) {
  x$strand <- normargGenomicRangesStrand(value, nrow(x))
  x
})


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### compatibleStrand() generic and methods
###

setGeneric("compatibleStrand", signature=c("x","y"),  # not exported
    function(x, y) standardGeneric("compatibleStrand")
)

setMethod("compatibleStrand", c("factor", "factor"),  # not exported
    function(x, y)
    {
        lvls <- levels(strand())
        if (length(x) != length(y))
            stop("'x' and 'y' must be of equal length")
        if (!identical(levels(x), lvls) || !identical(levels(y), lvls))
            stop("strand values must be in '", paste(lvls, collapse="' '"), "'")

        levels(x) <- c("1", "-1", "0")
        x <- as.integer(as.character(x))

        levels(y) <- c("1", "-1", "0")
        y <- as.integer(as.character(y))

        ans <- x * y != -1L
        if (S4Vectors:::anyMissing(ans)) {
            fix <- which(is.na(ans))
            ans[fix] <- (x[fix] == 0L) | (y[fix] == 0L)
            if (S4Vectors:::anyMissing(ans))
                ans[is.na(ans)] <- FALSE
        }
        ans
    }
)

setMethod("compatibleStrand", c("Rle", "Rle"),  # not exported
    function(x, y)
    {
        lvls <- levels(strand())
        if (length(x) != length(y))
            stop("'x' and 'y' must be of equal length")
        if (!identical(levels(runValue(x)), lvls) ||
            !identical(levels(runValue(y)), lvls))
            stop("strand values must be in '", paste(lvls, collapse="' '"), "'")

        levels(x) <- c("1", "-1", "0")
        runValue(x) <- as.integer(as.character(runValue(x)))

        levels(y) <- c("1", "-1", "0")
        runValue(y) <- as.integer(as.character(runValue(y)))

        ans <- x * y != -1L
        if (S4Vectors:::anyMissing(runValue(ans))) {
            fix <- which(is.na(runValue(ans)))
            runValue(ans)[fix] <-
              (runValue(x) == 0L)[fix] | (runValue(y)[fix] == 0L)
            if (S4Vectors:::anyMissing(runValue(ans)))
                runValue(ans)[is.na(runValue(ans))] <- FALSE
        }
        ans
    }
)

