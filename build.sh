# build image
docker build -t defcoin-node-docker --build-arg DEFCOIN_VERSION=75d804cdf4c13bd64814863fd19210b57ac0d67a .

# publish
#docker push coinfoundry/miningcore-docker
