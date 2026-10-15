###################################################
# Author: Irene Kyomuhangi
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2026
####################################################
# Purpose: Define utility functions used across analysis scripts
####################################################


# -----------------------------------------------------------------------------
# Statistical disclosure control
# -----------------------------------------------------------------------------
# Redact counts <= 7 by replacing them with NA and round remaining counts
# to the nearest 5.
#
# Counts remain numeric so that disclosure-controlled values can be used
# in subsequent calculations, such as percentages.
# TODO: Do we need to retain true 0's?

apply_sdc <- function(x) {
  if_else(
    x <= 7,
    NA_real_,
    round(x / 5) * 5
  )
}


# -----------------------------------------------------------------------------
# Categorise differences in recorded dates of death
# -----------------------------------------------------------------------------

# Difference in days is calculated as TPP date minus ONS date.
# Negative values indicate TPP dates before ONS; positive values indicate
# TPP dates after ONS.

categorise_date_difference <- function(diff_days) {
  factor(
    case_when(
      is.na(diff_days) ~ NA_character_,
      diff_days <= -29 ~ "-29+",
      diff_days >= -28 & diff_days <= -8 ~ "-28 to -8",
      diff_days >= -7 & diff_days <= -1 ~ "-7 to -1",
      diff_days == 0 ~ "0",
      diff_days >= 1 & diff_days <= 7 ~ "1 to 7",
      diff_days >= 8 & diff_days <= 28 ~ "8 to 28",
      diff_days >= 29 ~ "29+"
    ),
    levels = c(
      "-29+", "-28 to -8", "-7 to -1",
      "0", "1 to 7", "8 to 28", "29+"
    ),
    ordered = TRUE
  )
}