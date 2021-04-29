### Build Command
```shell
docker build \
    --progress plain \
    -t ${REGISTRY}/denodo/vdp:8.0 \
    --build-arg BASE_REGISTRY=${REGISTRY} \
    .
```

### Run Command
```shell
docker run --init -it --rm \
    --name denodo-vdp  \
    -h denodo-vdp \
    --network denodo \
    -v denodo-vdp-data:/opt/denodo/metadata/db \
    -p 7998:7998 \
    -p 7999:7999 \
    -p 8000:8000 \
    -p 8998:8998 \
    -p 8999:8999 \
    -p 9000:9000 \
    -p 9090:9090 \
    -p 9097:9097 \
    -p 9098:9098 \
    -p 9099:9099 \
    -p 9995:9995 \
    -p 9996:9996 \
    -p 9997:9997 \
    -p 9998:9998 \
    -p 9999:9999 \
    -p 10091:10091 \
    --add-host='denodo.example.org:127.0.0.1' \
    -e DENODO_LICENSE_SERVER=denodo-solman \
    -e DENODO_HOSTNAME=denodo.example.org \
    ${REGISTRY}/denodo/vdp:8.0
```

### Run SSL Command
```shell
# Having to do all of this to generate a valid key and trust store.
# Just having a self signed key store does not work.
openssl genrsa -out ca.key 2048 && \
openssl req -x509 -new -nodes -key ca.key -subj '/CN=ca' -sha256 -days 365 -out ca.pem && \
openssl genrsa -out localhost.key 2048 && \
openssl req -new -key localhost.key -subj '/CN=localhost' -out localhost.csr && \
openssl x509 -req -in localhost.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out localhost.pem -days 365 -sha256 && \
openssl pkcs12 -export -name localhost -in localhost.pem -inkey localhost.key -out localhost.p12 -passout pass:changeit && \
keytool -importkeystore -srckeystore localhost.p12 -srcstoretype PKCS12 -srcstorepass changeit -deststorepass changeit -destkeystore keystore.jks -deststoretype JKS && \
keytool -importcert -file ca.pem -keystore truststore.jks -alias "ca" -storepass changeit -noprompt -storetype JKS && \
rm -f localhost.* ca.*

docker run --init -it --rm \
    --name denodo-vdp  \
    -h localhost \
    -v $(pwd)/keystore.jks:/opt/denodo/conf/keystore.jks \
    -v $(pwd)/truststore.jks:/opt/denodo/conf/truststore.jks \
    -v $(pwd)/denodo.lic:/opt/denodo/conf/denodo.lic \
    -v denodo-vdp-data:/opt/denodo/metadata/db \
    -p 7998:7998 \
    -p 7999:7999 \
    -p 8000:8000 \
    -p 8998:8998 \
    -p 8999:8999 \
    -p 9000:9000 \
    -p 9097:9097 \
    -p 9098:9098 \
    -p 9099:9099 \
    -p 9443:9443 \
    -p 9995:9995 \
    -p 9996:9996 \
    -p 9997:9997 \
    -p 9998:9998 \
    -p 9999:9999 \
    -p 10091:10091 \
    -e DENODO_SSL_ENABLED=true \
    -e DENODO_SSL_KEYSTORE=/opt/denodo/conf/keystore.jks \
    -e DENODO_SSL_KEYSTORE_PASSWORD=changeit \
    -e DENODO_SSL_TRUSTSTORE=/opt/denodo/conf/truststore.jks \
    -e DENODO_SSL_TRUSTSTORE_PASSWORD=changeit \
    ${REGISTRY}/denodo/vdp:8.0
```

### Environment Variables
| Variable Name | Description | Default Value |
| --- | --- | --- |
| DENODO_HOSTNAME | This must be set to the external hostname your accessing VDP at. See gotcha below. | localhost |
| DENODO_SSL_ENABLED | | None |
| DENODO_SSL_KEYSTORE | | None |
| DENODO_SSL_KEYSTORE_PASSWORD | | None |
| DENODO_SSL_TRUSTSTORE | | None |
| DENODO_SSL_TRUSTSTORE_PASSWORD | | None |

### Virtual DataPort Default Ports
| Server | Default Port |
| --- | --- |
| Server ports (for Virtual DataPort administration tools and JDBC clients) | 9999 |
| ODBC port | 9996 |
| Monitoring ports (JMX) | Primary port: 9997 (the JMX connection is established with this port)<br /><br /> Secondary port: 9995 |
| Shutdown port (only reachable from localhost) | 9998 |

### Scheduler Server Default Ports
| Server | Default Port |
| --- | --- |
| Server ports | 8000 and 7998 |
| Shutdown port (only reachable from localhost) | 7999 |

### Scheduler Index Server Default Ports
| Server | Default Port |
| --- | --- |
| Server ports | 9000 and 8998 |
| Shutdown port (only reachable from localhost) | 8999 |

### Denodo Platform Web container (Scheduler and ITPilot Administration Tools, Virtual DataPort Web services, Data Catalog and Diagnostic & Monitoring Tool) Default Ports
| Server | Default Port |
| --- | --- |
| Web container port | 9090 for HTTP connections<br /><br /> 9443 for HTTPS connections |
| Shutdown port (only reachable from localhost) | 9099 |
| Monitoring ports (JMX) | 9098 and 9097 |

### Denodo URLs
| Service | URL |
| --- | --- |
| Design Studio | HTTP: http://localhost:9090/denodo-design-studio/ <br /> HTTPS: https://localhost:9443/denodo-design-studio/ |
| Scheduler Admin | HTTP: http://localhost:9090/webadmin/denodo-scheduler-admin <br /> HTTPS: http://localhost:9443/webadmin/denodo-scheduler-admin |
| Data Catalog | HTTP: http://localhost:9090/denodo-data-catalog <br /> HTTPS: http://localhost:9443/denodo-data-catalog |
| Diagnostic & Monitoring Tool | HTTP: http://localhost:9090/diagnostic-monitoring-tool <br /> HTTPS: http://localhost:9443/diagnostic-monitoring-tool

### Gotchas
Something that will trip you up is how Denodo uses it's hostname. Denodo takes advantage of Java RMI(Remote Method Invocation). RMI has a nasty querk that it only will respond if your request came to the hostname it was expecting. To make sure both internal and external communication works to VDP you need to make sure that you set the ```DENODO_HOSTNAME``` and container hostname to the exact same value as your external connection. So if for example Dendodo is behind a load balancer and the URL is ```denodo.example.org``` then both ```DENODO_HOSTNAME``` and the containers hostname must be ```denodo.example.org``` for everything to work the way your expecting.