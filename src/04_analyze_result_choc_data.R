# Rachel K. Riggs and Carrie Cheung, Nov 2018

# This script reads in cleaned data produced by 01_load_choc_data.R, 
# performs a statisical analysis, and produces a visualization.
# This script takes 2 arguments:
# arg1 is the input file
# arg2 is the output file
# Input filepath specifies location of the cleaned chocolate dataset and 
# Output filepath specifies where to save .png file of statistical analysis.

# Usage: 
# bash Rscript src/04_analyze_result_choc_data.R data/cleaned_choc_data.csv results/choc_ratings_analysis_viz.png


# load libraries
suppressPackageStartupMessages(library(tidyverse))
library(infer)

# Read in input parameters from command line
# input <- "data/cleaned_choc_data.csv"
# output <- "results/choc_ratings_analysis_viz.png"
args = commandArgs(trailingOnly = TRUE)
input <- args[1]
output <- args[2]

# define main function
main <- function() {
  
  # read in data
  data <- read.csv(input)
  
  # group Venezuela and Other countries
  data <- data %>%
    mutate(origin = ifelse(Broad.Bean.Origin == "Venezuela", "Venezuela", "Other"))
  
  # compute mean Ratings of Venezuela and Other  
  data_summarized <- data %>% 
    group_by(origin) %>% 
    summarize(mean_rating = mean(Rating))
  
  # define test statistic - calculate delta* from sample
  delta_star <- diff(data_summarized$mean_rating)
  
  # generate simulated data under the model H_0 & calculate test 
  # statistics for each simulated sample
  null_dist_two_means <- data %>%
    specify(formula = Rating ~ origin) %>% 
    hypothesize(null = "independence") %>% 
    generate(reps = 10000, type = "permute") %>% 
    calculate(stat = "diff in means", order = c("Venezuela", "Other"))
  
  # calculate p-value
  pval <- null_dist_two_means %>% 
    get_pvalue(delta_star, direction = "both")
  
  # calculate confidence interval
  ci <- null_dist_two_means %>%  
    get_ci() %>% 
    rename(lower_ci = `2.5%`, upper_ci = `97.5%`)
  
  # create plot
  null_dist_plot <- null_dist_two_means %>% 
    visualize() +
    geom_vline(xintercept = delta_star, colour = "red") +
    geom_vline(xintercept = c(ci[[1]], ci[[2]]), color = "blue", lty = 2) +
    xlab("Test Statistic (Difference Between Means)") +
    ylab("Count") +
    ggtitle("Null Hypothesis Distribution") +
    annotate("text", x = .038, y = 1975, label = round(delta_star, 3), size = 3) +  
    theme_bw() +
    theme(axis.title = element_text(size=rel(0.7)),
          axis.text = element_text(size=rel(0.7)),
          plot.title = element_text(size=rel(1)))

  # save plot 
  ggsave(output, width = 3.5, height = 3.5, units = "in", dpi = 150)
}

# call main function
main()
