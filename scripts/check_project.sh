echo "############### Accessing Website to generate traffic ##############"
for i in range{1..3}: 
do
curl http://localhost:8080/ > /dev/null
done

echo "############### Checking Logs ##############"

echo "############### Nginx Access Logs ##############"
cat /home/utkarsh/Desktop/Project/CDAC/Project/logs/nginx-access.log

echo "############### Docker Compose Logs ##############"
docker compose logs --no-color logstash | tail -n 50

echo "############### Logstasg Status  ##############"
curl http://localhost:9600/_node/pipelines?pretty

echo "############### Checking Elastic Search Indexes ##############"

curl http://localhost:9200/_cat/indices?v


