
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
  check_required_packages(c("ggplot2", "dplyr", "tidyr", "patchwork"))
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(patchwork)
  library(grid)
})

build_figure_03 <- function(root = find_project_root(), output_dir = NULL) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_dirs <- prepare_output_dirs(root)
  output_dir <- output_dir %||% output_dirs$figures
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  cleanup_legacy_figure5_outputs <- function(target_dir) {
    legacy_paths <- file.path(
      target_dir,
      c(
        "Figure5_discrepancy_sources.png",
        "Figure5_discrepancy_sources.pdf",
        "Figure5_discrepancy_sources.svg"
      )
    )
    invisible(unlink(legacy_paths, force = TRUE))
  }

  cleanup_legacy_figure5_outputs(output_dir)

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
  geom_vline_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_vline, ..., width = width)
  geom_segment_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_segment, ..., width = width)
  geom_smooth_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_smooth, ..., width = width)

  pt_to_geom_size <- function(pt) {
    pt / 2.845276
  }

  format_stats_label <- function(lines) {
    paste(lines, collapse = "\n")
  }

  identity_limits <- function(x, y, pad_frac = 0.08) {
    lo <- min(c(x, y), na.rm = TRUE)
    hi <- max(c(x, y), na.rm = TRUE)
    pad <- (hi - lo) * pad_frac
    c(lo - pad, hi + pad)
  }

  padded_range <- function(values, pad_frac = 0.08) {
    rng <- range(values, na.rm = TRUE)
    span <- diff(rng)
    if (!is.finite(span) || span == 0) span <- max(abs(rng[1]), 1)
    c(rng[1] - span * pad_frac, rng[2] + span * pad_frac)
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

  wrap_panel_title <- function(text, width = 120) {
    title_lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
    wrapped_lines <- vapply(
      title_lines,
      function(single_line) paste(strwrap(single_line, width = width), collapse = "\n"),
      character(1)
    )
    paste(wrapped_lines, collapse = "\n")
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
          margin = margin(b = 3)
        ),
        plot.tag = element_text(size = 14, face = "bold", color = "#111111", hjust = 0, vjust = 1),
        plot.tag.position = c(0.015, 0.985),
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        legend.position = legend_position,
        legend.title = element_blank(),
        legend.text = element_text(size = 10, color = "#222222"),
        legend.key.height = unit(4, "mm"),
        legend.key.width = unit(6, "mm"),
        legend.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(3, 4, 2, 3)
      )
  }

  build_concordance_panel <- function(
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
      scale_x_continuous(limits = lim, expand = expansion(mult = c(0, 0))) +
      scale_y_continuous(limits = lim, expand = expansion(mult = c(0, 0))) +
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

  build_histogram_panel <- function(
    values,
    panel_title,
    panel_tag,
    x_label,
    label_text,
    fill_color,
    mean_line_color,
    mean_line_width,
    zero_line_color,
    zero_line_width,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    label_text_size_pt,
    panel_border_width,
    label_box_border_width,
    label_fill,
    label_anchor
  ) {
    histogram_info <- graphics::hist(values, breaks = 10, plot = FALSE)
    x_plot_range <- padded_range(values, pad_frac = 0.05)
    y_plot_range <- c(0, max(histogram_info$counts, na.rm = TRUE) * 1.12)
    label_pos <- resolve_label_position(x_plot_range, y_plot_range, label_anchor)

    ggplot(data.frame(diff_value = values), aes(x = diff_value)) +
      geom_histogram(bins = 10, fill = fill_color, color = "white", alpha = 0.90) +
      geom_vline_compat(xintercept = mean(values, na.rm = TRUE), color = mean_line_color, width = mean_line_width) +
      geom_vline_compat(xintercept = 0, color = zero_line_color, linetype = "dashed", width = zero_line_width) +
      coord_cartesian(xlim = x_plot_range, ylim = y_plot_range, expand = FALSE) +
      labs(x = x_label, y = "Participants", title = wrap_panel_title(panel_title), tag = panel_tag) +
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

  build_delta_scatter_panel <- function(
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
    regression_line_color,
    regression_line_width,
    regression_ci_fill,
    regression_ci_alpha,
    zero_line_color,
    zero_line_width,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    label_text_size_pt,
    panel_border_width,
    label_box_border_width,
    label_fill,
    label_anchor
  ) {
    x_plot_range <- padded_range(df[[x_col]], pad_frac = 0.05)
    y_plot_range <- padded_range(df[[y_col]], pad_frac = 0.06)
    label_pos <- resolve_label_position(x_plot_range, y_plot_range, label_anchor)

    ggplot(df, aes(x = .data[[x_col]], y = .data[[y_col]])) +
      geom_hline_compat(yintercept = 0, linetype = "dashed", color = zero_line_color, width = zero_line_width) +
      geom_vline_compat(xintercept = 0, linetype = "dashed", color = zero_line_color, width = zero_line_width) +
      geom_smooth_compat(
        method = "lm",
        formula = y ~ x,
        se = TRUE,
        level = 0.95,
        color = regression_line_color,
        fill = regression_ci_fill,
        alpha = regression_ci_alpha,
        width = regression_line_width
      ) +
      geom_point(color = point_color, alpha = point_alpha, size = point_size) +
      scale_x_continuous(limits = x_plot_range, expand = expansion(mult = c(0, 0))) +
      scale_y_continuous(limits = y_plot_range, expand = expansion(mult = c(0, 0))) +
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

  build_forest_panel <- function(
    df,
    estimate_col,
    low_col,
    high_col,
    label_col,
    panel_title,
    panel_tag,
    x_label,
    point_color,
    point_size,
    segment_width,
    reference_line,
    reference_line_color,
    reference_line_width,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    panel_border_width,
    color_col = NULL,
    x_limits = NULL,
    label_text = NULL,
    label_text_size_pt = NULL,
    label_box_border_width = NULL,
    label_fill = "white"
  ) {
    plot_df <- df %>%
      mutate(label_factor = factor(.data[[label_col]], levels = rev(as.character(.data[[label_col]]))))

    x_values <- c(plot_df[[estimate_col]], plot_df[[low_col]], plot_df[[high_col]])
    if (!is.null(reference_line)) x_values <- c(x_values, reference_line)
    x_plot_range <- x_limits %||% expanded_range(range(x_values, na.rm = TRUE), mult = c(0.05, 0.08))

    if (is.null(color_col)) {
      panel_plot <- ggplot(plot_df, aes(y = label_factor)) +
        geom_segment_compat(
          aes(x = .data[[low_col]], xend = .data[[high_col]], yend = label_factor),
          color = point_color,
          width = segment_width
        ) +
        geom_point(aes(x = .data[[estimate_col]]), color = point_color, size = point_size)
    } else {
      panel_plot <- ggplot(plot_df, aes(y = label_factor)) +
        geom_segment_compat(
          aes(x = .data[[low_col]], xend = .data[[high_col]], yend = label_factor, color = .data[[color_col]]),
          width = segment_width
        ) +
        geom_point(aes(x = .data[[estimate_col]], color = .data[[color_col]]), size = point_size) +
        scale_color_identity()
    }

    panel_plot <- panel_plot +
      scale_x_continuous(expand = expansion(mult = c(0, 0))) +
      labs(x = x_label, y = NULL, title = wrap_panel_title(panel_title), tag = panel_tag) +
      coord_cartesian(xlim = x_plot_range, clip = "off") +
      build_panel_theme(panel_title_size_pt, axis_title_size_pt, axis_text_size_pt, panel_border_width)

    if (!is.null(reference_line)) {
      panel_plot <- panel_plot + geom_vline_compat(xintercept = reference_line, color = reference_line_color, linetype = "dashed", width = reference_line_width)
    }

    if (!is.null(label_text)) {
      panel_plot <- panel_plot +
        annotate(
          "label",
          x = x_plot_range[1] + 0.03 * diff(x_plot_range),
          y = length(levels(plot_df$label_factor)) + 0.42,
          hjust = 0,
          vjust = 1,
          label = label_text,
          size = pt_to_geom_size(label_text_size_pt),
          fontface = "bold",
          label.size = label_box_border_width,
          fill = label_fill,
          color = "#111111",
          label.padding = unit(0.16, "lines"),
          label.r = unit(0, "pt")
        )
    }

    panel_plot
  }

  build_sensitivity_panel <- function(
    df_long,
    df_wide,
    panel_title,
    panel_tag,
    fill_values,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    panel_border_width
  ) {
    metric_order <- c("CCC", "AUC")
    variant_order <- intersect(c("Mean", "Oneplus", "Redmi"), unique(as.character(df_long$AI_variant)))
    variant_labels <- c(Mean = "AI-UFD", Oneplus = "OnePlus", Redmi = "Redmi")

    plot_df <- df_long %>%
      mutate(
        AI_variant = factor(AI_variant, levels = variant_order),
        metric = factor(metric, levels = metric_order)
      )

    label_df <- df_wide %>%
      mutate(
        AI_variant = factor(AI_variant, levels = variant_order),
        y_pos = pmax(CCC_Qmax, AUC) + 0.05
      )

    ggplot(plot_df, aes(x = AI_variant, y = value, fill = metric)) +
      geom_col(position = position_dodge(width = 0.70), width = 0.60) +
      geom_text(
        data = label_df,
        aes(x = AI_variant, y = y_pos, label = paste0("n=", n)),
        inherit.aes = FALSE,
        size = pt_to_geom_size(10),
        fontface = "bold",
        color = "#111111"
      ) +
      scale_fill_manual(values = fill_values, breaks = metric_order) +
      scale_x_discrete(labels = variant_labels[variant_order]) +
      scale_y_continuous(limits = c(0, 1.08), expand = expansion(mult = c(0, 0))) +
      labs(x = NULL, y = "Performance", title = wrap_panel_title(panel_title), tag = panel_tag) +
      build_panel_theme(
        panel_title_size_pt = panel_title_size_pt,
        axis_title_size_pt = axis_title_size_pt,
        axis_text_size_pt = axis_text_size_pt,
        panel_border_width = panel_border_width,
        legend_position = "top"
      ) +
      theme(
        legend.justification = "left",
        legend.margin = margin(0, 0, 0, 0)
      )
  }

  clinical_point_color <- "#1F5AA6"
  vv_point_color <- "#1B8A6B"
  tqmax_point_color <- "#E18727FF"
  qave_point_color <- "#7876B1FF"
  flowtime_point_color <- "#B09C85FF"
  voidtime_point_color <- "#EE4C97FF"
  sensitivity_auc_color <- "#7DB7A4"
  reference_line_color <- "#B7B6B6"
  accent_line_color <- "#C00000"

  panel_point_size <- 2.0
  panel_point_alpha <- 0.82
  panel_title_size_pt <- 14
  panel_axis_title_size_pt <- 12
  panel_axis_text_size_pt <- 12
  panel_label_text_size_pt <- 10
  panel_border_width <- 1.0
  panel_label_box_border_width <- 0.6
  panel_label_fill <- "white"

  concordance_label_anchor <- c(0.96, 0.08)
  bland_label_anchor <- c(0.96, 0.12)
  histogram_label_anchor <- c(0.96, 0.94)
  delta_label_anchor <- c(0.96, 0.92)

  clinical_path <- file.path(root, "data", "raw", "Clinical_Raw_Data.xlsx")
  results_path <- file.path(root, "data", "derived", "Clinical_Analysis_RawFirst.xlsx")
  part_a_path <- file.path(root, "tables", "Part_A_Correlation_and_paired_tests.csv")

  clinical <- read_excel_safe(clinical_path)
  names(clinical) <- trim_ws_names(names(clinical))
  clinical <- clinical %>%
    mutate(
      AI_Mean_Qmax = (Oneplus_Qmax + Redmi_Qmax) / 2,
      AI_Mean_Qave = (Oneplus_Qave + Redmi_Qave) / 2,
      AI_Mean_Tqmax = (Oneplus_Tqmax + Redmi_Tqmax) / 2,
      AI_Mean_FlowTime = (Oneplus_FlowTime + Redmi_FlowTime) / 2,
      AI_Mean_VV = (Oneplus_VV + Redmi_VV) / 2,
      AI_Mean_VoidTime = (Oneplus_VoidTime + Redmi_VoidTime) / 2,
      dQmax = AI_Mean_Qmax - STD_Qmax,
      dVV = AI_Mean_VV - STD_VV
    )

  comparison_sheet <- read_excel_safe(results_path, sheet = "B_layer_STD_vs_AI")
  paired_sheet <- read_excel_safe(results_path, sheet = "Paired_tests")
  gee_sheet <- read_excel_safe(results_path, sheet = "GEE_Qmax_adjustVV")
  sensitivity_sheet <- read_excel_safe(results_path, sheet = "Sensitivity_VV150_Qmax")
  part_a_table <- utils::read.csv(part_a_path, check.names = FALSE)

  q_mean <- comparison_sheet %>% filter(Parameter == "Qmax", AI_variant == "Mean") %>% slice(1)
  vv_mean <- comparison_sheet %>% filter(Parameter == "VV", AI_variant == "Mean") %>% slice(1)
  paired_q_mean <- paired_sheet %>% filter(Parameter == "Qmax", AI_variant == "Mean") %>% slice(1)

  mean_all <- comparison_sheet %>%
    filter(AI_variant == "Mean", Parameter %in% c("Qmax", "Tqmax", "Qave", "FlowTime", "VV", "VoidTime")) %>%
    mutate(
      Parameter = factor(Parameter, levels = rev(c("Qmax", "Tqmax", "Qave", "FlowTime", "VV", "VoidTime"))),
      color_hex = c(
        Qmax = clinical_point_color,
        Tqmax = tqmax_point_color,
        Qave = qave_point_color,
        FlowTime = flowtime_point_color,
        VV = vv_point_color,
        VoidTime = voidtime_point_color
      )[as.character(Parameter)]
    )

  panel_d_reference_line <- 0.5
  panel_d_x_limits <- c(
    floor(min(mean_all$CCC_low, na.rm = TRUE) / 0.05) * 0.05 - 0.01,
    ceiling(max(c(mean_all$CCC_high, panel_d_reference_line), na.rm = TRUE) / 0.05) * 0.05 + 0.02
  )

  slope_fit <- stats::lm(dQmax ~ dVV, data = clinical)
  slope_coef <- stats::coef(slope_fit)[["dVV"]]
  corr_val <- stats::cor(clinical$dVV, clinical$dQmax, use = "complete.obs")
  part_a_p_value <- part_a_table$Result[part_a_table$Statistic == "P value"][1]

  gee_mean <- gee_sheet %>%
    filter(variant == "Mean", term != "Intercept") %>%
    mutate(
      estimate = if_else(term == "VV", estimate * 100, estimate),
      ci_low = if_else(term == "VV", ci_low * 100, ci_low),
      ci_high = if_else(term == "VV", ci_high * 100, ci_high),
      term_label = c("Method", "VV (per 100 mL)")
    )

  sensitivity_long <- sensitivity_sheet %>%
    transmute(
      AI_variant,
      CCC = CCC_Qmax,
      AUC = AUC,
      n = n
    ) %>%
    pivot_longer(cols = c(CCC, AUC), names_to = "metric", values_to = "value")

  panel_a <- build_concordance_panel(
    df = clinical,
    x_col = "STD_Qmax",
    y_col = "AI_Mean_Qmax",
    x_label = "SG-UFD Qmax (mL/s)",
    y_label = "AI-UFD Qmax (mL/s)",
    panel_title = "Clinical concordance (Qmax)",
    panel_tag = "A",
    label_text = format_stats_label(c(
      paste0("CCC = ", fmt_ccc(q_mean$CCC)),
      paste0("95% CI: ", fmt_ci(q_mean$CCC_low), " to ", fmt_ci(q_mean$CCC_high)),
      paste0("Median APE = ", fmt_percent(q_mean$APE_median))
    )),
    point_color = clinical_point_color,
    point_size = panel_point_size,
    point_alpha = panel_point_alpha,
    identity_line_color = reference_line_color,
    identity_line_width = 1.0,
    regression_line_color = accent_line_color,
    regression_line_width = 1.0,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    label_text_size_pt = panel_label_text_size_pt,
    panel_border_width = panel_border_width,
    label_box_border_width = panel_label_box_border_width,
    label_fill = panel_label_fill,
    label_anchor = concordance_label_anchor
  )

  panel_b <- build_bland_altman_panel(
    x = clinical$STD_Qmax,
    y = clinical$AI_Mean_Qmax,
    bias = q_mean$Bias,
    loa_low = q_mean$LoA_low,
    loa_high = q_mean$LoA_high,
    x_label = "Mean of two measurements (mL/s)",
    y_label = "AI-UFD - SG-UFD (mL/s)",
    panel_title = "Clinical Bland-Altman (Qmax)",
    panel_tag = "B",
    label_text = format_stats_label(c(
      paste0("bias = ", fmt_bias(q_mean$Bias)),
      paste0("95% LoA: ", fmt_loa(q_mean$LoA_low, q_mean$LoA_high))
    )),
    point_color = clinical_point_color,
    point_size = panel_point_size,
    point_alpha = panel_point_alpha,
    bias_line_color = accent_line_color,
    bias_line_width = 1.0,
    loa_line_color = reference_line_color,
    loa_line_width = 1.0,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    label_text_size_pt = panel_label_text_size_pt,
    panel_border_width = panel_border_width,
    label_box_border_width = panel_label_box_border_width,
    label_fill = panel_label_fill,
    label_anchor = bland_label_anchor
  )

  panel_c <- build_histogram_panel(
    values = clinical$AI_Mean_Qmax - clinical$STD_Qmax,
    panel_title = "Paired Qmax difference hist.",
    panel_tag = "C",
    x_label = "AI-UFD - SG-UFD Qmax (mL/s)",
    label_text = format_stats_label(c(
      sprintf("Paired t-test P = %s", fmt_number(paired_q_mean$t_p, digits = 3)),
      sprintf("Wilcoxon P = %s", fmt_number(paired_q_mean$wilcoxon_p, digits = 3))
    )),
    fill_color = clinical_point_color,
    mean_line_color = accent_line_color,
    mean_line_width = 1.0,
    zero_line_color = reference_line_color,
    zero_line_width = 1.0,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    label_text_size_pt = panel_label_text_size_pt,
    panel_border_width = panel_border_width,
    label_box_border_width = panel_label_box_border_width,
    label_fill = panel_label_fill,
    label_anchor = histogram_label_anchor
  ) +
    theme(
      axis.title.x = element_text(margin = margin(t = 2)),
      axis.title.y = element_text(margin = margin(r = 2)),
      plot.margin = margin(4, 4, 2, 4)
    )

  panel_d <- build_forest_panel(
    df = mean_all,
    estimate_col = "CCC",
    low_col = "CCC_low",
    high_col = "CCC_high",
    label_col = "Parameter",
    panel_title = "Parameter-wise concordance",
    panel_tag = "D",
    x_label = "Lin's CCC",
    point_color = clinical_point_color,
    point_size = panel_point_size,
    segment_width = 1.0,
    reference_line = panel_d_reference_line,
    reference_line_color = reference_line_color,
    reference_line_width = 1.0,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    panel_border_width = panel_border_width,
    color_col = "color_hex",
    x_limits = panel_d_x_limits
  )

  panel_e <- build_delta_scatter_panel(
    df = clinical,
    x_col = "dVV",
    y_col = "dQmax",
    x_label = expression(Delta * "VV (AI-UFD - SG-UFD, mL)"),
    y_label = expression(Delta * "Qmax (AI-UFD - SG-UFD, mL/s)"),
    panel_title = "VV-Qmax discrepancy association",
    panel_tag = "E",
    label_text = format_stats_label(c(
      paste0("r = ", fmt_number(corr_val, digits = 3)),
      paste0("P = ", part_a_p_value),
      paste0("Slope = ", fmt_number(slope_coef * 100, digits = 2), " mL/s per 100 mL")
    )),
    point_color = clinical_point_color,
    point_size = panel_point_size,
    point_alpha = panel_point_alpha,
    regression_line_color = accent_line_color,
    regression_line_width = 1.0,
    regression_ci_fill = accent_line_color,
    regression_ci_alpha = 0.16,
    zero_line_color = reference_line_color,
    zero_line_width = 1.0,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    label_text_size_pt = panel_label_text_size_pt,
    panel_border_width = panel_border_width,
    label_box_border_width = panel_label_box_border_width,
    label_fill = panel_label_fill,
    label_anchor = delta_label_anchor
  ) +
    theme(
      axis.title.x = element_text(margin = margin(t = 2)),
      axis.title.y = element_text(margin = margin(r = 2)),
      plot.margin = margin(4, 4, 2, 4)
    )

  panel_f <- build_bland_altman_panel(
    x = clinical$STD_VV,
    y = clinical$AI_Mean_VV,
    bias = vv_mean$Bias,
    loa_low = vv_mean$LoA_low,
    loa_high = vv_mean$LoA_high,
    x_label = "Mean of two measurements (mL)",
    y_label = "AI-UFD - SG-UFD (mL)",
    panel_title = "Clinical Bland-Altman (VV)",
    panel_tag = "F",
    label_text = format_stats_label(c(
      paste0("bias = ", fmt_bias(vv_mean$Bias, "mL")),
      paste0("95% LoA: ", fmt_loa(vv_mean$LoA_low, vv_mean$LoA_high, "mL"))
    )),
    point_color = vv_point_color,
    point_size = panel_point_size,
    point_alpha = panel_point_alpha,
    bias_line_color = accent_line_color,
    bias_line_width = 1.0,
    loa_line_color = reference_line_color,
    loa_line_width = 1.0,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    label_text_size_pt = panel_label_text_size_pt,
    panel_border_width = panel_border_width,
    label_box_border_width = panel_label_box_border_width,
    label_fill = panel_label_fill,
    label_anchor = bland_label_anchor
  )

  panel_g <- build_forest_panel(
    df = gee_mean,
    estimate_col = "estimate",
    low_col = "ci_low",
    high_col = "ci_high",
    label_col = "term_label",
    panel_title = "GEE model adjusted for VV",
    panel_tag = "G",
    x_label = "Regression coefficient (beta)",
    point_color = clinical_point_color,
    point_size = panel_point_size,
    segment_width = 1.0,
    reference_line = 0,
    reference_line_color = reference_line_color,
    reference_line_width = 1.0,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    panel_border_width = panel_border_width,
    label_text = format_stats_label(c(
      paste0("Method effect = ", fmt_beta(gee_mean$estimate[gee_mean$term == "method[T.SG-UFD]"])),
      paste0("VV effect = ", fmt_beta(gee_mean$estimate[gee_mean$term == "VV"]), " per 100 mL")
    )),
    label_text_size_pt = panel_label_text_size_pt,
    label_box_border_width = panel_label_box_border_width,
    label_fill = panel_label_fill
  ) +
    theme(
      axis.text.y = element_text(size = 10.8, angle = 90, hjust = 0.5, vjust = 0.5, lineheight = 0.90, color = "#333333"),
      plot.margin = margin(3, 4, 2, 2)
    )

  panel_h <- build_sensitivity_panel(
    df_long = sensitivity_long,
    df_wide = sensitivity_sheet,
    panel_title = "Sensitivity analysis (VV >= 150 mL)",
    panel_tag = "H",
    fill_values = c(CCC = vv_point_color, AUC = sensitivity_auc_color),
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    panel_border_width = panel_border_width
  )

  output_png <- file.path(output_dir, "Figure3_clinical_concordance.png")
  figure_width_in <- 8.27
  figure_height_in <- 10.90

  top_row <- panel_a + panel_b + plot_layout(widths = c(1, 1))
  second_row <- panel_c + panel_d + plot_layout(widths = c(1, 1))
  third_row <- panel_e + panel_f + plot_layout(widths = c(1, 1))
  fourth_row <- panel_g + panel_h + plot_layout(widths = c(1, 1))

  figure_plot <- wrap_elements(full = top_row) /
    wrap_elements(full = second_row) /
    wrap_elements(full = third_row) /
    wrap_elements(full = fourth_row) +
    plot_layout(heights = c(1.00, 0.78, 1.00, 0.92))

  main_outputs <- save_plot_outputs(
    plot_object = figure_plot,
    filename = output_png,
    width = figure_width_in,
    height = figure_height_in,
    dpi = 320
  )

  panel_outputs <- save_panel_plot_outputs(
    panel_specs = list(
      list(plot_object = panel_a, panel_id = "A", file_stub = "qmax_clinical_concordance", row = 1, col = 1, width = figure_width_in / 2, height = 4.0),
      list(plot_object = panel_b, panel_id = "B", file_stub = "qmax_clinical_bland_altman", row = 1, col = 2, width = figure_width_in / 2, height = 4.0),
      list(plot_object = panel_c, panel_id = "C", file_stub = "paired_qmax_difference_hist", row = 2, col = 1, width = figure_width_in / 2, height = 3.4),
      list(plot_object = panel_d, panel_id = "D", file_stub = "parameter_wise_concordance", row = 2, col = 2, width = figure_width_in / 2, height = 3.4),
      list(plot_object = panel_e, panel_id = "E", file_stub = "vv_qmax_discrepancy_association", row = 3, col = 1, width = figure_width_in / 2, height = 4.0),
      list(plot_object = panel_f, panel_id = "F", file_stub = "vv_clinical_bland_altman", row = 3, col = 2, width = figure_width_in / 2, height = 4.0),
      list(plot_object = panel_g, panel_id = "G", file_stub = "gee_model_adjusted_for_vv", row = 4, col = 1, width = figure_width_in / 2, height = 3.6),
      list(plot_object = panel_h, panel_id = "H", file_stub = "sensitivity_analysis_vv_150", row = 4, col = 2, width = figure_width_in / 2, height = 3.6)
    ),
    figure_filename = output_png,
    figure_width = figure_width_in,
    figure_height = figure_height_in,
    col_widths = c(1, 1),
    row_heights = c(1.00, 0.78, 1.00, 0.92),
    dpi = 320
  )

  invisible(c(main_outputs, list(panel_outputs = panel_outputs)))
}

if (identical(environment(), globalenv()) && !interactive()) {
  build_figure_03()
}
