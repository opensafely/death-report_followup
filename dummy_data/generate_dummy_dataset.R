###################################################
# Author: Irene Kyomuhangi
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2026
####################################################
# Purpose:
#   Generate fully synthetic death records for testing
#   the death-report follow-on analytical workflow.
#
#   The dataset is designed to test:
#   - inclusion/exclusion criteria;
#   - cause-of-death classifications;
#   - ONS-only and TPP-recorded deaths;
#   - agreement and differences between ONS and TPP dates;
#   - precedence of structured over coded TPP death dates.
#
#   The synthetic dataset uses a subset of valid ICD-10
#   codes and deliberately constructed recording scenarios.
#   It does not reproduce the distribution of real deaths.
#
#   No real patient data or OpenSAFELY extracts are used.
#
#   Run from the repository root:
#     Rscript dummy_data/generate_dummy_dataset.R
#
#   Output:
#     dummy_data/dummy_dataset.csv
#
#   The output is used by ehrQL with --dummy-data-file
#   for local testing of scripts 02 through 05.
####################################################


# -----------------------------------------------------------------------------
# Set parameters
# -----------------------------------------------------------------------------

# Set a fixed random seed for reproducibility
set.seed(20261014)

# Generate 240 records per cause-of-death group
n_per_group <- 240L

# Set output file and study period
output_file <- "dummy_data/dummy_dataset.csv"
study_start_date <- as.Date("2022-01-01")
study_end_date <- as.Date("2026-03-01")


# -----------------------------------------------------------------------------
# Define underlying cause-of-death codes
# -----------------------------------------------------------------------------

# Use a subset of ICD-10 codes covering the broad cause-of-death groups
# defined in 04_add_classifications.R.
#
# Codes are stored without decimal points, consistent with the
# classification rules. Missing codes are included to test their handling.
#
# These codes are selected for testing, not to represent actual mortality
# frequencies.

icd10_by_group <- list(
  neoplasms = c("C349", "C509", "D120"),
  cardiovascular = c("I219", "I500", "I639"),
  respiratory = c("J189", "J449", "U070"),
  neurological = c("G309", "F03", "G20"),
  infectious = c("A419", "B182", "U071"),
  external = c("S720", "W190", "U129"),
  perinatal_congenital_maternal = c("P220", "Q909", "O159"),
  ill_defined = c("R99", "R98", "R96"),
  other_medical = c("E119", "D649", "N189"),
  missing = NA_character_
)


# -----------------------------------------------------------------------------
# Generate cohort and ONS death dates
# -----------------------------------------------------------------------------

# Generate an equal number of individuals per broad cause group
labels <- rep(names(icd10_by_group), each = n_per_group)
n <- length(labels)

# Generate ONS death dates within the study period
ons_death_date <- sample(
  seq(study_start_date, study_end_date, by = "day"),
  n,
  replace = TRUE
)

# Assign one ICD-10 code to each individual
underlying_cause_of_death <- vapply(labels, function(group) {
  values <- icd10_by_group[[group]]
  values[sample.int(length(values), 1)]
}, character(1))


# -----------------------------------------------------------------------------
# Generate TPP death-recording scenarios
# -----------------------------------------------------------------------------

# Construct scenarios covering:
#   - ONS-only deaths;
#   - exact agreement between ONS and TPP;
#   - TPP dates earlier or later than ONS;
#   - structured TPP dates only;
#   - coded TPP dates only;
#   - both structured and coded dates.
#
# Some scenarios deliberately assign conflicting structured and coded
# TPP dates to test that the structured date takes precedence.
#
# All six non-zero date-difference categories are represented.

scenarios <- c(
  "ons_only",             # No TPP death record
  "structured_match",     # Structured TPP date matches ONS
  "structured_early_1",   # Structured TPP date 1 day earlier than ONS
  "structured_early_10",  # Structured TPP date 10 days earlier than ONS
  "structured_early_40",  # Structured TPP date 40 days earlier than ONS
  "structured_late_1",    # Structured TPP date 1 day later than ONS
  "structured_late_10",   # Structured TPP date 10 days later than ONS
  "structured_late_40",   # Structured TPP date 40 days later than ONS
  "coded_only_match",     # Coded TPP date matches ONS; no structured date
  "coded_only_early_10", # Coded TPP date 10 days earlier than ONS
  "coded_only_late_40",  # Coded TPP date 40 days later than ONS
  "both_conflict",        # Structured TPP matches ONS; coded date differs
  "both_match",           # Both TPP dates match ONS
  "both_mismatch",        # Both TPP dates differ from ONS
  "coded_only_late_1"    # Coded TPP date 1 day later than ONS
)

# -----------------------------------------------------------------------------
# Assign death-recording scenarios
# -----------------------------------------------------------------------------

# Assign illustrative probabilities to the death-recording scenarios.
# Structured TPP death dates are more common than coded-only records,
# and exact agreement is more common than large date differences.
#
# These probabilities are intended for synthetic testing and do not
# represent observed distributions in OpenSAFELY data.

scenario_prob <- c(
  ons_only = 0.10,
  structured_match = 0.35,
  structured_early_1 = 0.05,
  structured_early_10 = 0.04,
  structured_early_40 = 0.02,
  structured_late_1 = 0.05,
  structured_late_10 = 0.04,
  structured_late_40 = 0.02,
  coded_only_match = 0.02,
  coded_only_early_10 = 0.01,
  coded_only_late_40 = 0.005,
  both_conflict = 0.12,
  both_match = 0.15,
  both_mismatch = 0.02,
  coded_only_late_1 = 0.005
)

# Check that the probabilities match the defined scenarios
# and sum to 1. Stop if this is not the case. 
stopifnot(
  setequal(names(scenario_prob), scenarios),
  abs(sum(scenario_prob) - 1) < 1e-10
)

# Allocate fixed numbers to each scenario within each cause group.
# Remainder allocation ensures the counts sum to n_per_group.
expected_counts <- n_per_group * scenario_prob
scenario_counts <- floor(expected_counts)

remaining <- n_per_group - sum(scenario_counts)

if (remaining > 0) {
  remainder_order <- order(
    expected_counts - scenario_counts,
    decreasing = TRUE
  )

  scenario_counts[remainder_order[seq_len(remaining)]] <-
    scenario_counts[remainder_order[seq_len(remaining)]] + 1L
}

# Ensure every scenario is represented at least once.
# This is feasible with the current n_per_group = 240.
if (any(scenario_counts == 0)) {
  stop("Increase n_per_group to represent every scenario.")
}

# -----------------------------------------------------------------------------
# Introduce variation for SDC testing
# -----------------------------------------------------------------------------

# Retain the baseline scenario distribution for most cause-of-death groups.
# Introduce controlled variation in selected groups to test suppression
# and rounding of small counts.

scenario <- unlist(
  lapply(names(icd10_by_group), function(group) {

    counts <- scenario_counts

    # Neoplasms: no coded-only deaths
    if (group == "neoplasms") {
      counts["structured_match"] <-
        counts["structured_match"] + sum(counts[c(
          "coded_only_match",
          "coded_only_early_10",
          "coded_only_late_40",
          "coded_only_late_1"
        )])

      counts[c(
        "coded_only_match",
        "coded_only_early_10",
        "coded_only_late_40",
        "coded_only_late_1"
      )] <- 0
    }

    # Cardiovascular disease: small number of ONS-only deaths
    if (group == "cardiovascular") {
      difference <- counts["ons_only"] - 5

      counts["ons_only"] <- 5
      counts["structured_match"] <-
        counts["structured_match"] + difference
    }

    # Respiratory disease: ONS-only count just above suppression threshold
    if (group == "respiratory") {
      difference <- counts["ons_only"] - 8

      counts["ons_only"] <- 8
      counts["structured_match"] <-
        counts["structured_match"] + difference
    }

    # Neurological disorders: larger ONS-only count
    if (group == "neurological") {
      difference <- 40 - counts["ons_only"]

      counts["ons_only"] <- 40
      counts["structured_match"] <-
        counts["structured_match"] - difference
    }

    # Confirm the group still contains 240 individuals
    stopifnot(sum(counts) == n_per_group)

    # Randomly distribute the scenarios within the group
    sample(rep(names(counts), times = counts))
  }),
  use.names = FALSE
)

# Check the distribution of scenarios across cause-of-death groups
scenario_check <- table(
  cause_group = labels,
  scenario = scenario
)

print(scenario_check)


# -----------------------------------------------------------------------------
# Generate TPP dates of death
# -----------------------------------------------------------------------------

# Initialise TPP dates as missing
tpp_death_date <- rep(as.Date(NA), n)
tpp_coded_death_date <- rep(as.Date(NA), n)

# Assign TPP dates according to the selected scenario
for (i in seq_len(n)) {
  s <- scenario[i]

  if (s == "structured_match")
    tpp_death_date[i] <- ons_death_date[i]

  if (s == "structured_early_1")
    tpp_death_date[i] <- ons_death_date[i] - 1

  if (s == "structured_early_10")
    tpp_death_date[i] <- ons_death_date[i] - 10

  if (s == "structured_early_40")
    tpp_death_date[i] <- ons_death_date[i] - 40

  if (s == "structured_late_1")
    tpp_death_date[i] <- ons_death_date[i] + 1

  if (s == "structured_late_10")
    tpp_death_date[i] <- ons_death_date[i] + 10

  if (s == "structured_late_40")
    tpp_death_date[i] <- ons_death_date[i] + 40

  if (s == "coded_only_match")
    tpp_coded_death_date[i] <- ons_death_date[i]

  if (s == "coded_only_early_10")
    tpp_coded_death_date[i] <- ons_death_date[i] - 10

  if (s == "coded_only_late_40")
    tpp_coded_death_date[i] <- ons_death_date[i] + 40

  if (s == "coded_only_late_1")
    tpp_coded_death_date[i] <- ons_death_date[i] + 1

  # Structured date agrees with ONS; coded date differs
  if (s == "both_conflict") {
    tpp_death_date[i] <- ons_death_date[i]
    tpp_coded_death_date[i] <- ons_death_date[i] + 12
  }

  if (s == "both_match") {
    tpp_death_date[i] <- ons_death_date[i]
    tpp_coded_death_date[i] <- ons_death_date[i]
  }

  # Both TPP dates differ from ONS
  if (s == "both_mismatch") {
    tpp_death_date[i] <- ons_death_date[i] - 8
    tpp_coded_death_date[i] <- ons_death_date[i] + 5
  }
}


# -----------------------------------------------------------------------------
# Generate dates of birth
# -----------------------------------------------------------------------------

# Generate predominantly adult deaths, with age-appropriate examples
# for perinatal/congenital and maternal ICD-10 codes.
#
# Dates of birth are represented using the 15th of the month to test
# the limited DOB precision considered in the inclusion/exclusion criteria.
# Some neonatal deaths occur before the 15th of their birth month.

age <- sample(40:95, n, replace = TRUE)

perinatal <- underlying_cause_of_death %in% c("P220", "Q909")
maternal <- underlying_cause_of_death %in% "O159"

age[perinatal] <- 0L
age[maternal] <- sample(20:40, sum(maternal), replace = TRUE)

date_of_birth <- ons_death_date - round(age * 365.25)

date_of_birth[perinatal] <- as.Date(
  paste0(format(ons_death_date[perinatal], "%Y-%m"), "-15")
)

date_of_birth[!perinatal] <- as.Date(
  paste0(format(date_of_birth[!perinatal], "%Y-%m"), "-15")
)

# Include a small number of invalid date sequences to test exclusion in 02_
invalid_rows <- which(!perinatal)[seq_len(12)]
date_of_birth[invalid_rows] <- ons_death_date[invalid_rows] + 65


# -----------------------------------------------------------------------------
# Generate registration status
# -----------------------------------------------------------------------------

# Most individuals are registered with a TPP practice on the day before
# death. Some are deliberately assigned FALSE to test exclusion in 02_.

registered_day_before_death <- rep(TRUE, n)
registered_day_before_death[sample(seq_len(n), 80)] <- FALSE


# -----------------------------------------------------------------------------
# Generate additional variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Generate additional variables
# -----------------------------------------------------------------------------

# Generate synthetic practice region, practice and place-of-death variables
# for later descriptive analyses.
#
# Region and place-of-death categories follow the values defined in the
# OpenSAFELY ehrQL schema.

# Practice regions
regions <- c(
  "London",
  "South East",
  "South West",
  "East",
  "East Midlands",
  "West Midlands",
  "North West",
  "North East",
  "Yorkshire and The Humber"
)

# Place-of-death categories
places <- c(
  "Home",
  "Hospital",
  "Care Home",
  "Hospice",
  "Elsewhere",
  "Other communal establishment"
)

# Generate numeric practice identifiers, consistent with the ehrQL data type.
# Multiple individuals may be assigned to the same practice.
practice <- sample(1:120, n, replace = TRUE)

# Assign each practice to one region.
# All individuals registered with the same practice have the same region.
practice_region <- sample(regions, 120, replace = TRUE)

region <- practice_region[practice]

# Assign place of death using illustrative probabilities.
# These do not represent observed distributions in OpenSAFELY data.
place_of_death <- sample(
  places,
  n,
  replace = TRUE,
  prob = c(0.22, 0.47, 0.19, 0.06, 0.04, 0.02)
)


# Check that each practice is assigned to only one region
stopifnot(
  all(
    tapply(region, practice, function(x) length(unique(x))) == 1
  )
)


# -----------------------------------------------------------------------------
# Assemble synthetic dataset
# -----------------------------------------------------------------------------

# Use the column names expected from 01_dataset_definition.py.
# The dataset represents synthetic ehrQL output and is used to test
# downstream analysis scripts, not the ehrQL extraction logic itself.

dummy_data <- data.frame(
  patient_id = seq_len(n),
  registered_day_before_death = registered_day_before_death,
  ons_death_date = ons_death_date,
  tpp_death_date = tpp_death_date,
  tpp_coded_death_date = tpp_coded_death_date,
  has_tpp_coded_death = !is.na(tpp_coded_death_date),
  underlying_cause_of_death = underlying_cause_of_death,
  date_of_birth = date_of_birth,
  age = age,
  place_of_death = place_of_death,
  region = region,
  practice = practice,
  stringsAsFactors = FALSE
)


# -----------------------------------------------------------------------------
# Format Boolean variables for ehrQL
# -----------------------------------------------------------------------------

# ehrQL requires Boolean values to be represented as T/F in dummy CSV files.

dummy_data$registered_day_before_death <- ifelse(
  dummy_data$registered_day_before_death, "T", "F"
)

dummy_data$has_tpp_coded_death <- ifelse(
  dummy_data$has_tpp_coded_death, "T", "F"
)


# -----------------------------------------------------------------------------
# Save output
# -----------------------------------------------------------------------------

# Save the synthetic dataset as an uncompressed CSV file
write.csv(
  dummy_data,
  output_file,
  row.names = FALSE,
  na = ""
)

# Report basic information about the generated dataset
cat("Wrote", nrow(dummy_data), "synthetic records to", output_file, "\n")
cat("Cause groups represented:", length(icd10_by_group), "(including missing)\n")
cat("ONS-only records:", sum(is.na(tpp_death_date) & is.na(tpp_coded_death_date)), "\n")
cat("Coded-only records:", sum(is.na(tpp_death_date) & !is.na(tpp_coded_death_date)), "\n")
cat("Not registered on day before death:", sum(!registered_day_before_death), "\n")
cat("Note: synthetic test data only; distributions are not estimates of real mortality.\n")

