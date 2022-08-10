#!/bin/bash

echo ECS_CLUSTER=${ecs_cluster_name} >> /etc/ecs/ecs.config
echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config
echo ECS_INSTANCE_ATTRIBUTES=\'{\"instance_class\": \"${instance_class}\"}\' >> /etc/ecs/ecs.config
