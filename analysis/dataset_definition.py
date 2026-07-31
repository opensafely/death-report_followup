###################################################
# Author: Irene Kyomuhangi
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2026
####################################################
# This script defines the following population:

# Inclusion criteria:
# Individuals registered with a TPP practice and with a registered death in the ONS 
# dataset between 1 January 2022 and the most recent available data extract (* or X days before the 
# most recent data extract - TDB). 
# 
# Exclusion criteria: 
# Individuals > 110 years due to risk of incorrectly recorded age;
# Individuals with missing sex an indicator of poor data quality;
# Individuals not registered with a TPP practice on date of death (*with X days grace period -  TBD)
#
###################################################


#import elevant ehrQL tools and tables
from ehrql import create_dataset, case, when, days, codelist_from_csv
from ehrql.tables.tpp import (
    patients,
    ons_deaths,
    clinical_events,
    practice_registrations,
    addresses,
)
from codelists import (
    TPP_CODED_DEATH_CODES,
    CAUSE_GROUP,
    DEATH_CIRCUMSTANCE,
    CORONIAL_RISK,
    REGISTRATION_COMPLEXITY,
)


# create the dataset object
dataset = create_dataset()

# -----------------------------------------------------------------------------
# study period / parameters
# -----------------------------------------------------------------------------

STUDY_START_DATE = "2022-01-01"
STUDY_END_DATE = "2026-05-01"   # update based on final decision about what the end-date should be

# -----------------------------------------------------------------------------
# Population
# -----------------------------------------------------------------------------

# ----------------Death definitions ----------------

# individual has ONS death date recorded
has_ons_death_date = ons_deaths.date.is_not_null()

# individual has TPP structured death date recorded
has_tpp_death_date = patients.date_of_death.is_not_null()

# Find and keep the earliest death date for coded tpp deaths
tpp_coded_death_event = (
    clinical_events
    .where(clinical_events.snomedct_code.is_in(TPP_CODED_DEATH_CODES))
    .sort_by(clinical_events.date)
    .first_for_patient()
)

# individual has a coded death date recorded in tpp data
has_tpp_coded_death = tpp_coded_death_event.date.is_not_null()

# individual has death recorded in ONS + TPP
has_ons_and_tpp_death = (
    has_ons_death_date
    & has_tpp_death_date
)

# individual has ONS-only date of death
has_ons_only_death = (
    has_ons_death_date
    & ~has_tpp_death_date
)

# ----------------Age variables --------------

# Generate Age at ONS death date
age_at_ons_death = patients.age_on(ons_deaths.date)

# Keep plausible ages only, keeping people ages 0-110 years.
# Also retain infants aged <1 year, whose integer age may be recorded as 0.
has_possible_age = (
    ((age_at_ons_death >= 0) & (age_at_ons_death <= 110))
    | (patients.date_of_birth.year == ons_deaths.date.year)
)

# ---------------- Registration status --------------

# Last registration
last_registration = (
    practice_registrations
    .sort_by(
        practice_registrations.start_date,
        practice_registrations.end_date,
    )
    .last_for_patient()
)

# Registration at ONS death date
registered_at_ons_death = practice_registrations.exists_for_patient_on(ons_deaths.date)


# -------------- ONS death is within study period --------------
death_in_study_period = (
    ons_deaths.date.is_on_or_after(STUDY_START_DATE)
    & ons_deaths.date.is_on_or_before(STUDY_END_DATE)
)

# ----------------Define population----------------
dataset.define_population(
    has_ons_death_date
    & death_in_study_period
    & registered_at_ons_death
    & has_possible_age
    & patients.sex.is_not_null()
)


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

# ---------------- Death ----------------
dataset.ons_death_date = ons_deaths.date
dataset.tpp_death_date = patients.date_of_death
dataset.tpp_coded_death_date = tpp_coded_death_event.date

# analysis flags
dataset.has_tpp_coded_death = has_tpp_coded_death
dataset.has_ons_and_tpp_death = has_ons_and_tpp_death
dataset.has_ons_only_death = has_ons_only_death

# ---------------- Demographic ----------------

# Age at ONS date of death
dataset.date_of_birth = patients.date_of_birth
dataset.age = age_at_ons_death

# Sex
dataset.sex = patients.sex

# ---------------- Place of death ----------------

dataset.place_of_death = ons_deaths.place

# ---------------- Region/Practice ----------------

# Practice region
dataset.region = practice_registrations.for_patient_on(ons_deaths.date).practice_nuts1_region_name

# Practice (anonymous ID)
dataset.practice = practice_registrations.for_patient_on(ons_deaths.date).practice_pseudo_id


# ---------------- Cause of death generated categories ----------------

# ONS underlying cause of death
dataset.underlying_cause_of_death = ons_deaths.underlying_cause_of_death

# Broad Cause Group
dataset.cause_group = case(
    when(
        ons_deaths.underlying_cause_of_death.is_in(CAUSE_GROUP["Cancer"])
    ).then("Cancer"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CAUSE_GROUP["Cardiovascular disease"])
    ).then("Cardiovascular disease"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CAUSE_GROUP["Respiratory disease"])
    ).then("Respiratory disease"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CAUSE_GROUP["Infectious diseases"])
    ).then("Infectious diseases"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CAUSE_GROUP["Neurological and dementia disorders"])
    ).then("Neurological and dementia disorders"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CAUSE_GROUP["Other chronic medical conditions"])
    ).then("Other chronic medical conditions"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CAUSE_GROUP["Other or ill-defined causes"])
    ).then("Other or ill-defined causes"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CAUSE_GROUP["Perinatal, congenital and maternal conditions"])
    ).then("Perinatal, congenital and maternal conditions"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CAUSE_GROUP["External causes and injuries"])
    ).then("External causes and injuries"),
)

# Death Circumstance
dataset.death_circumstance = case(
    when(
        ons_deaths.underlying_cause_of_death.is_in(DEATH_CIRCUMSTANCE["Expected medically managed"])
    ).then("Expected medically managed"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(DEATH_CIRCUMSTANCE["Sudden natural"])
    ).then("Sudden natural"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(DEATH_CIRCUMSTANCE["External injury or poisoning"])
    ).then("External injury or poisoning"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(DEATH_CIRCUMSTANCE["Ill-defined or uncertain"])
    ).then("Ill-defined or uncertain"),
)

# Coronial Investigation Risk
dataset.coronial_investigation_risk = case(
    when(
        ons_deaths.underlying_cause_of_death.is_in(CORONIAL_RISK["Low"])
    ).then("Low"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CORONIAL_RISK["Possible"])
    ).then("Possible"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(CORONIAL_RISK["High"])
    ).then("High"),
)

# Registration Complexity
dataset.registration_complexity = case(
    when(
        ons_deaths.underlying_cause_of_death.is_in(REGISTRATION_COMPLEXITY["Standard"])
    ).then("Standard"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(REGISTRATION_COMPLEXITY["Moderate"])
    ).then("Moderate"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(REGISTRATION_COMPLEXITY["Enhanced"])
    ).then("Enhanced"),
    when(
        ons_deaths.underlying_cause_of_death.is_in(REGISTRATION_COMPLEXITY["High"])
    ).then("High"),
)

# -----------------------------------------------------------------------------
# Dummy data
# -----------------------------------------------------------------------------

dataset.configure_dummy_data(
    population_size=1000,
    timeout=180,
    additional_population_constraint=(
        # ONS death must be within the study period
        dataset.ons_death_date.is_on_or_between(STUDY_START_DATE, STUDY_END_DATE)
        &
        # keep TPP death dates in range when present
        (
            dataset.tpp_death_date.is_null()
            | dataset.tpp_death_date.is_on_or_between(STUDY_START_DATE, STUDY_END_DATE)
        )
        &
        # keep coded TPP death dates in range when present
        (
            dataset.tpp_coded_death_date.is_null()
            | dataset.tpp_coded_death_date.is_on_or_between(STUDY_START_DATE, STUDY_END_DATE)
        )
        &
        # keep registration start/end dates roughly around the study period
        (
            dataset.last_registration_start_date.is_null()
            | dataset.last_registration_start_date.is_on_or_between("2021-12-01", STUDY_END_DATE)
        )
        &
        (
            dataset.last_registration_end_date.is_null()
            | dataset.last_registration_end_date.is_on_or_between("2021-12-01", STUDY_END_DATE)
        )
    ),
)