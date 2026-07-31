from ehrql import codelist_from_csv


#codelists

TPP_CODED_DEATH_CODES = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-death_cod.csv",
    column="code",
)

ETHNICITY5 = codelist_from_csv(
  "codelists/opensafely-ethnicity-snomed-0removed.csv",
  column="code",
  category_column="Label_6", # it's 6 because there is an additional "6 - Not stated" but this is not represented in SNOMED, instead corresponding to no ethnicity code
)

# ---------------------------------------------------------------------
# Cause groups
# ---------------------------------------------------------------------

CAUSE_GROUP = {
    "Cancer": codelist_from_csv(
        "codelists/generated/cause_group_cancer.csv",
        column="code",
    ),
    "Cardiovascular disease": codelist_from_csv(
        "codelists/generated/cause_group_cardiovascular_disease.csv",
        column="code",
    ),
    "Respiratory disease": codelist_from_csv(
        "codelists/generated/cause_group_respiratory_disease.csv",
        column="code",
    ),
    "Infectious diseases": codelist_from_csv(
        "codelists/generated/cause_group_infectious_diseases.csv",
        column="code",
    ),
    "Neurological and dementia disorders": codelist_from_csv(
        "codelists/generated/cause_group_neurological_and_dementia_disorders.csv",
        column="code",
    ),
    "Other chronic medical conditions": codelist_from_csv(
        "codelists/generated/cause_group_other_chronic_medical_conditions.csv",
        column="code",
    ),
    "Other or ill-defined causes": codelist_from_csv(
        "codelists/generated/cause_group_other_or_ill_defined_causes.csv",
        column="code",
    ),
    "Perinatal, congenital and maternal causes": codelist_from_csv(
        "codelists/generated/cause_group_perinatal_congenital_and_maternal_causes.csv",
        column="code",
    ),
    "External causes and injuries": codelist_from_csv(
        "codelists/generated/cause_group_external_causes_and_injuries.csv",
        column="code",
    ),
}


# ---------------------------------------------------------------------
# Death circumstance
# ---------------------------------------------------------------------

DEATH_CIRCUMSTANCE = {
    "Expected medically managed": codelist_from_csv(
        "codelists/generated/death_circumstance_expected_medically_managed.csv",
        column="code",
    ),
    "Sudden natural": codelist_from_csv(
        "codelists/generated/death_circumstance_sudden_natural.csv",
        column="code",
    ),
    "External injury or poisoning": codelist_from_csv(
        "codelists/generated/death_circumstance_external_injury_or_poisoning.csv",
        column="code",
    ),
    "Ill-defined or uncertain": codelist_from_csv(
        "codelists/generated/death_circumstance_ill_defined_or_uncertain.csv",
        column="code",
    ),
}


# ---------------------------------------------------------------------
# Coronial investigation risk
# ---------------------------------------------------------------------

CORONIAL_RISK = {
    "Low": codelist_from_csv(
        "codelists/generated/coronial_investigation_risk_low.csv",
        column="code",
    ),
    "Possible": codelist_from_csv(
        "codelists/generated/coronial_investigation_risk_possible.csv",
        column="code",
    ),
    "High": codelist_from_csv(
        "codelists/generated/coronial_investigation_risk_high.csv",
        column="code",
    ),
}


# ---------------------------------------------------------------------
# Registration complexity
# ---------------------------------------------------------------------

REGISTRATION_COMPLEXITY = {
    "Standard": codelist_from_csv(
        "codelists/generated/registration_complexity_standard.csv",
        column="code",
    ),
    "Moderate": codelist_from_csv(
        "codelists/generated/registration_complexity_moderate.csv",
        column="code",
    ),
    "Enhanced": codelist_from_csv(
        "codelists/generated/registration_complexity_enhanced.csv",
        column="code",
    ),
    "High": codelist_from_csv(
        "codelists/generated/registration_complexity_high.csv",
        column="code",
    ),
}