###################################################
# Author: Irene Kyomuhangi
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2026
####################################################
# This script extracts information ONS deaths and corresponding death records in primary care data.
# The goal is to analyse how factors such as underlying cause of death contribute to  
# differences in recorded date of death between the two datasets 
###################################################


#import elevant ehrQL tools and tables
from ehrql import create_dataset
from ehrql.tables.tpp import (
    patients,
    ons_deaths,
    clinical_events,
    practice_registrations,
)
from codelists import (
    TPP_CODED_DEATH_CODES
)
# create the dataset object
dataset = create_dataset()


# -----------------------------------------------------------------------------
# Population
# -----------------------------------------------------------------------------

# ----------------Death definitions ----------------

# individual has ONS death date recorded
has_ons_death_date = ons_deaths.date.is_not_null()

# Find and keep the earliest death date for coded tpp deaths
tpp_coded_death_event = (
    clinical_events
    .where(clinical_events.snomedct_code.is_in(TPP_CODED_DEATH_CODES))
    .sort_by(clinical_events.date)
    .first_for_patient()
)

# individual has a coded death date recorded in TPP data
has_tpp_coded_death = tpp_coded_death_event.date.is_not_null()


# ----------------Age variables --------------

# Generate Age at ONS death date
age_at_ons_death = patients.age_on(ons_deaths.date)

# Keep plausible ages only, keeping people ages 0-110 years.
# Also retain infants aged <1 year, whose integer age may be recorded as 0.
has_possible_age = (
    ((age_at_ons_death >= 0) & (age_at_ons_death <= 110))
    | (patients.date_of_birth.year == ons_deaths.date.year)
)


# ----------------Define population----------------
dataset.define_population(
    has_ons_death_date
    & has_possible_age
    & patients.sex.is_not_null()
)


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------


# ---------------- Registration status --------------

# To later apply inclusion criteria on registration, extract last registration info
last_registration = (
    practice_registrations
    .sort_by(
        practice_registrations.start_date,
        practice_registrations.end_date,
    )
    .last_for_patient()
)

dataset.last_registration_start_date = last_registration.start_date
dataset.last_registration_end_date = last_registration.end_date


# ---------------- Death ----------------
# include three dates of death: ONS, TPP structured death date, and TPP death code date
dataset.ons_death_date = ons_deaths.date
dataset.tpp_death_date = patients.date_of_death
dataset.tpp_coded_death_date = tpp_coded_death_event.date
dataset.has_tpp_coded_death = has_tpp_coded_death
dataset.underlying_cause_of_death = ons_deaths.underlying_cause_of_death


# ---------------- Demographics----------------

# Age at ONS date of death
dataset.date_of_birth = patients.date_of_birth
dataset.age = age_at_ons_death


# ---------------- Place of death ----------------

dataset.place_of_death = ons_deaths.place


# ---------------- Region & Practice ----------------

# Practice region
dataset.region = practice_registrations.for_patient_on(ons_deaths.date).practice_nuts1_region_name

# Practice (anonymous ID)
dataset.practice = practice_registrations.for_patient_on(ons_deaths.date).practice_pseudo_id


# -----------------------------------------------------------------------------
# Dummy data
# -----------------------------------------------------------------------------

dataset.configure_dummy_data(
    population_size=10000,
    timeout=180,
    additional_population_constraint=(
        # ONS death date
        (dataset.ons_death_date.is_on_or_between( "2022-01-01", "2026-05-01")
            | dataset.ons_death_date.is_null()
        ) &
        # Structured TPP death date
        (dataset.tpp_death_date.is_on_or_between("2022-01-01", "2026-05-01")
            | dataset.tpp_death_date.is_null()
        )
        &
        # Coded TPP death date
        (dataset.tpp_coded_death_date.is_on_or_between("2022-01-01", "2026-05-01")
            | dataset.tpp_coded_death_date.is_null()
        )
        &
        # Registration start date
        (dataset.last_registration_start_date.is_on_or_between( "2010-01-01","2026-05-01")
            | dataset.last_registration_start_date.is_null()
        )
    ),
)