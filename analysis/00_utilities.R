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
