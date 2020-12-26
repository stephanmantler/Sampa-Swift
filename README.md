# Sampa-Swift

Swift port of the [NREL Solar and Moon Position Algorithm](https://midcdmz.nrel.gov/sampa/) (SAMPA), closely mirroring the C code parameter conventions and calling convention.

## Notable differences
Swift Timezone values are rounded to the closest minute. This causes differences if randomly generated test data is compared.

The elevation parameter is folded into CLLocation altitude value. 
