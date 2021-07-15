# tq
Simple [TOML](https://toml.io) processor

Upstream source code can be found at [github.com/pennbauman/tq](https://github.com/pennbauman/tq), and the particular version used its included in the `src` folder.


## Build on Raspberry Pi Zero
Cross-Compilation isn't working but the binary can be built on the Raspberry Pi Zero.

### Install Rust

	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	source $HOME/.cargo/env

### Get Source Code
The code can also be downloaded from this repository

	git clone https://github.com/pennbauman/besic-relay.git
	cd besic-relay/tq/src

or from the upstream repository, and the correct version checked out.

	git clone https://github.com/pennbauman/tq.git
	cd tq
	git checkout 9acbd00279cc06c87765a7e391dadca6197eb50b

### Build

	cargo build --release
