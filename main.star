POSTGRES_IMAGE_NAME = "postgres:15"
INDEXER_IMAGE_NAME = "mysten/sui-indexer:latest"
SUI_NODE_IMAGE = "mysten/sui-node:ci"

def run(plan, args):

    config_and_genesis = plan.upload_files("github.com/kurtosis-tech/sui-package/static_files")
    
    plan.add_service(
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