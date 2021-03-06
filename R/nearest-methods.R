### =========================================================================
### nearest (and related) methods
### -------------------------------------------------------------------------
###
### Dependencies :
###
###        distanceToNearest
###          |          |
###       nearest    distance
###       |     | 
###  precede   follow

.orderNumeric <- function(x)            # unstable order
    sort.list(x, na.last=NA, method="quick")

.GenomicRanges_findNearest0 <-
    function (query, subject, sentinel, leftOf=TRUE)
    ## query 'leftOf' subject
{
    sentinelidx <- length(subject) + seq_along(sentinel)
    subject <- c(subject, sentinel)

    ord <- .orderNumeric(subject)
    subject <- subject[ord]

    rle <- Rle(subject)
    subject <- runValue(rle)

    i <- findInterval(query - !leftOf, subject) + leftOf
    i[subject[i] %in% sentinel] <- NA_integer_
 
    IRanges:::vectorToHits(i, rle, ord)
}

.findNearest_distance <-
    function(hit, query, subject, leftOf=TRUE)
    ## query 'leftOf' of subject
{
    if (leftOf)
        start(subject)[subjectHits(hit)] - end(query)[queryHits(hit)]
    else
        start(query)[queryHits(hit)] - end(subject)[subjectHits(hit)]
}

.Hits <- function(queryHits, subjectHits,
                  queryLength=as.integer(max(c(0, queryHits))),
                  subjectLength=as.integer(max(c(0, subjectHits))))
{
    o <- S4Vectors:::orderIntegerPairs(queryHits, subjectHits)
    Hits(queryHits[o], subjectHits[o], queryLength, subjectLength)
}

.findPrecedeFollow_pmin <-
    function(hit0, dist0, hit1, dist1)
    ## hit0, hit1 are (possibly multiple) hits on same query; repeated
    ## hits are equidistant within hit0 or hit1, but not necessarily
    ## between
{
    stopifnot(queryLength(hit0) == queryLength(hit1))
    stopifnot(subjectLength(hit0) == subjectLength(hit1))
    stopifnot(length(hit0) == length(dist0) ||
        length(hit1) == length(dist1))

    n <- queryLength(hit0)
    d0 <- d1 <- integer()
    d0[n] <- d1[n] <- NA_integer_

    i0 <- queryHits(hit0)
    i1 <- queryHits(hit1)

    d0[i0] <- dist0
    d1[i1] <- dist1

    dMin <- pmin.int(d0, d1, na.rm=TRUE)
    i0 <- dist0 == dMin[i0]
    i1 <- dist1 == dMin[i1]

    .Hits(c(queryHits(hit0)[i0], queryHits(hit1)[i1]),
          c(subjectHits(hit0)[i0], subjectHits(hit1)[i1]),
          queryLength(hit0), subjectLength(hit0))
}

.GenomicRanges_findPrecedeFollow <-
    function(query, subject, select, ignore.strand, 
             where=c("precede", "follow"))
{
    if (!length(query) || !length(subject))
        return(Hits(queryLength=length(query), subjectLength=length(subject)))

    leftOf <- "precede" == match.arg(where)
    if (ignore.strand)
        strand(query) <- strand(subject) <- "+"

    if (leftOf) {
        plusfun <- function(xstart, xend, ystart, yend, sentinel)
            .GenomicRanges_findNearest0(xend, ystart, sentinel, leftOf)
        minusfun <- function(xstart, xend, ystart, yend, sentinel)
            .GenomicRanges_findNearest0(xstart, yend, sentinel, !leftOf)
    } else {
        plusfun <- function(xstart, xend, ystart, yend, sentinel)
            .GenomicRanges_findNearest0(xstart, yend, sentinel, leftOf)
        minusfun <- function(xstart, xend, ystart, yend, sentinel)
            .GenomicRanges_findNearest0(xend, ystart, sentinel, !leftOf)
    }

    ## sentinels marking seqlevels ends
    endq <- start(query) + width(query) # end(query) incorrect for 0-width
    ends <- start(subject) + width(subject)
    maxend <- max(max(endq), max(ends)) + 1
    lvls <- union(seqlevels(query), seqlevels(subject))
    offset <- setNames((seq_along(lvls) - 1) * maxend, lvls)
    stopifnot(typeof(offset) == "double")      # avoid integer overflow
    sentinel <- c(0, seq_along(lvls) * maxend)

    ## offset for sentinels
    queryOff <- unname(offset[as.character(seqnames(query))])
    queryStart <- start(query) + queryOff
    queryEnd <- end(query) + queryOff   # true end + offset
    qid <- seq_along(query)

    subjectOff <- unname(offset[as.character(seqnames(subject))])
    subjectStart <- start(subject) + subjectOff
    subjectEnd <- end(subject) + subjectOff # true end + offset
    spid <- which(strand(subject) != "-")
    smid <- which(strand(subject) != "+")

    ## '+' query
    idx <- which(strand(query) == "+")
    phit <- plusfun(queryStart[idx], queryEnd[idx],
        subjectStart[spid], subjectEnd[spid], sentinel)
    phit <- .Hits(qid[idx][queryHits(phit)], spid[subjectHits(phit)])

    ## '-' query
    idx <- which(strand(query) == "-")
    mhit <- minusfun(queryStart[idx], queryEnd[idx],
        subjectStart[smid], subjectEnd[smid], sentinel)
    mhit <- .Hits(qid[idx][queryHits(mhit)], smid[subjectHits(mhit)])

    ## '*' query
    idx <- which(strand(query) == "*")
    bhit <- local({
        qid <- qid[idx]
        phit <- plusfun(queryStart[idx], queryEnd[idx],
            subjectStart[spid], subjectEnd[spid], sentinel)
        phit <- .Hits(qid[queryHits(phit)], spid[subjectHits(phit)],
            length(query), length(subject))
        mhit <- minusfun(queryStart[idx], queryEnd[idx],
            subjectStart[smid], subjectEnd[smid], sentinel)
        mhit <- .Hits(qid[queryHits(mhit)], smid[subjectHits(mhit)],
            length(query), length(subject))
        pdist <- .findNearest_distance(phit, query, subject, leftOf)
        mdist <- .findNearest_distance(mhit, query, subject, !leftOf)
        .findPrecedeFollow_pmin(phit, pdist, mhit, mdist)
    })

    ## clean up
    qryHits <- c(queryHits(phit), queryHits(mhit), queryHits(bhit))
    subjHits <- c(subjectHits(phit), subjectHits(mhit), subjectHits(bhit))
    if ("arbitrary" == select) {
        hits <- integer()
        hits[length(query)] <- NA_integer_
        idx <- !duplicated(qryHits) ## ties
        hits[qryHits[idx]] <- subjHits[idx]
    } else {
        hits <- .Hits(qryHits, subjHits, length(query), length(subject))
    }
    hits
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### precede() and follow()
###

setMethod("precede", c("GenomicRanges", "GenomicRanges"),
    function(x, subject, select=c("arbitrary", "all"), ignore.strand=FALSE)
    {
        select <- match.arg(select)
        .GenomicRanges_findPrecedeFollow(x, subject, select, ignore.strand, 
                                         "precede") 
    }
)

setMethod("precede", c("GenomicRanges", "missing"),
    function(x, subject, select=c("arbitrary", "all"), ignore.strand=FALSE)
    {
        select <- match.arg(select)
        .GenomicRanges_findPrecedeFollow(x, subject, select, ignore.strand, 
                                         "precede") 
    }
)

setMethod("follow", c("GenomicRanges", "GenomicRanges"),
    function(x, subject, select=c("arbitrary", "all"), ignore.strand=FALSE)
    {
        select <- match.arg(select)
        .GenomicRanges_findPrecedeFollow(x, subject, select, ignore.strand, 
                                         "follow") 
    }
)

setMethod("follow", c("GenomicRanges", "missing"),
    function(x, subject, select=c("arbitrary", "all"), ignore.strand=FALSE)
    {
        select <- match.arg(select)
        .GenomicRanges_findPrecedeFollow(x, subject, select, ignore.strand, 
                                         "follow") 
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### nearest()
###

.filterHits <- function(hits, i, map) 
{
    m <- as.matrix(hits[as(hits, "IRanges")[i]])
    m[, 1L] <- map[m[, 1L]]
    m
}

.nearest <- function(x, subject, select, algorithm,
                     ignore.strand, ignoreSelf=FALSE)
{
    ## overlapping ranges
    if (ignoreSelf) {
        ol <- findOverlaps(x, select=select, algorithm=algorithm,
                           ignore.strand=ignore.strand, ignoreSelf=TRUE)
    } else {
        ol <- findOverlaps(x, subject, select=select, algorithm=algorithm,
                           ignore.strand=ignore.strand)
    }

    if (select == "all") {
        olv <- selectHits(ol, select="first")
    } else {
        olv <- ol
    }

    ## non-overlapping ranges
    if (length(x <- x[is.na(olv)]) != 0) {
        p <- precede(x, subject, select, ignore.strand)
        f <- follow(x, subject, select, ignore.strand)

        ## terminate if no results
        if (!length(p) && !length(f)) {
            if (is(olv, "Hits") && !length(olv) || all(is.na(olv))) {
                if (select == "all") 
                    return(Hits(queryLength=length(x),
                                subjectLength=length(subject)))
                else if (select == "arbitrary")
                    return (rep(NA, length(x)))
            }
        }

        if (select == "all") {
            p0 <- p
            p <- selectHits(p, select="first")
            f0 <- f
            f <- selectHits(f, select="first")
        }

        ## choose nearest or not missing
        pdist <- .nearestDistance(x, subject, p)
        fdist <- .nearestDistance(x, subject, f)
        pnearest <- ifelse(pdist == fdist, p < f, pdist < fdist)
        isNA <- is.na(pnearest)
        pnearest[isNA] <- is.na(f[isNA])

        if (select == "all") {
            map <- which(is.na(olv))
            pnearest[pdist == fdist] <- TRUE
            m <- rbind(as.matrix(ol), .filterHits(p0, pnearest, map),
                                      .filterHits(f0, !pnearest, map))
            m <- m[S4Vectors:::orderIntegerPairs(m[, 1L], m[, 2L]),, drop=FALSE]
            ol@queryHits <- unname(m[, 1L])
            ol@subjectHits <- unname(m[, 2L])
        } else {
            olv[is.na(olv)] <- ifelse(pnearest, p, f) 
            ol <- olv
        }
    }
    ol
}

.nearestDistance <- function(x, subject, index)
{
    if (length(index)) {
        maxStart <- pmax.int(start(x), start(subject)[index])
        minEnd <- pmin.int(end(x), end(subject)[index])
        pmax.int(maxStart - minEnd - 1L, 0L)
    } else NA
}


setMethod("nearest", c("GenomicRanges", "GenomicRanges"),
    function(x, subject, select=c("arbitrary", "all"),
             algorithm=c("nclist", "intervaltree"), ignore.strand=FALSE)
    {
        select <- match.arg(select)
        .nearest(x, subject, select=select, algorithm=match.arg(algorithm),
                 ignore.strand=ignore.strand)
    }
)

setMethod("nearest", c("GenomicRanges", "missing"),
    function(x, subject, select=c("arbitrary", "all"),
             algorithm=c("nclist", "intervaltree"), ignore.strand=FALSE)
    {
        select <- match.arg(select)
        .nearest(x, x, select=select, algorithm=match.arg(algorithm),
                 ignore.strand=ignore.strand, ignoreSelf=TRUE)
    }
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### distance()
###

setMethod("distance", c("GenomicRanges", "GenomicRanges"),
    function(x, y, ignore.strand=FALSE, ...)
    {
        if (!isTRUEorFALSE(ignore.strand))
            stop("'ignore.strand' must be TRUE or FALSE")
        d <- distance(ranges(x), ranges(y))
        mismtch <- as.character(seqnames(x)) != as.character(seqnames(y))
        if (any(mismtch))
            d[mismtch] <- NA
        if (!ignore.strand) {
            idx <- as.numeric(strand(x)) + as.numeric(strand(y))
            if (any(idx == 3))
                d[idx == 3] <- NA
        }
        d
    }
)

### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### distanceToNearest()
###

setMethod("distanceToNearest", c("GenomicRanges", "GenomicRanges"),
    function(x, subject, algorithm=c("nclist", "intervaltree"),
             ignore.strand=FALSE, ...)
    {
        x_nearest <- nearest(x, subject, algorithm=match.arg(algorithm),
                             ignore.strand=ignore.strand, ...)
        .distanceToNearest(x_nearest, x, subject, ignore.strand=ignore.strand)
    }
)

setMethod("distanceToNearest", c("GenomicRanges", "missing"),
    function(x, subject, algorithm=c("nclist", "intervaltree"),
             ignore.strand=FALSE, ...)
    {
        x_nearest <- nearest(x, algorithm=match.arg(algorithm),
                             ignore.strand=ignore.strand, ...)
        .distanceToNearest(x_nearest, x, x, ignore.strand=ignore.strand)
    }
)

.distanceToNearest <- function(x_nearest, x, subject, ignore.strand)
{
    ## 'x_nearest' is Hits when select = all
    if (is(x_nearest, "Hits")) {
        queryHits <- queryHits(x_nearest)
        subjectHits <- subjectHits(x_nearest)
    } else {
    ## 'x_nearest' is Integer vector when select = arbitrary
        queryHits <- seq_along(x)[!is.na(x_nearest)]
        subjectHits <- x_nearest[!is.na(x_nearest)]
    }

    if (!length(subjectHits) || all(is.na(subjectHits))) {
        Hits(queryLength=length(x), 
             subjectLength=length(subject),
             distance=integer(0))
    } else {
        distance <- distance(x[queryHits], subject[subjectHits],
                             ignore.strand=ignore.strand)
        Hits(queryHits, subjectHits, length(x), length(subject), distance)
    }
}

