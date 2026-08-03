# Development commands

## Generate dummy dataset

```bash
opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py 
    --output output/dummy_dataset.csv
```

## Generate dummy tables
```bash
opensafely exec ehrql:v1 create-dummy-tables analysis/dataset_definition.py dummy_tables
```

## Re-running the dataset using the dummy tables
```bash
opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py --dummy-tables dummy_tables --output output/dummy_dataset.csv
```

## Running prepate the dataset
```bash
Rscript analysis/01_prepare_dataset.R
```