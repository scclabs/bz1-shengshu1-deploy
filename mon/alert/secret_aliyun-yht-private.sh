#/bin/bash

kubectl create secret docker-registry aliyun-yht-private \
    --docker-server=https://registry.cn-beijing.aliyuncs.com \
    --docker-username=yhtangio \
    --docker-password=fjkag42376G,akjh \
    --docker-email=myemail@example.com \
    -n mon