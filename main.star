postgres_module = import_module("github.com/kurtosis-tech/postgres-package/main.star")

INDEXER_IMAGE_NAME = "mysten/sui-indexer:13f89b7b8bbb0a75ff84615623ee79abb6a31228"
SUI_NODE_IMAGE = "mysten/sui-node:13f89b7b8bbb0a75ff84615623ee79abb6a31228"
POSTGRES_IMAGE = "postgres:15"

RUST_IMAGE = "rust:slim"
RUST_SERVICE_NAME = "rust-diesel-runner"

def run(plan, args):

    postgres_output = postgres_module.run(plan, {"image": POSTGRES_IMAGE, "user": "postgres", "password": "admin", "database": "sui_indexer_testnet"})

    config_and_genesis = plan.upload_files("github.com/kurtosis-tech/sui-package/static_files/node_config")
    cloner = plan.upload_files("github.com/kurtosis-tech/sui-package/static_files/cloner.sh")

    plan.add_service(
        name = RUST_SERVICE_NAME,
        config = ServiceConfig(
            image = RUST_IMAGE,
            entrypoint = ["tail", "-f", "/dev/null"],
            files = {
                "/tmp/cloner": cloner
            }
        )
    )

    # 1. Get rust up
    plan.exec(
        service_name = RUST_SERVICE_NAME,
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c", "apt update && apt install git libpq-dev -y"]
        )
    )

    plan.exec(
        service_name = RUST_SERVICE_NAME,
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c", "cd /tmp && /tmp/cloner/cloner.sh https://github.com/MystenLabs/sui.git"]
        )
    )

    plan.exec(
        service_name = RUST_SERVICE_NAME,
        recipe = ExecRecipe(
            command = ["cargo", "install", "diesel_cli", "--no-default-features", "--features", "postgres"]
        )
    )

    plan.exec(
        service_name = RUST_SERVICE_NAME,
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c", "cd /tmp/sui/crates/sui-indexer && diesel setup --database-url=\"{0}\"".format(postgres_output.url)]
        )
    )
    
    fullnode = plan.add_service(
        name = "sui-node",
        config = ServiceConfig(
            image = SUI_NODE_IMAGE,
            env_vars = {
                "RUST_LOG": "info",
                "RUST_JSON_LOG": "true",
            },
            ports = {
                "json-rpc": PortSpec(number = 9000, transport_protocol="TCP"),
                "metrics": PortSpec(number = 9184, transport_protocol="TCP"),
                "udp": PortSpec(number=8084, transport_protocol="UDP")
            },
            files =  {
                "/tmp/config": config_and_genesis
            },
            cmd = ["/usr/local/bin/sui-node", "--config-path", "/tmp/config/fullnode.yml"]
        )
    )
    fullnode_rpc_url = "http://{0}:9000".format(fullnode.hostname)

    plan.add_service(
        name = "sui-indexer",
        config = ServiceConfig(
            image = INDEXER_IMAGE_NAME,
            env_vars = {
                "RUST_LOG": "info",
                "RUST_JSON_LOG": "true",
                "DATABASE_URL": postgres_output.url,
                "RPC_CLIENT_URL": fullnode_rpc_url
            },
            ports = {
                "rpc": PortSpec(number= 9000, transport_protocol= "TCP"),
                "metircs": PortSpec(number = 9184, transport_protocol="TCP")
            },
            cmd = ["/usr/local/bin/sui-indexer", "--db-url", postgres_output.url, "--rpc-client-url", fullnode_rpc_url]
        )
    )