# Mithril Docker

This repo contains instructions for building a mithril signer node and a relay that acts as a proxy for obscuring the signer's requests to the mithril aggregator.

Make sure you've read the official manual first: https://mithril.network/doc/manual/getting-started/run-signer-node

## Mithril Signer

As of today, Mithril depends on the `cardano-cli` to communicate with the block producing node. While the IOG team is [refactoring](https://github.com/input-output-hk/mithril/issues/1315) towards [pallas](https://github.com/txpipe/pallas), it currently leaves two possible approaches when using Docker.

* The `cardano-cli` and libraries are compiled (or copied) in the mithril container
* The mithril container executes the cardano node container to run `cardano-cli`

I opted for the latter and therefore installed Docker in the Mithril container.

In order to execute the cardano node container, the Docker socket of the host needs to be mounted at runtime.
Caution, this has security implications you must be aware of! Write access to the Docker socket means root privileges on the host! Please don't use this setup if you don't fully understand this.

Mithril hardcodes `/tmp` for outfiles when using `cardano-cli`. Since the cli lives in the container of the cardano node `/tmp` must be made accessible for Mithril.
This is solved by mounting a volume for `/tmp` in both containers.

Mithril also requires access to the cardano node's KES signing key, the operational certificate and the database files.

The following example shows how the Mithril container can be run next to a block producer node

```
docker run -d --restart=unless-stopped \
  --name mithril-signer \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v "/root/mithril-cardano-tmp:/tmp" \
  -v "/root/mithril:/mithril" \
  -v "/root/cardano-node_config/block-producer:/cardano_node" \
  -e PARTY_ID="pool1cpr59c88ps8499gtgegr3muhclr7dln35g9a3rqmv4dkxg9n3h8" \
  -e CARDANO_NODE_SOCKET_PATH="/cardano_node/node.socket" \
  -e KES_SECRET_KEY_PATH="/cardano_node/staking/pool-keys/kes.skey" \
  -e OPERATIONAL_CERTIFICATE_PATH="/cardano_node/staking/pool-keys/node.cert" \
  -e DB_DIRECTORY="/cardano_node/db" \
  -e CARDANO_CLI_PATH="/mithril/cardano-cli-proxy" \
  -e DATA_STORES_DIRECTORY="/mithril/store" \
  -e RELAY_ENDPOINT="http://relay01.lacepool.com:3132" \
  -e AGGREGATOR_ENDPOINT="https://aggregator.release-mainnet.api.mithril.network/aggregator" \
  -e ERA_READER_ADAPTER_PARAMS='{"address": "addr1qy72kwgm6kypyc5maw0h8mfagwag8wjnx6emgfnsnhqaml6gx7gg4tzplw9l32nsgclqax7stc4u6c5dn0ctljwscm2sqv0teg", "verification_key": "5b31312c3133342c3231352c37362c3134312c3232302c3131312c3135342c36332c3233302c3131342c31322c38372c37342c39342c3137322c3133322c32372c39362c3138362c3132362c3137382c31392c3131342c33302c3234332c36342c3134312c3131302c38332c38362c31395d"}' \
  lacepool/mithril-signer -vvvv
```

## Mithril Relay

As of today the relay is just a squid proxy, configured to forward requests from the signer to the aggregator.
The container needs to run on $RELAY_ENDPOINT and the firewall must be configured to allow traffic to the container from $BLOCKPRODUCER_IP on the defined port (e.g 3132).

```
docker run -itd --restart=unless-stopped \
  --name mithril-relay \
  -p 3132:3132 \
  -e BLOCKPRODUCER_IP="xx.xx.xx.xx" \
  lacepool/mithril-relay
```
