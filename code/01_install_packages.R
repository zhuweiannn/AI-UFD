
script_path_local <- local({
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/", mustWork = FALSE)
  } else {
    frame_files <- vapply(sys.frames(), function(env) if (!is.null(env$ofile)) env$ofile else NA_character_, character(1))
    frame_files <- frame_files[!is.na(frame_files)]
    if (length(frame_files) > 0) normalizePath(frame_files[1], winslash = "/", mustWork = FALSE) else normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  }
})

source(file.path(dirname(script_path_local), "00_common.R"), local = TRUE)

install_required_packages <- function() {
  required_packages <- c(
    "readxl",
    "ggplot2",
    "dplyr",
    "tidyr",
    "patchwork",
    "png",
    "svglite",
    "cowplot"
  )

  missing <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

  if (length(missing) == 0) {
    message("All required R packages are already installed.")
    return(invisible(character(0)))
  }

  message("Installing R packages: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org")
  message("Package installation completed.")

  invisible(missing)
}

if (identical(environment(), globalenv()) && !interactive()) {
  install_required_packages()
}
