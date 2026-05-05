
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
  check_required_packages(c("ggplot2", "dplyr", "patchwork"))
  library(ggplot2)
  library(dplyr)
  library(patchwork)
  library(grid)
})

build_figure_s4 <- function(root = find_project_root(), output_dir = NULL) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_dirs <- prepare_output_dirs(root)
  output_dir <- output_dir %||% output_dirs$figures
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  ggplot_linewidth_aes <- if (utils::packageVersion("ggplot2") >= "3.4.0") "linewidth" else "size"

  compat_geom <- function(fun, ..., width = NULL) {
    args <- list(...)
    if (!is.null(width)) args[[ggplot_linewidth_aes]] <- width
    do.call(fun, args)
  }

  compat_element_line <- function(..., width = NULL) {
    args <- list(...)
    if (!is.null(width)) args[[ggplot_linewidth_aes]] <- width
    do.call(ggplot2::element_line, args)
  }

  compat_element_rect <- function(..., width = NULL) {
    args <- list(...)
    if (!is.null(width)) args[[ggplot_linewidth_aes]] <- width
    do.call(ggplot2::element_rect, args)
  }

  geom_abline_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_abline, ..., width = width)
  geom_hline_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_hline, ..., width = width)
  geom_smooth_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_smooth, ..., width = width)

  pt_to_geom_size <- function(pt) pt / 2.845276
  format_stats_label <- function(lines) paste(lines, collapse = "\n")

  identity_limits <- function(x, y, pad_frac = 0.08) {
    lo <- min(c(x, y), na.rm = TRUE)
    hi <- max(c(x, y), na.rm = TRUE)
    pad <- (hi - lo) * pad_frac
    c(lo - pad, hi + pad)
  }

  resolve_label_position <- function(x_range, y_range, label_anchor) {
    list(
      x = x_range[1] + label_anchor[1] * diff(x_range),
      y = y_range[1] + label_anchor[2] * diff(y_range),
      hjust = if (label_anchor[1] >= 0.5) 1 else 0,
      vjust = if (label_anchor[2] >= 0.5) 1 else 0
    )
  }

  expanded_range <- function(x, mult = c(0, 0)) {
    span <- diff(x)
    c(x[1] - span * mult[1], x[2] + span * mult[2])
  }

  wrap_panel_title <- function(text, width = 28) {
    paste(strwrap(text, width = width), collapse = "\n")
  }

  build_panel_theme <- function(panel_title_size_pt, axis_title_size_pt, axis_text_size_pt, panel_border_width) {
    theme_classic(base_size = axis_title_size_pt, base_family = "sans") +
      theme(
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = compat_element_rect(color = "black", fill = NA, width = panel_border_width),
        axis.line = element_blank(),
        axis.ticks = compat_element_line(color = "#222222", width = 0.40),
        axis.ticks.length = unit(2.2, "mm"),
        axis.title = element_text(size = axis_title_size_pt, face = "bold", color = "#111111"),
        axis.text = element_text(size = axis_text_size_pt, color = "#222222"),
        plot.title = element_text(
          size = panel_title_size_pt,
          face = "bold",
          color = "#111111",
          hjust = 0.5,
          lineheight = 0.95,
          margin = margin(b = 6)
        ),
        plot.tag = element_text(size = 14, face = "bold", color = "#111111", hjust = 0, vjust = 1),
        plot.tag.position = c(0.015, 0.985),
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        legend.position = "none",
        aspect.ratio = 1,
        plot.margin = margin(7, 7, 7, 7)
      )
  }

  build_scatter_panel <- function(
    df,
    x_col,
    y_col,
    x_label,
    y_label,
    panel_title,
    panel_tag,
    label_text,
    point_color,
    point_size,
    point_alpha,
    identity_line_color,
    identity_line_width,
    regression_line_color,
    regression_line_width,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    label_text_size_pt,
    panel_border_width,
    label_box_border_width,
    label_fill,
    label_anchor
  ) {
    lim <- identity_limits(df[[x_col]], df[[y_col]])
    label_pos <- resolve_label_position(lim, lim, label_anchor)

    ggplot(df, aes(x = .data[[x_col]], y = .data[[y_col]])) +
      geom_point(color = point_color, alpha = point_alpha, size = point_size) +
      geom_abline_compat(intercept = 0, slope = 1, linetype = "dashed", color = identity_line_color, width = identity_line_width) +
      geom_smooth_compat(method = "lm", formula = y ~ x, se = FALSE, color = regression_line_color, width = regression_line_width) +
      coord_equal(xlim = lim, ylim = lim, expand = FALSE) +
      labs(x = x_label, y = y_label, title = wrap_panel_title(panel_title), tag = panel_tag) +
      annotate(
        "label",
        x = label_pos$x,
        y = label_pos$y,
        hjust = label_pos$hjust,
        vjust = label_pos$vjust,
        label = label_text,
        size = pt_to_geom_size(label_text_size_pt),
        fontface = "bold",
        label.size = label_box_border_width,
        fill = label_fill,
        color = "#111111",
        label.padding = unit(0.16, "lines"),
        label.r = unit(0, "pt")
      ) +
      build_panel_theme(panel_title_size_pt, axis_title_size_pt, axis_text_size_pt, panel_border_width)
  }

  build_bland_altman_panel <- function(
    x,
    y,
    bias,
    loa_low,
    loa_high,
    x_label,
    y_label,
    panel_title,
    panel_tag,
    label_text,
    point_color,
    point_size,
    point_alpha,
    bias_line_color,
    bias_line_width,
    loa_line_color,
    loa_line_width,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    label_text_size_pt,
    panel_border_width,
    label_box_border_width,
    label_fill,
    label_anchor
  ) {
    bland_altman_df <- data.frame(mean_xy = (x + y) / 2, diff_yx = y - x)

    x_range <- range(bland_altman_df$mean_xy, na.rm = TRUE)
    y_range <- range(c(bland_altman_df$diff_yx, bias, loa_low, loa_high), na.rm = TRUE)
    x_plot_range <- expanded_range(x_range, mult = c(0.05, 0.05))
    y_plot_range <- expanded_range(y_range, mult = c(0.14, 0.08))
    label_pos <- resolve_label_position(x_plot_range, y_plot_range, label_anchor)

    ggplot(bland_altman_df, aes(x = mean_xy, y = diff_yx)) +
      geom_point(color = point_color, alpha = point_alpha, size = point_size) +
      geom_hline_compat(yintercept = bias, color = bias_line_color, width = bias_line_width) +
      geom_hline_compat(yintercept = c(loa_low, loa_high), color = loa_line_color, linetype = "dashed", width = loa_line_width) +
      scale_x_continuous(expand = expansion(mult = c(0.05, 0.05))) +
      scale_y_continuous(expand = expansion(mult = c(0.14, 0.08))) +
      labs(x = x_label, y = y_label, title = wrap_panel_title(panel_title), tag = panel_tag) +
      annotate(
        "label",
        x = label_pos$x,
        y = label_pos$y,
        hjust = label_pos$hjust,
        vjust = label_pos$vjust,
        label = label_text,
        size = pt_to_geom_size(label_text_size_pt),
        fontface = "bold",
        label.size = label_box_border_width,
        fill = label_fill,
        color = "#111111",
        label.padding = unit(0.16, "lines"),
        label.r = unit(0, "pt")
      ) +
      build_panel_theme(panel_title_size_pt, axis_title_size_pt, axis_text_size_pt, panel_border_width)
  }

  bench_summary_path <- file.path(root, "data", "raw", "Bench_Summary_Overall.csv")
  bench_record_path <- file.path(root, "data", "raw", "Peristaltic_Pump_Bench_Record_Revised.xlsx")

  bench_summary <- utils::read.csv(bench_summary_path, check.names = FALSE, stringsAsFactors = FALSE)
  bench_runs <- read_excel_safe(bench_record_path, sheet = "Runs")
  names(bench_runs) <- trim_ws_names(names(bench_runs))

  metric_specs <- list(
    list(
      parameter = "Qmax",
      summary_metric = "Qmax",
      y_col = "AI_Redmi_Qmax",
      truth_col = "Truth_Qmax_ml_s",
      unit = "mL/s",
      point_color = "#1F5AA6",
      scatter_tag = "A",
      bland_tag = "B",
      scatter_stub = "redmi_qmax_concordance",
      bland_stub = "redmi_qmax_bland_altman",
      y_label = "Redmi Qmax (mL/s)",
      bland_y_label = "Redmi - truth (mL/s)"
    ),
    list(
      parameter = "VV",
      summary_metric = "VV",
      y_col = "AI_Redmi_VV",
      truth_col = "Truth_VV_ml",
      unit = "mL",
      point_color = "#1B8A6B",
      scatter_tag = "C",
      bland_tag = "D",
      scatter_stub = "redmi_vv_concordance",
      bland_stub = "redmi_vv_bland_altman",
      y_label = "Redmi VV (mL)",
      bland_y_label = "Redmi - truth (mL)"
    )
  )

  panel_point_size <- 2.0
  panel_point_alpha <- 0.82
  panel_identity_line_color <- "#b7b6b6"
  panel_identity_line_width <- 1.0
  panel_regression_line_color <- "#c00000"
  panel_regression_line_width <- 1.0
  panel_bias_line_color <- "#c00000"
  panel_bias_line_width <- 1.0
  panel_loa_line_color <- "#b7b6b6"
  panel_loa_line_width <- 1.0
  panel_title_size_pt <- 14
  panel_axis_title_size_pt <- 12
  panel_axis_text_size_pt <- 12
  panel_label_text_size_pt <- 10
  panel_border_width <- 1.0
  panel_label_box_border_width <- 0.6
  panel_label_fill <- "white"
  scatter_label_anchor <- c(0.96, 0.08)
  bland_label_anchor <- c(0.96, 0.12)

  metric_panels <- lapply(metric_specs, function(spec) {
    stats_row <- bench_summary %>% filter(Metric == spec$summary_metric, Device == "Redmi") %>% slice(1)

    scatter_panel <- build_scatter_panel(
      df = bench_runs,
      x_col = spec$truth_col,
      y_col = spec$y_col,
      x_label = sprintf("Truth %s (%s)", spec$parameter, spec$unit),
      y_label = spec$y_label,
      panel_title = sprintf("Redmi bench concordance (%s)", spec$parameter),
      panel_tag = spec$scatter_tag,
      label_text = format_stats_label(c(
        paste0("CCC = ", fmt_bench_ccc(stats_row$CCC)),
        paste0("95% CI: ", fmt_bench_ci(stats_row$CCC_L), " to ", fmt_bench_ci(stats_row$CCC_U)),
        paste0("MAE = ", fmt_mae(stats_row$MAE), " ", spec$unit)
      )),
      point_color = spec$point_color,
      point_size = panel_point_size,
      point_alpha = panel_point_alpha,
      identity_line_color = panel_identity_line_color,
      identity_line_width = panel_identity_line_width,
      regression_line_color = panel_regression_line_color,
      regression_line_width = panel_regression_line_width,
      panel_title_size_pt = panel_title_size_pt,
      axis_title_size_pt = panel_axis_title_size_pt,
      axis_text_size_pt = panel_axis_text_size_pt,
      label_text_size_pt = panel_label_text_size_pt,
      panel_border_width = panel_border_width,
      label_box_border_width = panel_label_box_border_width,
      label_fill = panel_label_fill,
      label_anchor = scatter_label_anchor
    )

    bland_panel <- build_bland_altman_panel(
      x = bench_runs[[spec$truth_col]],
      y = bench_runs[[spec$y_col]],
      bias = stats_row$Bias,
      loa_low = stats_row$LoA_Low,
      loa_high = stats_row$LoA_High,
      x_label = sprintf("Mean of two measurements (%s)", spec$unit),
      y_label = spec$bland_y_label,
      panel_title = sprintf("Redmi bench Bland-Altman (%s)", spec$parameter),
      panel_tag = spec$bland_tag,
      label_text = if (identical(spec$parameter, "Qmax")) {
        format_stats_label(c(
          paste0("bias = ", fmt_bias(stats_row$Bias)),
          paste0("95% LoA: ", fmt_loa(stats_row$LoA_Low, stats_row$LoA_High))
        ))
      } else {
        format_stats_label(c(
          paste0("bias = ", fmt_bias(stats_row$Bias, spec$unit)),
          paste0("95% LoA: ", fmt_loa(stats_row$LoA_Low, stats_row$LoA_High, spec$unit))
        ))
      },
      point_color = spec$point_color,
      point_size = panel_point_size,
      point_alpha = panel_point_alpha,
      bias_line_color = panel_bias_line_color,
      bias_line_width = panel_bias_line_width,
      loa_line_color = panel_loa_line_color,
      loa_line_width = panel_loa_line_width,
      panel_title_size_pt = panel_title_size_pt,
      axis_title_size_pt = panel_axis_title_size_pt,
      axis_text_size_pt = panel_axis_text_size_pt,
      label_text_size_pt = panel_label_text_size_pt,
      panel_border_width = panel_border_width,
      label_box_border_width = panel_label_box_border_width,
      label_fill = panel_label_fill,
      label_anchor = bland_label_anchor
    )

    list(scatter = scatter_panel, bland = bland_panel)
  })

  ordered_panels <- unlist(lapply(metric_panels, function(panel_pair) list(panel_pair$scatter, panel_pair$bland)), recursive = FALSE)

  output_png <- file.path(output_dir, "FigureS4_bench_redmi_qmax_vv.png")
  figure_width_in <- 8.27
  figure_height_in <- 8.20

  figure_plot <- patchwork::wrap_plots(ordered_panels, ncol = 2, byrow = TRUE) +
    plot_layout(ncol = 2, widths = c(1, 1), heights = c(1, 1))

  main_outputs <- save_plot_outputs(
    plot_object = figure_plot,
    filename = output_png,
    width = figure_width_in,
    height = figure_height_in,
    dpi = 320
  )

  panel_outputs <- save_panel_plot_outputs(
    panel_specs = list(
      list(plot_object = metric_panels[[1]]$scatter, panel_id = "A", file_stub = metric_specs[[1]]$scatter_stub, row = 1, col = 1),
      list(plot_object = metric_panels[[1]]$bland, panel_id = "B", file_stub = metric_specs[[1]]$bland_stub, row = 1, col = 2),
      list(plot_object = metric_panels[[2]]$scatter, panel_id = "C", file_stub = metric_specs[[2]]$scatter_stub, row = 2, col = 1),
      list(plot_object = metric_panels[[2]]$bland, panel_id = "D", file_stub = metric_specs[[2]]$bland_stub, row = 2, col = 2)
    ),
    figure_filename = output_png,
    figure_width = figure_width_in,
    figure_height = figure_height_in,
    col_widths = c(1, 1),
    row_heights = c(1, 1),
    dpi = 320
  )

  invisible(c(main_outputs, list(panel_outputs = panel_outputs)))
}

if (identical(environment(), globalenv()) && !interactive()) {
  build_figure_s4()
}
