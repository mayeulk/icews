#
#   Functions related to determining the local vs DVN state
#

#' Get DVN/local file/database state
#'
#' Determine what data files are currently on dataverse, in the local files,
#' or in the local database.
#'
#' @rdname state
#'
#' @param icews_doi DOI of the main ICEWS repo on Dataverse, see [get_doi()]
#' @param server For unit tests only; default is set to [dataverse::get_dataset()] default.
#'
#' @details The data files (tab-separated files, ".tab") on dataverse that
#'   contain the raw event data follow a common format denoting the set of
#'   events contained in a file and which version of the event data and/or file
#'   dump they correspond to. For example, "events.1995.20150313082510.tab"
#'   contains events for 1995 and the version is denoted by the timestamp,
#'   "20150313082510".
#'
#'   The download and update functions
#'   ([update_icews()], [download_data()]) will recognize which event sets
#'   are locally available or still need to be downloaded, and whether any
#'   local even sets have been superseded by a new version in dataverse, by
#'   using
#'
#' @return
#'   For `get_dvn_manifest`, a tibble with the following columns:
#'   - dvn_repo: "historic" or "daily", see [get_doi()]
#'   - dvn_file_label: the file label on dataverse, possibly non-unique
#'   - dvn_file_id: the integer file ID on dataverse
#'   - file_name: the normalized, unique file name, see [normalize_label()]
#'
#'  For `get_local_state` and `get_db_state`, a tibble with columns:
#'   - file_name: the full source data file name, e.g.
#'     "events.1995.20150313082510.tab"; see [normalize_label()]
#'
#' @examples
#' \dontrun{
#' # Remote (DVN) state
#' get_dvn_state()
#' # Local file state
#' get_local_state()
#' # Database state
#' get_db_state()
#' }
#'
#' @md
#' @export
#' @import dataverse
#' @import tibble
get_dvn_state <- function(icews_doi = get_doi(), server = Sys.getenv("DATAVERSE_SERVER")) {
  dvn_manifest <- get_dvn_manifest()

  # we only need this for data files
  file_list    <- dvn_manifest$file_list %>%
    dplyr::filter(category=="Data") %>%
    dplyr::arrange(id)
  dict <- tibble(
    dvn_repo = file_list$repo,
    dvn_file_label = file_list$label,
    dvn_file_id    = file_list$id
  )
  dict$file_name <- normalize_label(dict$dvn_file_label)

  dict
}


#' List dataverse files
#'
#' Get a listing of files on dataverse
#'
#' @param icews_doi DOI of the main ICEWS repo on Dataverse, see [get_doi()]
#' @param server For unit tests only; default is set to [dataverse::get_dataset()] default.
#'
#' @return A list of length 2, containing:
#'
#'   - file_list: a summary list of all files on DVN, consisting of the data files
#'     but also documentation and metadata files.
#'   - dataverse_dataset: a list tibble with two columns:
#'       + `repo`: "daily" or "historic"`
#'       + `content`: objects of class "dataverse_dataset", returned by
#'         [dataverse::get_dataset()].
#'
#' @export
get_dvn_manifest <- function(icews_doi = get_doi(), server = Sys.getenv("DATAVERSE_SERVER")) {
  dvn_files  <- tryCatch(
    tibble(repo = c("historic", "daily"),
           content = list(
             dataverse::get_dataset(icews_doi$historic, server = server),
             dataverse::get_dataset(icews_doi$daily, server = server)
           )),
    error = function(e) {
      stop("Something went wrong in 'dataverse' or the Dataverse API, try again. Original error message:\n", e$message)
    })

  file_list <- bind_rows(
    tibble::tibble(
      repo = "historic",
      label = dvn_files$content[[1]]$files$label,
      id = dvn_files$content[[1]]$files$id,
      category = unlist(dvn_files$content[[1]]$files$categories),
      description = dvn_files$content[[1]]$files$description
    ),
    tibble::tibble(
      repo = "daily",
      label = dvn_files$content[[2]]$files$label,
      id = dvn_files$content[[2]]$files$id,
      category = "Data",
      description = dvn_files$content[[2]]$files$description
    )
  )

  # filter out known corrupt file
  file_list <- file_list[!file_list$label=="20181006-icews-events.zip", ]

  list(
    file_list          = file_list,
    dataverse_datasets = dvn_files
  )
}


#' Normalize a data file label
#'
#' Normalize the dataverse file label, i.e. substitute ".tab" for zipped files
#' and alter duplicate file names
#'
#' @param x character string, DVN file label
#'
#' @return A character vector with normalized file names.
#'
#' @import tibble
#' @keywords internal
normalize_label <- function(x) {

  x <- as.character(x)
  x <- gsub(".tab.zip", ".tab", x)
  x <- gsub(".zip", ".tab", x)

  # fix known duplicate file label (fix manually because i want future
  # occurrences of duplicates to trip errors)
  idx <- x=="20190309-icews-events.tab"
  mod <- x[idx]
  mod <- gsub(".tab", "", mod)
  mod <- paste0(mod, "-part", 1:length(mod), ".tab")
  x[idx] <- mod

  x
}

