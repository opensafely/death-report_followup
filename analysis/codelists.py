from ehrql import codelist_from_csv


#codelists

TPP_CODED_DEATH_CODES = codelist_from_csv(
    "codelists/nhsd-primary-care-domain-refsets-death_cod.csv",
    column="code",
)
