# linode/bbgo-grid-usdttwd.sh by c9s
# id: 793380
# description: BBGO grid trading on USDT/TWD market.

This StackScript helps you create a new personal node with bbgo installed.

Register your MAX Exchange account at:
https://max.maicoin.com/signup?r=c7982718

Create your API Key at:
https://max.maicoin.com/api_tokens

To trade on TWD markets, you need to pass the level 2 identity verification.


To check the BBGO logs, run:

    journalctl -xe -u bbgo

To stop the BBGO process:

    systemctl stop bbgo

To retsart the BBGO process:

    systemctl restart bbgo

# defined fields: name-max_api_key-label-max-api-key-name-max_api_secret-label-max-secret-key-name-lower_price-label-lower-price-of-the-grid-band-default-280-example-280-name-upper_price-label-upper-price-of-the-grid-band-default-290-example-290-name-grid_number-label-number-of-grids-10-grids-means-you-will-place-10-orders-default-50-example-50-name-quantity-label-quantity-how-much-usdt-quantity-for-each-grid-total-capital-grid-quantity-default-1000-example-100-name-profit_spread-label-profit-spread-the-price-spread-for-the-arbitrage-order-default-01-example-01-name-side-label-initial-grid-side-buy-only-sell-only-or-both-default-both-oneof-buysellboth-name-catch_up-label-catch-up-price-place-buy-orders-with-higher-price-if-price-raises-place-sell-orders-with-lower-price-if-price-drops-default-false-oneof-truefalse-name-long-label-keep-profit-in-the-base-asset-earn-usdt-default-true-oneof-truefalse
# images: ['linode/ubuntu20.04', 'linode/ubuntu18.04']
# stats: Used By: 2 + AllTime: 77
#!/bin/bash
#<UDF name="max_api_key" label="MAX API Key"/>
# MAX_API_KEY=
#
#<UDF name="max_api_secret" label="MAX Secret Key"/>
# MAX_API_SECRET=
#
#<UDF name="lower_price" label="Lower price of the grid band" default="28.0" example="28.0" />
# LOWER_PRICE=
#
#<UDF name="upper_price" label="Upper price of the grid band" default="29.0" example="29.0" />
# UPPER_PRICE=
#
#<UDF name="grid_number" label="Number of Grids (10 Grids means you will place 10 orders)" default="50" example="50"/>
# GRID_NUMBER=
#
#<UDF name="quantity" label="Quantity (How much USDT quantity for each grid, Total Capital = Grid * Quantity)" default="100.0" example="10.0"/>
# QUANTITY=
#
#<UDF name="profit_spread" label="Profit Spread (The price spread for the arbitrage order)" default="0.1" example="0.1"/>
# PROFIT_SPREAD=
#
#<UDF name="side" label="Initial grid side (Buy only, Sell only or Both)" default="both" oneof="buy,sell,both"/>
# SIDE=
#
#<UDF name="catch_up" label="Catch up price (place buy orders with higher price if price raises, place sell orders with lower price if price drops)" default="false" oneof="true,false"/>
# CATCH_UP=
#
#<UDF name="long" label="Keep profit in the base asset (earn USDT)" default="true" oneof="true,false"/>
# LONG=
set -e
osf=$(uname | tr '[:upper:]' '[:lower:]')
version=v1.21.1
dist_file=bbgo-$version-$osf-amd64.tar.gz

apt-get update
apt-get install -y redis-server

curl -O -L https://github.com/c9s/bbgo/releases/download/$version/$dist_file
tar xzf $dist_file
mv bbgo-$osf-amd64 bbgo
chmod +x bbgo
mv bbgo /usr/local/bin/bbgo

useradd --create-home -g users -s /usr/bin/bash bbgo
cd /home/bbgo

cat <<END > .env.local
export MAX_API_KEY=$MAX_API_KEY
export MAX_API_SECRET=$MAX_API_SECRET
END

cat <<END > /etc/systemd/system/bbgo.service
[Unit]
Description=bbgo trading bot
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
WorkingDirectory=/home/bbgo
# EnvironmentFile=/home/bbgo/envvars
ExecStart=/usr/local/bin/bbgo run --enable-webserver
KillMode=process
User=bbgo
Restart=always
RestartSec=10
END

cat <<END > bbgo.yaml
---
persistence:
  json:
    directory: var/data
  redis:
    host: 127.0.0.1
    port: 6379
    db: 0

exchangeStrategies:
- on: max
  grid:
    symbol: USDTTWD
    quantity: $QUANTITY
    gridNumber: $GRID_NUMBER
    profitSpread: $PROFIT_SPREAD
    upperPrice: $UPPER_PRICE
    lowerPrice: $LOWER_PRICE
    side: $SIDE
    long: $LONG
    catchUp: $CATCH_UP
    persistence:
      type: redis
      store: main
END

systemctl daemon-reload
systemctl enable bbgo.service
systemctl start bbgo
