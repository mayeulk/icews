% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/database.R
\name{delete_events}
\alias{delete_events}
\title{Delete events associated with a file}
\usage{
delete_events(file, db_path)
}
\arguments{
\item{file}{The normalized filename, e.g. "events.1995.\link{...}.tab", without
".zip" ending.}

\item{db_path}{Path to SQLite database file}
}
\description{
Delete events associated with a file
}
\seealso{
\code{\link[=purge_db]{purge_db()}}, \code{\link[=delete_events]{delete_events()}}
}
\keyword{internal}
