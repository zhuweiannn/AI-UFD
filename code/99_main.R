
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

suppressPackageStartupMessages({
  source(file.path(dirname(script_path_local), "00_common.R"), local = TRUE)
  check_required_packages(c("ggplot2", "patchwork", "png"))
  library(patchwork)
  library(grid)
})

load_script_function <- function(code_dir, script_name, function_name) {
  script_env <- new.env(parent = globalenv())
  sys.source(file.path(code_dir, script_name), envir = script_env)
  script_env[[function_name]]
}

build_contact_sheet <- function(figure_png_paths, output_png) {
  figure_panels <- lapply(figure_png_paths, function(png_path) {
    image_array <- png::readPNG(png_path)
    image_grob <- grid::rasterGrob(image_array, interpolate = TRUE)
    patchwork::wrap_elements(full = image_grob) +
      plot_annotation(title = tools::file_path_sans_ext(basename(png_path)))
  })

  contact_plot <- patchwork::wrap_plots(figure_panels, ncol = 2) +
    plot_annotation(title = "AI-UFD Figures Contact Sheet")

  save_plot_outputs(
    plot_object = contact_plot,
    filename = output_png,
    width = 14,
    height = 18,
    dpi = 220
  )
}

relative_to_root <- function(paths, root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")

  vapply(paths, function(path) {
    path <- normalizePath(path, winslash = "/", mustWork = FALSE)
    if (startsWith(path, prefix)) substring(path, nchar(prefix) + 1L) else basename(path)
  }, character(1))
}

required_figure_inputs <- function(root) {
  file.path(root, c(
    "data/raw/Clinical_Raw_Data.xlsx",
    "data/raw/Bench_Summary_Overall.csv",
    "data/raw/Bench_Summary_By_Condition.csv",
    "data/raw/Peristaltic_Pump_Bench_Record_Revised.xlsx",
    "data/derived/Clinical_Analysis_RawFirst.xlsx",
    "tables/Part_A_Correlation_and_paired_tests.csv"
  ))
}

check_figure_inputs <- function(root) {
  required <- required_figure_inputs(root)
  missing <- required[!file.exists(required)]
  if (length(missing) > 0) {
    stop(
      "Missing private figure-generation inputs:\n",
      paste(missing, collapse = "\n"),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

run_all_outputs <- function(root = find_project_root()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  code_dir <- file.path(root, "code_r")
  output_dirs <- prepare_output_dirs(root)

  message("Project root: ", root)
  message("Step 1/3: checking private figure-generation inputs...")
  check_figure_inputs(root)

  message("Step 2/3: building Figure 2-6 and FigureS1-S4...")
  figure_specs <- list(
    list(script = "12_figure_02_cross_platform.R", fun = "build_figure_02"),
    list(script = "13_figure_03_clinical_concordance.R", fun = "build_figure_03"),
    list(script = "14_figure_04_low_flow_screening.R", fun = "build_figure_04"),
    list(script = "15_figure_05_bench_overall.R", fun = "build_figure_05"),
    list(script = "16_figure_06_bench_by_condition.R", fun = "build_figure_06"),
    list(script = "19_figure_s1_cross_platform_tqmax_qave.R", fun = "build_figure_s1"),
    list(script = "20_figure_s2_cross_platform_flowtime_voidtime.R", fun = "build_figure_s2"),
    list(script = "21_figure_s3_bench_oneplus_qmax_vv.R", fun = "build_figure_s3"),
    list(script = "22_figure_s4_bench_redmi_qmax_vv.R", fun = "build_figure_s4")
  )

  figure_results <- lapply(figure_specs, function(spec) {
    message("  - ", spec$script)
    build_fun <- load_script_function(code_dir, spec$script, spec$fun)
    build_fun(root = root)
  })

  figure_png_paths <- vapply(figure_results, function(result) result$png_path, character(1))
  figure_pdf_paths <- vapply(figure_results, function(result) result$pdf_path, character(1))
  figure_svg_paths <- vapply(figure_results, function(result) result$svg_path, character(1))
  panel_exported_paths <- unlist(lapply(figure_results, function(result) {
    if (is.null(result$panel_outputs) || length(result$panel_outputs) == 0) {
      return(character(0))
    }
    unlist(lapply(result$panel_outputs, function(panel_result) {
      c(panel_result$png_path, panel_result$pdf_path, panel_result$svg_path)
    }), use.names = FALSE)
  }), use.names = FALSE)

  message("Step 3/3: building contact sheet and manifest...")
  contact_png <- file.path(output_dirs$figures, "Figures_Contact_Sheet.png")
  build_contact_sheet(figure_png_paths, contact_png)

  exported_paths <- c(figure_png_paths, figure_pdf_paths, figure_svg_paths, panel_exported_paths)
  contact_paths <- c(contact_png, companion_pdf_path(contact_png), companion_svg_path(contact_png))
  manifest_paths <- c(exported_paths, contact_paths)

  manifest <- data.frame(
    file_name = basename(manifest_paths),
    relative_path = relative_to_root(manifest_paths, root),
    stringsAsFactors = FALSE
  )
  utils::write.csv(manifest, file.path(output_dirs$figures, "Figure_Manifest_R.csv"), row.names = FALSE)

  message("All outputs completed successfully.")
  message("Outputs are under: ", file.path(root, "r_outputs"))

  invisible(list(
    figure_png_paths = figure_png_paths,
    figure_pdf_paths = figure_pdf_paths,
    figure_svg_paths = figure_svg_paths,
    panel_export_paths = panel_exported_paths,
    contact_sheet_png = contact_png,
    contact_sheet_pdf = companion_pdf_path(contact_png),
    contact_sheet_svg = companion_svg_path(contact_png),
    manifest = manifest
  ))
}

if (identical(environment(), globalenv()) && !interactive()) {
  run_all_outputs()
}
