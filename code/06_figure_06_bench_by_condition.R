
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
  check_required_packages(c("ggplot2", "dplyr", "cowplot"))
  library(ggplot2)
  library(dplyr)
  library(cowplot)
  library(grid)
})

build_figure_06 <- function(root = find_project_root(), output_dir = NULL) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_dirs <- prepare_output_dirs(root)
  output_dir <- output_dir %||% output_dirs$figures
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  cleanup_legacy_bench_figure7_outputs <- function(target_dir, panel_root) {
    legacy_paths <- file.path(
      target_dir,
      c(
        "Figure7_bench_by_condition.png",
        "Figure7_bench_by_condition.pdf",
        "Figure7_bench_by_condition.svg"
      )
    )
    invisible(unlink(legacy_paths, force = TRUE))
    invisible(unlink(file.path(panel_root, "Figure7_bench_by_condition"), recursive = TRUE, force = TRUE))
  }

  cleanup_legacy_bench_figure7_outputs(output_dir, output_dirs$figure_panels)

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

  geom_tile_compat <- function(..., border_width = NULL) {
    args <- list(...)
    if (!is.null(border_width)) args[[ggplot_linewidth_aes]] <- border_width
    do.call(ggplot2::geom_tile, args)
  }

  geom_line_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_line, ..., width = width)

  pt_to_geom_size <- function(pt) {
    pt / 2.845276
  }

  expanded_range <- function(x, mult = c(0, 0)) {
    span <- diff(x)
    if (!is.finite(span) || span == 0) span <- max(abs(x[1]), 1)
    c(x[1] - span * mult[1], x[2] + span * mult[2])
  }

  resolve_label_position <- function(x_range, y_range, label_anchor) {
    list(
      x = x_range[1] + label_anchor[1] * diff(x_range),
      y = y_range[1] + label_anchor[2] * diff(y_range),
      hjust = if (label_anchor[1] >= 0.5) 1 else 0,
      vjust = if (label_anchor[2] >= 0.5) 1 else 0
    )
  }

  wrap_panel_title <- function(text, width = 32) {
    paste(strwrap(text, width = width), collapse = "\n")
  }

  build_panel_theme <- function(
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    panel_border_width,
    legend_position = "none"
  ) {
    theme_classic(base_size = axis_title_size_pt, base_family = "sans") +
      theme(
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = compat_element_rect(color = "black", fill = NA, width = panel_border_width),
        axis.line = element_blank(),
        axis.ticks = compat_element_line(color = "#222222", width = 0.40),
        axis.ticks.length = unit(1.8, "mm"),
        axis.title.x = element_text(size = axis_title_size_pt, face = "bold", color = "#111111", margin = margin(t = 2.4)),
        axis.title.y = element_text(size = axis_title_size_pt, face = "bold", color = "#111111", margin = margin(r = 2.4)),
        axis.text = element_text(size = axis_text_size_pt, color = "#222222"),
        plot.title = element_text(
          size = panel_title_size_pt,
          face = "bold",
          color = "#111111",
          hjust = 0.5,
          lineheight = 0.95,
          margin = margin(b = 4)
        ),
        plot.tag = element_text(size = 14, face = "bold", color = "#111111", hjust = 0, vjust = 1),
        plot.tag.position = c(0.015, 0.985),
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        legend.position = legend_position,
        legend.title = element_blank(),
        legend.text = element_text(size = 10, color = "#222222"),
        legend.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(1.5, 1.2, 1.2, 1.2)
      )
  }

  tighten_plot_grob <- function(grob, outer_margin_pt = 2.5, guide_gap_pt = 3.5) {
    panel_idx <- grob$layout$l[grob$layout$name == "panel"][1]
    if (is.na(panel_idx)) return(grob)

    grob$widths[1] <- unit(outer_margin_pt, "pt")
    grob$widths[length(grob$widths)] <- unit(outer_margin_pt, "pt")

    if ((panel_idx + 3) <= length(grob$widths)) {
      grob$widths[panel_idx + 3] <- unit(guide_gap_pt, "pt")
    }

    grob
  }

  build_heatmap_panel <- function(
    df,
    panel_title,
    panel_tag,
    fill_scale,
    label_formatter = function(x) sprintf("%.2f", x),
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    panel_border_width
  ) {
    df <- df %>%
      mutate(panel_label = label_formatter(value))

    ggplot(df, aes(x = Device, y = Condition_Type, fill = value)) +
      geom_tile_compat(color = "white", border_width = 0.9) +
      geom_text(
        aes(label = panel_label),
        fontface = "bold",
        color = "#111111",
        size = pt_to_geom_size(10)
      ) +
      labs(
        x = NULL,
        y = NULL,
        title = wrap_panel_title(panel_title),
        tag = panel_tag
      ) +
      fill_scale +
      build_panel_theme(
        panel_title_size_pt = panel_title_size_pt,
        axis_title_size_pt = axis_title_size_pt,
        axis_text_size_pt = axis_text_size_pt,
        panel_border_width = panel_border_width,
        legend_position = "right"
      ) +
      theme(
        axis.ticks = element_blank(),
        legend.key.height = unit(14, "mm"),
        legend.key.width = unit(2.6, "mm"),
        legend.margin = margin(0, 0, 0, 0),
        legend.box.margin = margin(0, 0, 0, 0),
        legend.box.spacing = unit(0.3, "mm"),
        plot.margin = margin(1.5, 0.4, 1.2, 1.0)
      )
  }

  build_waveform_panel <- function(
    truth_df,
    ai_df,
    run_row,
    panel_title,
    panel_tag,
    label_anchor,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    panel_border_width
  ) {
    plot_df <- bind_rows(truth_df, ai_df)

    x_range <- range(plot_df$t_s, na.rm = TRUE)
    y_range <- range(plot_df$value, na.rm = TRUE)
    x_axis_limit <- c(0, max(plot_df$t_s, na.rm = TRUE) * 1.02)
    x_breaks <- pretty(c(0, max(plot_df$t_s, na.rm = TRUE)), n = 4)
    x_plot_range <- x_axis_limit
    y_plot_range <- expanded_range(y_range, mult = c(0.08, 0.10))
    label_pos <- resolve_label_position(x_plot_range, y_plot_range, label_anchor)

    label_text <- paste(
      sprintf("Run identifier: %s", run_row$Run_ID),
      sprintf("Truth Qmax: %.2f mL/s", run_row$Truth_Qmax_ml_s),
      sprintf("Truth VV: %.1f mL", run_row$Truth_VV_ml),
      sep = "\n"
    )

    ggplot(plot_df, aes(x = t_s, y = value, color = series, linetype = series)) +
      geom_line_compat(width = 1.1) +
      scale_color_manual(
        values = c(Truth = "#4D4D4D", OnePlus = "#1F5AA6", Redmi = "#C00000"),
        name = NULL,
        breaks = c("Truth", "OnePlus", "Redmi")
      ) +
      scale_linetype_manual(
        values = c(Truth = "solid", OnePlus = "dashed", Redmi = "dotdash"),
        name = NULL,
        breaks = c("Truth", "OnePlus", "Redmi")
      ) +
      scale_x_continuous(
        limits = x_axis_limit,
        breaks = x_breaks,
        expand = expansion(mult = c(0, 0.01))
      ) +
      scale_y_continuous(expand = expansion(mult = c(0.08, 0.10))) +
      labs(
        x = "Time (s)",
        y = "Flow rate (mL/s)",
        title = wrap_panel_title(panel_title),
        tag = panel_tag
      ) +
      annotate(
        "label",
        x = label_pos$x,
        y = label_pos$y,
        hjust = label_pos$hjust,
        vjust = label_pos$vjust,
        label = label_text,
        size = pt_to_geom_size(10),
        fontface = "bold",
        label.size = 0.6,
        fill = "white",
        color = "#111111",
        label.padding = unit(0.16, "lines"),
        label.r = unit(0, "pt")
      ) +
      build_panel_theme(
        panel_title_size_pt = panel_title_size_pt,
        axis_title_size_pt = axis_title_size_pt,
        axis_text_size_pt = axis_text_size_pt,
        panel_border_width = panel_border_width,
        legend_position = "right"
      ) +
      guides(
        color = guide_legend(
          ncol = 1,
          byrow = TRUE,
          override.aes = list(
            linetype = c("solid", "dashed", "dotdash")
          )
        ),
        linetype = "none"
      ) +
      theme(
        axis.title.y = element_text(size = axis_title_size_pt, face = "bold", color = "#111111", margin = margin(r = 0.8)),
        legend.justification = "center",
        legend.direction = "vertical",
        legend.key.width = unit(5.2, "mm"),
        legend.key.height = unit(3.0, "mm"),
        legend.spacing.y = unit(0.3, "mm"),
        legend.margin = margin(0, 0, 0, 0),
        legend.box.margin = margin(0, 0, 0, 0),
        legend.box.spacing = unit(0.3, "mm"),
        plot.margin = margin(1.5, 0.4, 1.2, 1.0)
      )
  }

  harmonize_plot_grobs <- function(plot_list) {
    grobs <- lapply(plot_list, function(plot_object) tighten_plot_grob(ggplotGrob(plot_object)))
    shared_widths <- Reduce(grid::unit.pmax, lapply(grobs, function(g) g$widths))
    shared_heights <- Reduce(grid::unit.pmax, lapply(grobs, function(g) g$heights))

    lapply(grobs, function(g) {
      g$widths <- shared_widths
      g$heights <- shared_heights
      g
    })
  }

  bench_condition_path <- file.path(root, "data", "raw", "Bench_Summary_By_Condition.csv")
  bench_record_path <- file.path(root, "data", "raw", "Peristaltic_Pump_Bench_Record_Revised.xlsx")

  bench_by_condition <- utils::read.csv(bench_condition_path, check.names = FALSE, stringsAsFactors = FALSE)
  bench_runs <- read_excel_safe(bench_record_path, sheet = "Runs")
  wave_truth <- read_excel_safe(bench_record_path, sheet = "Waveform_Truth")
  wave_ai <- read_excel_safe(bench_record_path, sheet = "Waveform_AI")

  names(bench_runs) <- trim_ws_names(names(bench_runs))
  names(wave_truth) <- trim_ws_names(names(wave_truth))
  names(wave_ai) <- trim_ws_names(names(wave_ai))

  condition_levels <- c("Constant", "Bell", "Trapezoid", "Custom")
  condition_display_levels <- rev(condition_levels)
  device_levels <- c("OnePlus", "Redmi", "Mean")

  bench_by_condition <- bench_by_condition %>%
    mutate(
      Condition_Type = factor(Condition_Type, levels = condition_display_levels),
      Device = factor(Device, levels = device_levels)
    )

  q_bias <- bench_by_condition %>%
    filter(Metric == "Qmax") %>%
    transmute(Condition_Type, Device, value = Bias)
  q_mape <- bench_by_condition %>%
    filter(Metric == "Qmax") %>%
    transmute(Condition_Type, Device, value = MAPE * 100)
  v_bias <- bench_by_condition %>%
    filter(Metric == "VV") %>%
    transmute(Condition_Type, Device, value = Bias)
  v_mape <- bench_by_condition %>%
    filter(Metric == "VV") %>%
    transmute(Condition_Type, Device, value = MAPE * 100)

  q_bias_range <- range(q_bias$value, na.rm = TRUE)
  v_bias_range <- range(v_bias$value, na.rm = TRUE)
  q_mape_range <- range(q_mape$value, na.rm = TRUE)
  v_mape_range <- range(v_mape$value, na.rm = TRUE)
  q_bias_mid <- mean(q_bias_range)
  v_bias_mid <- mean(v_bias_range)
  q_mape_mid <- mean(q_mape_range)
  v_mape_mid <- mean(v_mape_range)

  q_bias_breaks <- c(q_bias_range[1], q_bias_mid, q_bias_range[2])
  v_bias_breaks <- c(v_bias_range[1], v_bias_mid, v_bias_range[2])
  q_mape_breaks <- c(q_mape_range[1], q_mape_mid, q_mape_range[2])
  v_mape_breaks <- c(v_mape_range[1], v_mape_mid, v_mape_range[2])

  panel_title_size_pt <- 14
  axis_title_size_pt <- 12
  axis_text_size_pt <- 12
  panel_border_width <- 1.0

  panel_a <- build_heatmap_panel(
    df = q_bias,
    panel_title = "Qmax bias",
    panel_tag = "A",
    fill_scale = scale_fill_gradient2(
      low = "#C00000",
      mid = "white",
      high = "#1F5AA6",
      midpoint = q_bias_mid,
      limits = q_bias_range,
      breaks = q_bias_breaks,
      labels = sprintf("%.2f", q_bias_breaks),
      guide = guide_colorbar(
        frame.colour = "black",
        ticks.colour = "#333333",
        barheight = unit(18, "mm"),
        barwidth = unit(3.6, "mm")
      )
    ),
    label_formatter = function(x) sprintf("%.2f", x),
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = axis_title_size_pt,
    axis_text_size_pt = axis_text_size_pt,
    panel_border_width = panel_border_width
  )

  panel_b <- build_heatmap_panel(
    df = q_mape,
    panel_title = "Qmax error",
    panel_tag = "B",
    fill_scale = scale_fill_gradient2(
      low = "#C00000",
      mid = "white",
      high = "#1F5AA6",
      midpoint = q_mape_mid,
      limits = q_mape_range,
      breaks = q_mape_breaks,
      labels = sprintf("%.1f%%", q_mape_breaks),
      guide = guide_colorbar(
        frame.colour = "black",
        ticks.colour = "#333333",
        barheight = unit(18, "mm"),
        barwidth = unit(3.6, "mm")
      )
    ),
    label_formatter = function(x) sprintf("%.1f%%", x),
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = axis_title_size_pt,
    axis_text_size_pt = axis_text_size_pt,
    panel_border_width = panel_border_width
  )

  panel_c <- build_heatmap_panel(
    df = v_bias,
    panel_title = "VV bias",
    panel_tag = "C",
    fill_scale = scale_fill_gradient2(
      low = "#E18727",
      mid = "white",
      high = "#1B8A6B",
      midpoint = v_bias_mid,
      limits = v_bias_range,
      breaks = v_bias_breaks,
      labels = sprintf("%.2f", v_bias_breaks),
      guide = guide_colorbar(
        frame.colour = "black",
        ticks.colour = "#333333",
        barheight = unit(18, "mm"),
        barwidth = unit(3.6, "mm")
      )
    ),
    label_formatter = function(x) fmt_bias_value(x),
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = axis_title_size_pt,
    axis_text_size_pt = axis_text_size_pt,
    panel_border_width = panel_border_width
  )

  panel_d <- build_heatmap_panel(
    df = v_mape,
    panel_title = "VV error",
    panel_tag = "D",
    fill_scale = scale_fill_gradient2(
      low = "#E18727",
      mid = "white",
      high = "#1B8A6B",
      midpoint = v_mape_mid,
      limits = v_mape_range,
      breaks = v_mape_breaks,
      labels = sprintf("%.1f%%", v_mape_breaks),
      guide = guide_colorbar(
        frame.colour = "black",
        ticks.colour = "#333333",
        barheight = unit(18, "mm"),
        barwidth = unit(3.6, "mm")
      )
    ),
    label_formatter = function(x) sprintf("%.1f%%", x),
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = axis_title_size_pt,
    axis_text_size_pt = axis_text_size_pt,
    panel_border_width = panel_border_width
  )

  pick_ids <- c("PP001", "PP016", "PP031", "PP046")
  waveform_titles <- c("Constant waveform", "Bell waveform", "Trapezoid waveform", "Custom waveform")
  waveform_tags <- c("E", "F", "G", "H")
  waveform_label_anchors <- list(
    c(0.04, 0.14),
    c(0.04, 0.14),
    c(0.04, 0.14),
    c(0.04, 0.14)
  )

  waveform_panels <- lapply(seq_along(pick_ids), function(i) {
    run_id <- pick_ids[i]
    run_row <- bench_runs %>% filter(Run_ID == run_id) %>% slice(1)

    truth_df <- wave_truth %>%
      filter(Run_ID == run_id) %>%
      transmute(t_s = t_s, value = Truth_Q_ml_s, series = "Truth")

    ai_df <- wave_ai %>%
      filter(Run_ID == run_id) %>%
      transmute(t_s = t_s, value = AI_Q_ml_s, series = Device)

    build_waveform_panel(
      truth_df = truth_df,
      ai_df = ai_df,
      run_row = run_row,
      panel_title = waveform_titles[[i]],
      panel_tag = waveform_tags[[i]],
      label_anchor = waveform_label_anchors[[i]],
      panel_title_size_pt = panel_title_size_pt,
      axis_title_size_pt = axis_title_size_pt,
      axis_text_size_pt = axis_text_size_pt,
      panel_border_width = panel_border_width
    )
  })

  panel_e <- waveform_panels[[1]]
  panel_f <- waveform_panels[[2]]
  panel_g <- waveform_panels[[3]]
  panel_h <- waveform_panels[[4]]

  left_column_grobs <- harmonize_plot_grobs(list(panel_a, panel_c, panel_e, panel_g))
  right_column_grobs <- harmonize_plot_grobs(list(panel_b, panel_d, panel_f, panel_h))

  row_1 <- cowplot::plot_grid(left_column_grobs[[1]], right_column_grobs[[1]], ncol = 2, rel_widths = c(1, 1))
  row_2 <- cowplot::plot_grid(left_column_grobs[[2]], right_column_grobs[[2]], ncol = 2, rel_widths = c(1, 1))
  row_3 <- cowplot::plot_grid(left_column_grobs[[3]], right_column_grobs[[3]], ncol = 2, rel_widths = c(1, 1))
  row_4 <- cowplot::plot_grid(left_column_grobs[[4]], right_column_grobs[[4]], ncol = 2, rel_widths = c(1, 1))

  output_png <- file.path(output_dir, "Figure6_bench_by_condition.png")
  figure_width_in <- 8.27
  figure_height_in <- 10.00

  figure_plot <- cowplot::plot_grid(
    row_1,
    row_2,
    row_3,
    row_4,
    ncol = 1,
    rel_heights = c(1, 1, 1, 1)
  )

  main_outputs <- save_plot_outputs(
    plot_object = figure_plot,
    filename = output_png,
    width = figure_width_in,
    height = figure_height_in,
    dpi = 320
  )

  panel_outputs <- save_panel_plot_outputs(
    panel_specs = list(
      list(plot_object = panel_a, panel_id = "A", file_stub = "qmax_bias_heatmap", row = 1, col = 1),
      list(plot_object = panel_b, panel_id = "B", file_stub = "qmax_relative_error_heatmap", row = 1, col = 2),
      list(plot_object = panel_c, panel_id = "C", file_stub = "vv_bias_heatmap", row = 2, col = 1),
      list(plot_object = panel_d, panel_id = "D", file_stub = "vv_relative_error_heatmap", row = 2, col = 2),
      list(plot_object = panel_e, panel_id = "E", file_stub = "constant_waveform", row = 3, col = 1),
      list(plot_object = panel_f, panel_id = "F", file_stub = "bell_waveform", row = 3, col = 2),
      list(plot_object = panel_g, panel_id = "G", file_stub = "trapezoid_waveform", row = 4, col = 1),
      list(plot_object = panel_h, panel_id = "H", file_stub = "custom_waveform", row = 4, col = 2)
    ),
    figure_filename = output_png,
    figure_width = figure_width_in,
    figure_height = figure_height_in,
    col_widths = c(1, 1),
    row_heights = c(1, 1, 1, 1),
    dpi = 320
  )

  invisible(c(main_outputs, list(panel_outputs = panel_outputs)))
}

if (identical(environment(), globalenv()) && !interactive()) {
  build_figure_06()
}
