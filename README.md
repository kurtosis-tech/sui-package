# SUI Package

A Kurtosis Starlark package that spins up everything below in a single command:
1. A Sui fullnode
2. An indexer
3. A Postgres Database for the indexer

This environment definition is reproducable & is portable (works on your laptop or in the cloud at large scales). 

NOTE: This package combines [Sui Fullnode Docker setup](https://github.com/MystenLabs/sui/tree/main/docker/fullnode) and the [Sui Fullnode-x Docker setup](https://github.com/MystenLabs/sui/tree/main/docker/fullnode-x) into a single package.

To run, you must first [install the Kurtosis CLI](https://docs.kurtosis.com/install), have Docker running, and then simply run:

`kurtosis run github.com/kurtosis-tech/sui-package`
