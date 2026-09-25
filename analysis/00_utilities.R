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

# Redact counts <= 7 and round remaining counts to the nearest 5
apply_sdc <- function(x) {
  if_else(
    x <= 7,
    "[REDACTED]",
    as.character(round(x / 5) * 5)
  )
}