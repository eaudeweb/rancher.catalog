version: '2'
volumes:
    es-data:
        driver: local
        per_container: true
services:
    es-master:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.container.hostname_override: container_name
            io.rancher.scheduler.affinity:host_label: ${host_labels}
        image: docker.elastic.co/elasticsearch/elasticsearch:5.6.9
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "ES_JAVA_OPTS=-Xms${master_heap_size} -Xmx${master_heap_size}"
            - "discovery.zen.ping.unicast.hosts=es-master"
            - "discovery.zen.minimum_master_nodes=${minimum_master_nodes}"
            - "node.master=true"
            - "node.data=false"
            - "http.enabled=false"
            - "TZ=${TZ}"
            - xpack.security.enabled=false
            - xpack.monitoring.enabled=false
            - xpack.ml.enabled=false
            - xpack.graph.enabled=false
            - xpack.watcher.enabled=false
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${master_mem_limit}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        volumes:
            - es-data:/usr/share/elasticsearch/data

    es-worker:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            io.rancher.container.hostname_override: container_name
        image: docker.elastic.co/elasticsearch/elasticsearch:5.6.9
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "discovery.zen.ping.unicast.hosts=es-master"
            - "ES_JAVA_OPTS=-Xms${data_heap_size} -Xmx${data_heap_size}"
            - "node.master=false"
            - "node.data=true"
            - "http.enabled=false"
            - "TZ=${TZ}"
            - xpack.security.enabled=false
            - xpack.monitoring.enabled=false
            - xpack.ml.enabled=false
            - xpack.graph.enabled=false
            - xpack.watcher.enabled=false
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${data_mem_limit}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        volumes:
            - es-data:/usr/share/elasticsearch/data
        depends_on:
            - es-master

    es-client:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            io.rancher.container.hostname_override: container_name
        image: docker.elastic.co/elasticsearch/elasticsearch:5.6.9
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "discovery.zen.ping.unicast.hosts=es-master"
            - "ES_JAVA_OPTS=-Xms${client_heap_size} -Xmx${client_heap_size}"
            - "node.master=false"
            - "node.data=false"
            - "http.enabled=true"
            - "TZ=${TZ}"
            - xpack.security.enabled=false
            - xpack.monitoring.enabled=false
            - xpack.ml.enabled=false
            - xpack.graph.enabled=false
            - xpack.watcher.enabled=false
    {{- if (.Values.ES_CLIENT_PORT)}}
        ports:
            - "${ES_CLIENT_PORT}:9200"
    {{- end}}
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${client_mem_limit}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        volumes:
            - es-data:/usr/share/elasticsearch/data
        depends_on:
            - es-master

    cerebro:
        image: eeacms/cerebro:0.7.3 
        depends_on:
            - es_client
       {{- if (.Values.CEREBRO_PORT)}}
        ports:
            - "${CEREBRO_PORT}:9000"
       {{- end}}
        environment:
            - CER_ES_URL=http://es-client:9200
            - "TZ=${TZ}"
        labels:
          io.rancher.container.hostname_override: container_name
          io.rancher.scheduler.affinity:host_label: ${host_labels}

    kibana:
        image: docker.elastic.co/kibana/kibana:5.6.9
        depends_on:
            - es_client
       {{- if (.Values.KIBANA_PORT)}}
        ports:
            - "${KIBANA_PORT}:5601"
       {{- end}}
        labels:
          io.rancher.container.hostname_override: container_name
          io.rancher.scheduler.affinity:host_label: ${host_labels}
        environment:
            - ELASTICSEARCH_URL=http://es-client:9200
            - "TZ=${TZ}"
            - "xpack.security.enabled=false"
            - "xpack.monitoring.enabled=false"
            - "xpack.ml.enabled=false"
            - "xpack.graph.enabled=false"
            - "xpack.watcher.enabled=false"

    es-sysctl:
        labels:
            io.rancher.scheduler.global: 'true'
            io.rancher.scheduler.affinity:host_label: ${host_labels}
            io.rancher.container.start_once: false
        image: rawmind/alpine-sysctl:0.1
        network_mode: none
        privileged: true
        environment:
            - "SYSCTL_KEY=vm.max_map_count"
            - "SYSCTL_VALUE=262144"
            - "KEEP_ALIVE=1"
