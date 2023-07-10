postgres_module = import_module("github.com/kurtosis-tech/postgres-package/main.star")

INDEXER_IMAGE_NAME = "mysten/sui-indexer:ci"
SUI_NODE_IMAGE = "mysten/sui-node:ci"
POSTGRES_IMAGE = "postgres:15"

def run(plan, args):

    config_and_genesis = plan.upload_files("github.com/kurtosis-tech/sui-package/static_files")
    
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

    postgres_output = postgres_module.run(plan, {"image": POSTGRES_IMAGE, "user": "postgres", "password": "admin", "database": "sui_indexer_testnet"})

    plan.add_service(
        name = "indexer",
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