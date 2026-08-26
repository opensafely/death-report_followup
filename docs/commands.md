## DeveloUseful commands

### Generate dummy dataset

```bash
opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py 
    --output output/dummy_dataset.csv
```

### Generate dummy tables
```bash
opensafely exec ehrql:v1 create-dummy-tables analysis/dataset_definition.py dummy_tables
```

### Re-running the dataset using the dummy tables
```bash
opensafely exec ehrql:v1 generate-dataset analysis/01_dataset_definition.py --dummy-tables dummy_tables --output output/dummy_dataset.csv
# or if you've already got this in the yaml file 
opensafely run extract_data
```

### Running 02
```bash
Rscript analysis/02_inclusion_exclusion_criteria.R
```

### Forcing dependencies:
### For example if running a down-stream action which has dependencies you haev already run
### You may want to 'refresh' the run of those dependencies too. 
```bash
opensafely run extract_underlying_cause_summary --force-run-dependencies
```