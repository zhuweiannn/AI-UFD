
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
  check_required_packages(c("ggplot2", "dplyr", "tidyr", "patchwork", "cowplot"))
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(patchwork)
  library(cowplot)
  library(grid)
})

build_figure_04 <- function(root = find_project_root(), output_dir = NULL) {
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

  geom_line_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_line, ..., width = width)
  geom_abline_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_abline, ..., width = width)
  geom_hline_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_hline, ..., width = width)
  geom_vline_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_vline, ..., width = width)
  geom_segment_compat <- function(..., width = NULL) compat_geom(ggplot2::geom_segment, ..., width = width)

  geom_tile_compat <- function(..., border_width = NULL) {
    args <- list(...)
    if (!is.null(border_width)) args[[ggplot_linewidth_aes]] <- border_width
    do.call(ggplot2::geom_tile, args)
  }

  pt_to_geom_size <- function(pt) {
    pt / 2.845276
  }

  format_stats_label <- function(lines) {
    paste(lines, collapse = "\n")
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

  wrap_panel_title <- function(text, width = 38) {
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
        legend.key.width = unit(7, "mm"),
        legend.background = element_rect(fill = "white", color = NA),
        plot.margin = margin(3, 4, 2, 3)
      )
  }

  roc_curve_manual <- function(truth, score) {
    truth <- as.integer(truth)
    score <- as.numeric(score)
    thresholds <- sort(unique(score), decreasing = TRUE)

    curve_points <- lapply(thresholds, function(th) {
      predicted_positive <- as.integer(score >= th)
      tp <- sum(predicted_positive == 1 & truth == 1, na.rm = TRUE)
      fp <- sum(predicted_positive == 1 & truth == 0, na.rm = TRUE)
      tn <- sum(predicted_positive == 0 & truth == 0, na.rm = TRUE)
      fn <- sum(predicted_positive == 0 & truth == 1, na.rm = TRUE)

      sensitivity <- if ((tp + fn) == 0) NA_real_ else tp / (tp + fn)
      specificity <- if ((tn + fp) == 0) NA_real_ else tn / (tn + fp)

      data.frame(threshold = th, tpr = sensitivity, fpr = 1 - specificity)
    })

    curve <- dplyr::bind_rows(curve_points)
    curve <- dplyr::distinct(curve, fpr, tpr, .keep_all = TRUE)
    curve <- dplyr::bind_rows(
      data.frame(threshold = Inf, tpr = 0, fpr = 0),
      curve,
      data.frame(threshold = -Inf, tpr = 1, fpr = 1)
    )
    curve[order(curve$fpr, curve$tpr), , drop = FALSE]
  }

  build_full_roc_fill_df <- function(roc_curve_df) {
    roc_curve_df %>%
      arrange(series, fpr, tpr) %>%
      transmute(
        fpr = fpr,
        tpr = tpr,
        series = series
      )
  }

  calc_threshold_metrics <- function(truth, qmax_values, thresholds) {
    bind_rows(lapply(thresholds, function(thr) {
      predicted_positive <- as.integer(qmax_values < thr)
      tp <- sum(predicted_positive == 1 & truth == 1, na.rm = TRUE)
      fp <- sum(predicted_positive == 1 & truth == 0, na.rm = TRUE)
      tn <- sum(predicted_positive == 0 & truth == 0, na.rm = TRUE)
      fn <- sum(predicted_positive == 0 & truth == 1, na.rm = TRUE)

      data.frame(
        Threshold = thr,
        Sensitivity = if ((tp + fn) == 0) NA_real_ else tp / (tp + fn),
        Specificity = if ((tn + fp) == 0) NA_real_ else tn / (tn + fp)
      )
    }))
  }

  build_confusion_panel <- function(
    tn,
    fp,
    fn,
    tp,
    panel_title,
    panel_tag,
    fill_high_color,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    panel_border_width
  ) {
    total_n <- tn + fp + fn + tp

    cm_df <- data.frame(
      prediction = factor(c("Low flow", "Low flow", "Not low flow", "Not low flow"), levels = c("Low flow", "Not low flow")),
      truth = factor(c("Low flow", "Not low flow", "Low flow", "Not low flow"), levels = c("Low flow", "Not low flow")),
      cell = c("TP", "FP", "FN", "TN"),
      n = c(tp, fp, fn, tn)
    ) %>%
      mutate(
        label = sprintf("%s\n%d\n(%.1f%%)", cell, n, 100 * n / total_n),
        text_color = ifelse(n >= stats::median(n), "white", "#111111")
      )

    ggplot(cm_df, aes(x = truth, y = prediction, fill = n)) +
      geom_tile_compat(color = "white", border_width = 0.9) +
      geom_text(
        aes(label = label, color = text_color),
        lineheight = 0.95,
        fontface = "bold",
        size = pt_to_geom_size(10.8),
        show.legend = FALSE
      ) +
      scale_fill_gradient(low = "#F8FBFF", high = fill_high_color) +
      scale_color_identity() +
      coord_equal(expand = FALSE) +
      labs(
        x = "Reference (SG-UFD)",
        y = "Prediction (AI-UFD)",
        title = wrap_panel_title(panel_title),
        tag = panel_tag
      ) +
      build_panel_theme(
        panel_title_size_pt = panel_title_size_pt,
        axis_title_size_pt = axis_title_size_pt,
        axis_text_size_pt = axis_text_size_pt,
        panel_border_width = panel_border_width
      ) +
      theme(
        axis.ticks = element_blank(),
        axis.title.y = element_text(margin = margin(r = 0.8)),
        axis.text.y = element_text(angle = 90, hjust = 0.5, vjust = 0.5),
        legend.position = "none",
        plot.margin = margin(4, 5, 3, 1.5)
      )
  }

  build_threshold_scan_panel <- function(
    perf_long,
    threshold_perf_df,
    fixed_threshold,
    youden_threshold,
    panel_title,
    panel_tag,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    panel_border_width,
    sensitivity_color,
    specificity_color,
    fixed_threshold_color,
    youden_threshold_color
  ) {
    endpoint_row <- threshold_perf_df %>%
      filter(Threshold == max(Threshold)) %>%
      slice(1)

    label_df <- data.frame(
      Threshold = c(28.7, 28.7),
      value = c(min(endpoint_row$Sensitivity, 0.96), max(endpoint_row$Specificity, 0.07)),
      label = c("Sensitivity", "Specificity"),
      text_color = c(sensitivity_color, specificity_color),
      stringsAsFactors = FALSE
    )

    ggplot(perf_long, aes(x = Threshold, y = value, color = metric)) +
      geom_area(
        aes(fill = metric, group = metric),
        alpha = 0.10,
        position = "identity",
        color = NA
      ) +
      geom_line_compat(width = 1.0) +
      geom_vline_compat(xintercept = fixed_threshold, linetype = "dashed", color = fixed_threshold_color, width = 1.0) +
      geom_vline_compat(xintercept = youden_threshold, linetype = "dashed", color = youden_threshold_color, width = 1.0) +
      geom_text(
        data = label_df,
        aes(label = label, color = NULL),
        x = label_df$Threshold,
        y = label_df$value,
        label = label_df$label,
        color = label_df$text_color,
        fontface = "bold",
        hjust = 1,
        size = pt_to_geom_size(10)
      ) +
      annotate(
        "text",
        x = fixed_threshold,
        y = 0.08,
        label = "15 mL/s",
        color = fixed_threshold_color,
        size = pt_to_geom_size(10),
        fontface = "bold",
        vjust = 0
      ) +
      annotate(
        "text",
        x = youden_threshold,
        y = 0.18,
        label = paste0("Youden = ", fmt_threshold(youden_threshold)),
        color = youden_threshold_color,
        size = pt_to_geom_size(10),
        fontface = "bold",
        vjust = 0
      ) +
      scale_color_manual(values = c(Sensitivity = sensitivity_color, Specificity = specificity_color)) +
      scale_fill_manual(values = c(Sensitivity = sensitivity_color, Specificity = specificity_color), guide = "none") +
      scale_x_continuous(limits = c(5, 30), breaks = c(5, 10, 15, 20, 25, 30), expand = expansion(mult = c(0, 0))) +
      scale_y_continuous(limits = c(0, 1.02), breaks = c(0, 0.25, 0.50, 0.75, 1.00), expand = expansion(mult = c(0, 0))) +
      labs(
        x = "Qmax threshold (mL/s)",
        y = "Metric value",
        title = wrap_panel_title(panel_title),
        tag = panel_tag
      ) +
      build_panel_theme(
        panel_title_size_pt = panel_title_size_pt,
        axis_title_size_pt = axis_title_size_pt,
        axis_text_size_pt = axis_text_size_pt,
        panel_border_width = panel_border_width
      ) +
      theme(
        legend.position = "none",
        aspect.ratio = 1
      )
  }

  build_metric_bar_panel <- function(
    metric_df,
    panel_title,
    panel_tag,
    threshold_15_color,
    youden_color,
    panel_title_size_pt,
    axis_title_size_pt,
    axis_text_size_pt,
    panel_border_width
  ) {
    metric_label_formatter <- function(metric, value) {
      if (identical(as.character(metric), "Kappa")) {
        return(fmt_kappa(value))
      }
      fmt_percent(value * 100)
    }

    plot_df <- bind_rows(
      data.frame(metric = metric_df$metric, threshold = "15 mL/s", value = metric_df$threshold_15, stringsAsFactors = FALSE),
      data.frame(metric = metric_df$metric, threshold = "Youden", value = metric_df$youden, stringsAsFactors = FALSE)
    ) %>%
      mutate(
        metric = factor(metric, levels = metric_df$metric),
        threshold = factor(threshold, levels = c("15 mL/s", "Youden")),
        label = mapply(metric_label_formatter, metric, value)
      )

    ggplot(plot_df, aes(x = metric, y = value, fill = threshold)) +
      geom_col(position = position_dodge(width = 0.68), width = 0.60) +
      geom_text(
        aes(label = label),
        position = position_dodge(width = 0.68),
        vjust = -0.34,
        size = pt_to_geom_size(9.8),
        fontface = "bold",
        color = "#111111"
      ) +
      scale_x_discrete(expand = expansion(add = c(0.35, 0.35))) +
      scale_fill_manual(values = c("15 mL/s" = threshold_15_color, "Youden" = youden_color)) +
      scale_y_continuous(
        limits = c(0, 1.08),
        breaks = c(0, 0.20, 0.40, 0.60, 0.80, 1.00),
        expand = expansion(mult = c(0, 0.02))
      ) +
      labs(
        x = NULL,
        y = "Metric value",
        title = wrap_panel_title(panel_title),
        tag = panel_tag
      ) +
      coord_cartesian(clip = "off") +
      build_panel_theme(
        panel_title_size_pt = panel_title_size_pt,
        axis_title_size_pt = axis_title_size_pt,
        axis_text_size_pt = axis_text_size_pt,
        panel_border_width = panel_border_width,
        legend_position = c(0.02, 0.985)
      ) +
      theme(
        legend.justification = c(0, 1),
        legend.direction = "horizontal",
        legend.key.width = unit(5.2, "mm"),
        legend.key.height = unit(3.6, "mm"),
        legend.text = element_text(size = 9.5, color = "#222222"),
        legend.margin = margin(0, 0, 0, 0),
        legend.box.margin = margin(0, 0, 0, 0),
        axis.text.x = element_text(size = axis_text_size_pt, color = "#222222"),
        plot.margin = margin(1.5, 5, 1.5, 5)
      )
  }


  oneplus_color <- "#1F5AA6"
  redmi_color <- "#C00000"
  mean_color <- "#1B8A6B"
  sensitivity_color <- "#C00000"
  specificity_color <- "#E18727FF"
  reference_line_color <- "#B7B6B6"
  threshold_15_line_color <- "#1F5AA6"
  youden_line_color <- "#1B8A6B"

  panel_point_size <- 2.0
  panel_point_alpha <- 0.82
  panel_title_size_pt <- 14
  panel_axis_title_size_pt <- 12
  panel_axis_text_size_pt <- 12
  panel_label_text_size_pt <- 10
  panel_border_width <- 1.0
  panel_label_box_border_width <- 0.6
  panel_label_fill <- "white"


  clinical_path <- file.path(root, "data", "raw", "Clinical_Raw_Data.xlsx")
  results_path <- file.path(root, "data", "derived", "Clinical_Analysis_RawFirst.xlsx")

  clinical <- read_excel_safe(clinical_path)
  names(clinical) <- trim_ws_names(names(clinical))
  clinical <- clinical %>%
    mutate(
      AI_Mean_Qmax = (Oneplus_Qmax + Redmi_Qmax) / 2,
      low_flow = as.integer(STD_Qmax < 15)
    )

  roc_sheet <- read_excel_safe(results_path, sheet = "ROC_STD15")

  roc_specs <- list(
    list(column = "Oneplus_Qmax", label = "OnePlus", key = "Oneplus", color = oneplus_color),
    list(column = "Redmi_Qmax", label = "Redmi", key = "Redmi", color = redmi_color),
    list(column = "AI_Mean_Qmax", label = "AI-UFD", key = "Mean", color = mean_color)
  )

  roc_series_meta <- bind_rows(lapply(seq_along(roc_specs), function(i) {
    spec <- roc_specs[[i]]
    roc_row <- roc_sheet %>% filter(AI_variant == spec$key) %>% slice(1)

    data.frame(
      series = sprintf("%s (AUC = %s)", spec$label, fmt_auc(roc_row$AUC)),
      plot_color = spec$color,
      auc = roc_row$AUC,
      series_order = i,
      stringsAsFactors = FALSE
    )
  }))

  roc_curve_df <- bind_rows(lapply(roc_specs, function(spec) {
    roc_curve <- roc_curve_manual(clinical$low_flow, -clinical[[spec$column]])
    roc_row <- roc_sheet %>% filter(AI_variant == spec$key) %>% slice(1)

    mutate(
      roc_curve,
      series = sprintf("%s (AUC = %s)", spec$label, fmt_auc(roc_row$AUC)),
      plot_color = spec$color
    )
  }))

  roc_color_values <- setNames(roc_series_meta$plot_color, roc_series_meta$series)
  roc_fill_df <- build_full_roc_fill_df(roc_curve_df)

  roc_mean <- roc_sheet %>% filter(AI_variant == "Mean") %>% slice(1)

  thresholds <- seq(5, 30, by = 0.5)
  threshold_perf_df <- calc_threshold_metrics(
    truth = clinical$low_flow,
    qmax_values = clinical$AI_Mean_Qmax,
    thresholds = thresholds
  )

  threshold_long <- threshold_perf_df %>%
    pivot_longer(
      cols = c(Sensitivity, Specificity),
      names_to = "metric",
      values_to = "value"
    ) %>%
    mutate(metric = factor(metric, levels = c("Sensitivity", "Specificity")))

  metric_df <- data.frame(
    metric = c("Sensitivity", "Specificity", "PPV", "NPV", "Accuracy", "Kappa"),
    threshold_15 = c(
      roc_mean$t15_Sensitivity,
      roc_mean$t15_Specificity,
      roc_mean$t15_PPV,
      roc_mean$t15_NPV,
      roc_mean$t15_Accuracy,
      roc_mean$t15_Kappa
    ),
    youden = c(
      roc_mean$youden_Sensitivity,
      roc_mean$youden_Specificity,
      roc_mean$youden_PPV,
      roc_mean$youden_NPV,
      roc_mean$youden_Accuracy,
      roc_mean$youden_Kappa
    )
  )


  panel_a_label_text <- format_stats_label(c(
    "Positive:",
    "SG-UFD Qmax < 15 mL/s"
  ))

  panel_a <- ggplot(roc_curve_df, aes(x = fpr, y = tpr, color = series)) +
    geom_ribbon(
      data = roc_fill_df,
      aes(x = fpr, ymin = 0, ymax = tpr, fill = series, group = series),
      inherit.aes = FALSE,
      alpha = 0.06,
      color = NA
    ) +
    geom_line_compat(width = 1.0) +
    geom_abline_compat(intercept = 0, slope = 1, linetype = "dashed", color = reference_line_color, width = 1.0) +
    scale_fill_manual(values = roc_color_values, guide = "none") +
    scale_color_manual(values = roc_color_values) +
    scale_x_continuous(limits = c(0, 1), breaks = c(0, 0.25, 0.50, 0.75, 1.00), expand = expansion(mult = c(0, 0))) +
    scale_y_continuous(limits = c(0, 1.02), breaks = c(0, 0.25, 0.50, 0.75, 1.00), expand = expansion(mult = c(0, 0))) +
    coord_equal() +
    labs(
      title = "ROC curves for low flow",
      tag = "A",
      x = "1 - Specificity",
      y = "Sensitivity"
    ) +
    annotate(
      "label",
      x = 0.05,
      y = 0.14,
      hjust = 0,
      vjust = 0,
      label = panel_a_label_text,
      size = pt_to_geom_size(panel_label_text_size_pt),
      fontface = "bold",
      label.size = panel_label_box_border_width,
      fill = panel_label_fill,
      color = "#111111",
      label.padding = unit(0.16, "lines"),
      label.r = unit(0, "pt")
    ) +
    build_panel_theme(
      panel_title_size_pt = panel_title_size_pt,
      axis_title_size_pt = panel_axis_title_size_pt,
      axis_text_size_pt = panel_axis_text_size_pt,
      panel_border_width = panel_border_width,
      legend_position = c(0.98, 0.04)
    ) +
    theme(
      legend.justification = c(1, 0),
      legend.direction = "vertical"
    )


  panel_b <- build_threshold_scan_panel(
    perf_long = threshold_long,
    threshold_perf_df = threshold_perf_df,
    fixed_threshold = 15,
    youden_threshold = roc_mean$Youden_thr_AI,
    panel_title = "Sensitivity and specificity across thresholds",
    panel_tag = "B",
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    panel_border_width = panel_border_width,
    sensitivity_color = sensitivity_color,
    specificity_color = specificity_color,
    fixed_threshold_color = threshold_15_line_color,
    youden_threshold_color = youden_line_color
  )


  panel_c <- build_confusion_panel(
    tn = roc_mean$t15_TN,
    fp = roc_mean$t15_FP,
    fn = roc_mean$t15_FN,
    tp = roc_mean$t15_TP,
    panel_title = "Confusion matrix (15 mL/s)",
    panel_tag = "C",
    fill_high_color = oneplus_color,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    panel_border_width = panel_border_width
  )

  panel_d <- build_confusion_panel(
    tn = roc_mean$youden_TN,
    fp = roc_mean$youden_FP,
    fn = roc_mean$youden_FN,
    tp = roc_mean$youden_TP,
    panel_title = "Confusion matrix (Youden)",
    panel_tag = "D",
    fill_high_color = mean_color,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    panel_border_width = panel_border_width
  )


  panel_e <- build_metric_bar_panel(
    metric_df = metric_df,
    panel_title = "Diagnostic performance summary",
    panel_tag = "E",
    threshold_15_color = oneplus_color,
    youden_color = mean_color,
    panel_title_size_pt = panel_title_size_pt,
    axis_title_size_pt = panel_axis_title_size_pt,
    axis_text_size_pt = panel_axis_text_size_pt,
    panel_border_width = panel_border_width
  )


  output_png <- file.path(output_dir, "Figure4_low_flow_screening.png")
  figure_width_in <- 8.27
  figure_height_in <- 10.80
  panel_output_dir <- panel_output_dir_for_figure(output_png)

  if (dir.exists(panel_output_dir)) {
    unlink(panel_output_dir, recursive = TRUE, force = TRUE)
  }
  dir.create(panel_output_dir, recursive = TRUE, showWarnings = FALSE)

  aligned_plots <- cowplot::align_plots(
    panel_a, panel_b, panel_c, panel_d,
    align = "hv",
    axis = "tblr",
    greedy = FALSE
  )

  top_row <- cowplot::plot_grid(
    plotlist = aligned_plots[1:2],
    ncol = 2,
    rel_widths = c(1, 1)
  )

  middle_row <- cowplot::plot_grid(
    plotlist = aligned_plots[3:4],
    ncol = 2,
    rel_widths = c(1, 1)
  )

  bottom_row_weight <- 0.704
  total_row_weight <- 2 + bottom_row_weight
  top_row_height <- 1 / total_row_weight
  middle_row_height <- 1 / total_row_weight
  bottom_row_height <- bottom_row_weight / total_row_weight
  e_container_x <- 0.036
  e_container_width <- 0.940

  figure_plot <- cowplot::ggdraw() +
    cowplot::draw_plot(top_row, x = 0, y = middle_row_height + bottom_row_height, width = 1, height = top_row_height) +
    cowplot::draw_plot(middle_row, x = 0, y = bottom_row_height, width = 1, height = middle_row_height) +
    cowplot::draw_plot(panel_e, x = e_container_x, y = 0, width = e_container_width, height = bottom_row_height)

  main_outputs <- save_plot_outputs(
    plot_object = figure_plot,
    filename = output_png,
    width = figure_width_in,
    height = figure_height_in,
    dpi = 320
  )

  panel_outputs <- save_panel_plot_outputs(
    panel_specs = list(
      list(plot_object = panel_a, panel_id = "A", file_stub = "roc_curves", row = 1, col = 1, width = figure_width_in / 2, height = 3.75),
      list(plot_object = panel_b, panel_id = "B", file_stub = "sensitivity_specificity_threshold_scan", row = 1, col = 2, width = figure_width_in / 2, height = 3.75),
      list(plot_object = panel_c, panel_id = "C", file_stub = "threshold_15_confusion_matrix", row = 2, col = 1, width = figure_width_in / 2, height = 3.75),
      list(plot_object = panel_d, panel_id = "D", file_stub = "youden_confusion_matrix", row = 2, col = 2, width = figure_width_in / 2, height = 3.75),
      list(plot_object = panel_e, panel_id = "E", file_stub = "diagnostic_performance_summary", row = 3, col = 1, width = figure_width_in, height = 2.64)
    ),
    figure_filename = output_png,
    figure_width = figure_width_in,
    figure_height = figure_height_in,
    col_widths = c(1, 1),
    row_heights = c(1.00, 1.00, 0.704),
    panel_dir = panel_output_dir,
    dpi = 320
  )

  invisible(c(main_outputs, list(panel_outputs = panel_outputs)))
}

if (identical(environment(), globalenv()) && !interactive()) {
  build_figure_04()
}
