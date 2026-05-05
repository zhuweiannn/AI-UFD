
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

normalize_rounded_zero <- function(x, digits = 2) {
  if (is.null(x) || length(x) == 0 || all(is.na(x))) {
    return(x)
  }
  x_num <- suppressWarnings(as.numeric(x))
  tol <- 0.5 * 10^(-digits)
  x_num[is.finite(x_num) & abs(x_num) < tol] <- 0
  x_num
}

fmt_number <- function(x, digits = 2, na_value = "") {
  if (length(x) == 0 || is.null(x) || all(is.na(x))) {
    return(na_value)
  }
  x_num <- normalize_rounded_zero(x, digits = digits)
  sprintf(paste0("%.", digits, "f"), x_num)
}

fmt_percent <- function(x, digits = 1, na_value = "") {
  if (length(x) == 0 || is.null(x) || all(is.na(x))) {
    return(na_value)
  }
  paste0(fmt_number(x, digits = digits, na_value = na_value), "%")
}

fmt_ccc <- function(x) fmt_number(x, digits = 3)
fmt_ci <- function(x) fmt_number(x, digits = 3)
fmt_auc <- function(x) fmt_number(x, digits = 3)
fmt_kappa <- function(x) fmt_number(x, digits = 3)
fmt_beta <- function(x) fmt_number(x, digits = 3)
fmt_threshold <- function(x) fmt_number(x, digits = 2)
fmt_bias_value <- function(x) fmt_number(x, digits = 2)
fmt_mae <- function(x) fmt_number(x, digits = 2)
fmt_rmse <- function(x) fmt_number(x, digits = 2)
fmt_bench_ccc <- function(x) fmt_number(x, digits = 6)
fmt_bench_ci <- function(x) fmt_number(x, digits = 6)

fmt_bias <- function(x, unit = NULL) {
  out <- fmt_bias_value(x)
  if (!is.null(unit) && nzchar(unit)) {
    paste0(out, " ", unit)
  } else {
    out
  }
}

fmt_loa <- function(low, high, unit = NULL) {
  out <- paste0(fmt_bias_value(low), " to ", fmt_bias_value(high))
  if (!is.null(unit) && nzchar(unit)) {
    paste0(out, " ", unit)
  } else {
    out
  }
}

get_script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/", mustWork = FALSE))
  }

  frame_files <- vapply(
    sys.frames(),
    function(env) if (!is.null(env$ofile)) env$ofile else NA_character_,
    character(1)
  )
  frame_files <- frame_files[!is.na(frame_files)]
  if (length(frame_files) > 0) {
    return(normalizePath(frame_files[1], winslash = "/", mustWork = FALSE))
  }

  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

parent_chain <- function(path) {
  out <- character(0)
  current <- normalizePath(path, winslash = "/", mustWork = FALSE)

  repeat {
    out <- c(out, current)
    parent <- dirname(current)
    if (identical(parent, current)) break
    current <- parent
  }

  unique(out)
}

find_project_root <- function(start_path = get_script_path()) {
  script_dir <- if (file.exists(start_path)) {
    dirname(normalizePath(start_path, winslash = "/", mustWork = FALSE))
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  }

  candidates <- unique(c(parent_chain(script_dir), parent_chain(getwd())))

  for (candidate in candidates) {
    if (dir.exists(file.path(candidate, "code_r"))) {
      return(normalizePath(candidate, winslash = "/", mustWork = TRUE))
    }
  }

  stop(
    "Cannot locate the project root. Run scripts from a repository containing the code_r directory.",
    call. = FALSE
  )
}

python_excel_available <- local({
  cache <- NULL

  function() {
    if (!is.null(cache)) return(cache)

    py <- Sys.which("python3")
    if (!nzchar(py)) {
      cache <<- FALSE
      return(cache)
    }

    tmp_script <- tempfile(fileext = ".py")
    on.exit(unlink(tmp_script), add = TRUE)

    writeLines(
      c(
        "import importlib.util",
        "import sys",
        "mods = ['pandas', 'openpyxl']",
        "ok = all(importlib.util.find_spec(m) is not None for m in mods)",
        "sys.exit(0 if ok else 1)"
      ),
      tmp_script
    )

    cache <<- identical(system2(py, tmp_script, stdout = FALSE, stderr = FALSE), 0L)
    cache
  }
})

trim_ws_names <- function(x) {
  gsub("^\\s+|\\s+$", "", x)
}

check_required_packages <- function(pkgs) {
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]

  if (python_excel_available()) {
    missing <- setdiff(missing, "readxl")
  }

  if (length(missing) > 0) {
    stop(
      paste0(
        "Missing required R packages: ",
        paste(missing, collapse = ", "),
        ". Run Rscript code_r/01_install_packages.R or install them manually."
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

read_excel_safe <- function(path, sheet = 1) {
  if (requireNamespace("readxl", quietly = TRUE)) {
    return(as.data.frame(readxl::read_excel(path, sheet = sheet), check.names = FALSE))
  }

  if (!python_excel_available()) {
    stop("Excel input requires either the readxl R package or Python with pandas and openpyxl: ", path, call. = FALSE)
  }

  py <- Sys.which("python3")
  tmp_csv <- tempfile(fileext = ".csv")
  tmp_script <- tempfile(fileext = ".py")
  on.exit(unlink(c(tmp_csv, tmp_script)), add = TRUE)

  sheet_mode <- if (is.numeric(sheet)) "index" else "name"
  sheet_value <- if (is.numeric(sheet)) as.character(as.integer(sheet) - 1L) else as.character(sheet)

  writeLines(
    c(
      "import pandas as pd",
      "import sys",
      "path, out_csv, sheet_mode, sheet_value = sys.argv[1:5]",
      "sheet = int(sheet_value) if sheet_mode == 'index' else sheet_value",
      "df = pd.read_excel(path, sheet_name=sheet)",
      "df.to_csv(out_csv, index=False)"
    ),
    tmp_script
  )

  out <- system2(
    py,
    c(tmp_script, normalizePath(path, winslash = "/", mustWork = TRUE), tmp_csv, sheet_mode, sheet_value),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    stop("Python Excel reader failed for: ", path, "\n", paste(out, collapse = "\n"), call. = FALSE)
  }

  utils::read.csv(tmp_csv, check.names = FALSE, stringsAsFactors = FALSE)
}

prepare_output_dirs <- function(root) {
  out_root <- file.path(root, "r_outputs")
  dirs <- list(
    root = out_root,
    figures = file.path(out_root, "figures"),
    figure_panels = file.path(out_root, "figures", "panels")
  )

  for (path in unname(dirs)) {
    if (!dir.exists(path)) {
      dir.create(path, recursive = TRUE, showWarnings = FALSE)
    }
  }

  dirs
}

replace_file_extension <- function(path, new_ext) {
  ext <- paste0(".", gsub("^\\.", "", new_ext))
  if (grepl("\\.[^.]+$", path)) {
    sub("\\.[^.]+$", ext, path)
  } else {
    paste0(path, ext)
  }
}

companion_pdf_path <- function(path) {
  replace_file_extension(path, "pdf")
}

companion_svg_path <- function(path) {
  replace_file_extension(path, "svg")
}

slugify_filename <- function(text) {
  text <- tolower(as.character(text %||% "panel"))
  text <- gsub("[^a-z0-9]+", "_", text)
  text <- gsub("^_+|_+$", "", text)
  if (!nzchar(text)) "panel" else text
}

panel_output_dir_for_figure <- function(figure_filename) {
  figure_stem <- tools::file_path_sans_ext(basename(figure_filename))
  out_dir <- file.path(dirname(figure_filename), "panels", figure_stem)
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  }
  out_dir
}

panel_size_from_layout <- function(figure_width, figure_height, col_widths, row_heights, col = 1, row = 1) {
  col_widths <- as.numeric(col_widths %||% 1)
  row_heights <- as.numeric(row_heights %||% 1)

  if (length(col_widths) < col || length(row_heights) < row) {
    stop("Panel row or column exceeds the specified layout.", call. = FALSE)
  }

  list(
    width = figure_width * col_widths[col] / sum(col_widths),
    height = figure_height * row_heights[row] / sum(row_heights)
  )
}

save_panel_plot_outputs <- function(
  panel_specs,
  figure_filename,
  figure_width,
  figure_height,
  col_widths = 1,
  row_heights = 1,
  panel_dir = NULL,
  dpi = 320
) {
  if (length(panel_specs) == 0) {
    return(invisible(list()))
  }

  figure_stem <- tools::file_path_sans_ext(basename(figure_filename))
  panel_dir <- panel_dir %||% panel_output_dir_for_figure(figure_filename)

  panel_outputs <- lapply(panel_specs, function(spec) {
    if (is.null(spec$plot_object)) {
      stop("panel_specs is missing plot_object.", call. = FALSE)
    }
    if (is.null(spec$panel_id)) {
      stop("panel_specs is missing panel_id.", call. = FALSE)
    }

    panel_id <- as.character(spec$panel_id)
    file_stub <- slugify_filename(spec$file_stub %||% panel_id)
    row <- as.integer(spec$row %||% 1L)
    col <- as.integer(spec$col %||% 1L)

    auto_size <- panel_size_from_layout(
      figure_width = figure_width,
      figure_height = figure_height,
      col_widths = col_widths,
      row_heights = row_heights,
      col = col,
      row = row
    )

    panel_png <- file.path(
      panel_dir,
      paste0(figure_stem, "_panel_", panel_id, "_", file_stub, ".png")
    )

    saved <- save_plot_outputs(
      plot_object = spec$plot_object,
      filename = panel_png,
      width = spec$width %||% auto_size$width,
      height = spec$height %||% auto_size$height,
      dpi = spec$dpi %||% dpi
    )

    c(saved, list(
      panel_id = panel_id,
      file_stub = file_stub,
      row = row,
      col = col
    ))
  })

  names(panel_outputs) <- vapply(panel_specs, function(spec) as.character(spec$panel_id), character(1))
  invisible(panel_outputs)
}

save_plot_outputs <- function(plot_object, filename, width = 10.8, height = 8.6, dpi = 320) {
  ggplot2::ggsave(
    filename = filename,
    plot = plot_object,
    width = width,
    height = height,
    dpi = dpi,
    units = "in",
    bg = "white"
  )
  ggplot2::ggsave(
    filename = companion_pdf_path(filename),
    plot = plot_object,
    width = width,
    height = height,
    units = "in",
    bg = "white"
  )
  svg_path <- companion_svg_path(filename)
  if (requireNamespace("svglite", quietly = TRUE)) {
    ggplot2::ggsave(
      filename = svg_path,
      plot = plot_object,
      width = width,
      height = height,
      units = "in",
      bg = "white",
      device = svglite::svglite
    )
  } else {
    ggplot2::ggsave(
      filename = svg_path,
      plot = plot_object,
      width = width,
      height = height,
      units = "in",
      bg = "white",
      device = grDevices::svg
    )
  }

  invisible(list(
    png_path = filename,
    pdf_path = companion_pdf_path(filename),
    svg_path = svg_path
  ))
}
