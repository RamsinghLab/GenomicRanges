\name{SummarizedExperiment-class}
\docType{class}

% Class
\alias{SummarizedExperiment-class}
\alias{SummarizedExperiment}

% Constructor-like function:
\alias{SummarizedExperiment}
\alias{SummarizedExperiment,missing-method}
\alias{SummarizedExperiment,matrix-method}
\alias{SummarizedExperiment,list-method}
\alias{SummarizedExperiment,SimpleList-method}

% Coercion methods:

% Accessor methods:
\alias{assays}
\alias{assays,SummarizedExperiment-method}
\alias{assays<-}
\alias{assays<-,SummarizedExperiment,list-method}
\alias{assays<-,SummarizedExperiment,SimpleList-method}
\alias{assay}
\alias{assay,SummarizedExperiment,ANY-method}
\alias{assay,SummarizedExperiment,character-method}
\alias{assay,SummarizedExperiment,numeric-method}
\alias{assay,SummarizedExperiment,missing-method}
\alias{assay<-}
\alias{assay<-,SummarizedExperiment,character,matrix-method}
\alias{assay<-,SummarizedExperiment,numeric,matrix-method}
\alias{assay<-,SummarizedExperiment,missing,matrix-method}
\alias{rowData}
\alias{rowData,SummarizedExperiment-method}
\alias{rowData<-}
\alias{rowData<-,SummarizedExperiment,GenomicRanges-method}
\alias{colData}
\alias{colData,SummarizedExperiment-method}
\alias{colData<-}
\alias{colData<-,SummarizedExperiment,DataFrame-method}
\alias{exptData}
\alias{exptData,SummarizedExperiment-method}
\alias{exptData<-}
\alias{exptData<-,SummarizedExperiment,SimpleList-method}
\alias{exptData<-,SummarizedExperiment,list-method}
\alias{dim,SummarizedExperiment-method}
\alias{dimnames,SummarizedExperiment-method}
\alias{dimnames<-,SummarizedExperiment,NULL-method}
\alias{dimnames<-,SummarizedExperiment,list-method}

% Subset methods
\alias{[,SummarizedExperiment-method}
\alias{[<-,SummarizedExperiment,ANY,ANY,SummarizedExperiment-method}

% show method:
\alias{show,SummarizedExperiment-method}

\title{SummarizedExperiment instances}

\description{

  The SummarizedExperiment class is an eSet-like container where rows
  represent ranges of interest (as a \code{\linkS4class{GRanges}-class})
  and columns represent samples (with sample data summarized as a
  \code{\linkS4class{DataFrame}-class}). A \code{SummarizedExperiment}
  contains one or more assays, each represented by a matrix of numeric
  or other mode.

}

\usage{

## Constructors

SummarizedExperiment(assays, ...)
\S4method{SummarizedExperiment}{SimpleList}(assays, rowData = GRanges(),
    colData = DataFrame(), exptData = SimpleList(), ...,
    verbose = FALSE)
\S4method{SummarizedExperiment}{missing}(assays, ...)
\S4method{SummarizedExperiment}{list}(assays, ...)
\S4method{SummarizedExperiment}{matrix}(assays, ...)

## Accessors

assays(x, ..., withDimnames=TRUE)
assays(x, ...) <- value
assay(x, i, ...)
assay(x, i, ...) <- value
rowData(x, ...)
rowData(x, ...) <- value
colData(x, ...)
colData(x, ...) <- value
exptData(x, ...)
exptData(x, ...) <- value
\S4method{dim}{SummarizedExperiment}(x)
\S4method{dimnames}{SummarizedExperiment}(x)
\S4method{dimnames}{SummarizedExperiment,NULL}(x) <- value
\S4method{dimnames}{SummarizedExperiment,list}(x) <- value

## Subsetting

\S4method{[}{SummarizedExperiment}(x, i, j, ..., drop=TRUE)
\S4method{[}{SummarizedExperiment,ANY,ANY,SummarizedExperiment}(x, i, j) <- value

}

\arguments{

  \item{assays}{A \code{list} or \code{SimpleList} of matrix elements,
    or a \code{matrix}. Each element of the list must have the same
    dimensions, and dimension names (if present) must be consistent
    across elements and with the row names of \code{rowData},
    \code{colData}.}

  \item{rowData}{A \code{GRanges} instance describing the ranges of
    interest. Row names, if present, become the row names of the
    \code{SummarizedExperiment}.}

  \item{colData}{An optional \code{DataFrame} describing the
    samples. Row names, if present, become the column names of the
    \code{SummarizedExperiment}.}

  \item{exptData}{An optional \code{SimpleList} of arbitrary content
    describing the overall experiment.}

  \item{...}{For \code{SummarizedExperiment}, S4 methods \code{list}
    and \code{matrix}, arguments identical to those of the
    \code{SimpleList} method.

    For \code{assay}, \code{...} may contain \code{withNames}, which is
    forwarded to \code{assays}.

    For other accessors, ignored.

  }

  \item{verbose}{A \code{logical(1)} indicating whether messages
    about data coercion during construction should be printed.}

  \item{x}{An instance of \code{SummarizedExperiment}-class.}

  \item{i, j}{For \code{assay}, \code{assay<-}, \code{i} is a integer or
    numeric scalar; see \sQuote{Details} for additional constraints.

    For \code{SummarizedExperiment}, \code{SummarizedExperiment<-},
    \code{i}, \code{j} are instances that can act to subset the
    underlying \code{rowData}, \code{colData}, and \code{matrix}
    elements of \code{assays}.}

  \item{withDimnames}{A \code{logical(1)}, indicating whether dimnames
    should be applied to extracted assay elements.}

  \item{drop}{A \code{logical(1)}, ignored by these methods.}

  \item{value}{An instance of a class specified in the S4 method
    signature or as outlined in \sQuote{Details}.}

}

\details{

  The \code{SummarizedExperiment} class is meant for numeric and other
  data types derived from a sequencing experiment. The structure is
  rectangular, like an \code{eSet} in \pkg{Biobase}.

  The rows of a \code{SummarizedExperiment} instance represent ranges
  (in genomic coordinates) of interest. The ranges of interest are
  described by a \code{\linkS4class{GRanges}-class} instance, accessible
  using the \code{rowData} function, described below. The \code{GRanges}
  class contains sequence (e.g., chromosome) name, genomic coordinates,
  and strand information. Each range can be annotated with additional
  data; this data might be used to describe the range (analogous to
  annotations associated with genes in a \code{eSet}) or to summarize
  results (e.g., statistics of differential abundance) relevant to the
  range. Rows may or may not have row names; they often will not.

  Each column of a \code{SummarizedExperiment} instance represents a
  sample.  Information about the samples are stored in a
  \code{\linkS4class{DataFrame}-class}, accessible using the function
  \code{colData}, described below. The \code{DataFrame} must have as
  many rows as there are columns in the \code{SummarizedExperiment},
  with each row of the \code{DataFrame} providing information on the
  sample in the corresponding column of the
  \code{SummarizedExperiment}. Columns of the \code{DataFrame} represent
  different sample attributes, e.g., tissue of origin, etc. Columns of
  the \code{DataFrame} can themselves be annotated (via the
  \code{\link{values}} function) in a fashion similar to the
  \code{varMetadata} facilities of the \code{eSet} class. Column names
  typically provide a short identifier unique to each sample.

  A \code{SummarizedExperiment} can also contain information about the
  overall experiment, for instance the lab in which it was conducted,
  the publications with which it is associated, etc. This information is
  stored as a \code{\linkS4class{SimpleList}-class}, accessible using
  the \code{exptData} function. The form of the data associated with the
  experiment is left to the discretion of the user.

  The \code{SummarizedExperiment} is appropriate for matrix-like
  data. The data are accessed using the \code{assays} function,
  described below. This returns a \code{SimpleList}-class instance. Each
  element of the list must itself be a matrix (of any mode) and must
  have dimensions that are the same as the dimensions of the
  \code{SummarizedExperiment} in which they are stored. Row and column
  names of each matrix must either be \code{NULL} or match those of the
  \code{SummarizedExperiment} during construction. It is convenient for
  the elements of \code{SimpleList} of assays to be named.

  The \code{SummarizedExperiment} class has the following slots; this
  detail of class structure is not relevant to the user.
  \describe{
    \item{\code{exptData}}{A \link{SimpleList}-class instance containing
      information about the overall experiment.}
    \item{\code{rowData}}{A \link{GRanges}-class instance defining the
      ranges of interest and associated metadata.}
    \item{\code{colData}}{A \link{DataFrame}-class instance describing
      the samples and associated metadata.}
    \item{\code{assays}}{A \link{SimpleList}-class instance, each
      element of which is a matrix summarizing data associated with the
      corresponding range and sample.}
  }
}

\section{Constructor}{

  Instances are constructed using the \code{SummarizedExperiment}
  function with arguments outlined above.

}

% \section{Coercion}{}

\section{Accessors}{

  In the following code snippets, \code{x} is a
  \code{SummarizedExperiment} instance.

  \describe{

    \item{\code{assays(x)}, \code{assays(x) <- value}:}{Get or set the
      assays. \code{value} is a \code{list} or \code{SimpleList}, each
      element of which is a matrix with the same dimensions as
      \code{x}.}

    \item{\code{assay(x, i)}, \code{assay(x, i) <- value}:}{A convenient
      alternative (to \code{assays(x)[[i]]}, \code{assays(x)[[i]] <-
      value}) to get or set the \code{i}th (default first) assay
      element. \code{value} must be a matrix of the same dimension as
      \code{x}, and with dimension names \code{NULL} or consistent with
      those of \code{x}.}

    \item{\code{rowData(x)}, \code{rowData(x) <- value}:}{Get or set the
      row data. \code{value} is a \code{GenomicRanges} instance. Row
      names of \code{value} must be NULL or consistent with the existing
      row names of \code{x}.}

    \item{\code{colData(x)}, \code{colData(x) <- value}:}{Get or set the
      column data. \code{value} is a \code{DataFrame} instance. Row
      names of \code{value} must be NULL or consistent with the existing
      column names of \code{x}.}

    \item{\code{exptData(x)}, \code{exptData(x) <- value}:}{Get or set
      the experiment data. \code{value} is a \code{list} or
      \code{SimpleList} instance, with arbitrary content.}

    \item{\code{dim(x)}:}{Get the dimensions (ranges x samples) of the
      \code{SummarizedExperiment}.}

    \item{\code{dimnames(x)}, \code{dimnames(x) <- value}:}{Get or set
      the dimension names. \code{value} is usually a list of length 2,
      containing elements that are either \code{NULL} or vectors of
      appropriate length for the corresponding dimension. \code{value}
      can be \code{NULL}, which removes dimension names. This method
      implies that \code{rownames}, \code{rownames<-}, \code{colnames},
      and \code{colnames<-} are all available.}

  }
}

\section{Subsetting}{

  In the code snippets below, \code{x} is a \code{SummarizedExperiment}
  instance.

  \describe{

    \item{\code{x[i,j]}, \code{x[i,j] <- value}:}{Create or replace a
      subset of \code{x}. \code{i}, \code{j} can be \code{numeric},
      \code{logical}, \code{character}, or \code{missing}. \code{value}
      must be a \code{SummarizedExperiment} instance with dimensions,
      dimension names, and assay elements consistent with the subset
      \code{x[i,j]} being replaced.}

  }
}

\author{Martin Morgan, \url{mtmorgan@fhcrc.org}}

\seealso{
  \link{GRanges},
  \link[IRanges]{DataFrame},
  \link[IRanges]{SimpleList},
}

\examples{
  nrows <- 200; ncols <- 6
  counts <- matrix(runif(nrows * ncols, 1, 1e4), nrows)
  rowData <- GRanges(rep(c("chr1", "chr2"), c(50, 150)),
                     IRanges(floor(runif(200, 1e5, 1e6)), width=100),
                     strand=sample(c("+", "-"), 200, TRUE))
  colData <- DataFrame(Treatment=rep(c("ChIP", "Input"), 3),
                       row.names=LETTERS[1:6])
  sset <- SummarizedExperiment(assays=SimpleList(counts=counts),
                 rowData=rowData, colData=colData)
  sset
  assays(sset) <- endoapply(assays(sset), asinh)
  head(assay(sset))
}