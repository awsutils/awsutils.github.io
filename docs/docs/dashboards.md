---
sidebar_position: 3
---

# How to Use Dashboards

This guide explains how to use the CloudWatch dashboard provided in this repository.

## Prerequisites

- CloudWatch access: the viewer needs `cloudwatch:GetDashboard` and editors need `cloudwatch:PutDashboard`. If you use the CLI, also allow `cloudwatch:ListDashboards`.
- Metrics present: enable CloudWatch Container Insights for EKS/ECS and install the CloudWatch Agent on EC2/edge nodes so the CPU/memory/disk widgets populate. API Gateway, CloudFront, Lambda, and VPC Lattice widgets stay empty if those services are not in use.
- Region alignment: the JSON defaults to `us-east-1`. You can change the `region` variable at the top of the dashboard or bulk-search/replace the region string before importing.

## Import Options

1) **AWS Console (fastest)**
   - Open CloudWatch → Dashboards → `Create dashboard` → choose `Import dashboard`. 
   - Paste the JSON below, name it (e.g., `app-observability`), and click `Create dashboard`.

2) **AWS CLI**
   - Save the JSON in a file, e.g., `dashboard.json`.
   - Run:

```bash
aws cloudwatch put-dashboard \
  --dashboard-name app-observability \
  --dashboard-body file://dashboard.json
```

3) **Terraform (optional)**
   - Wrap the JSON string in a `aws_cloudwatch_dashboard` resource’s `dashboard_body`. Keep it compact with `jq -c` to avoid newline escaping.

## Variables & Customization

- **Region selector**: the `region` variable allows quick swaps between regions without editing every widget.
- **Namespace selector**: the `[EKS] Namespace` variable powers the Container Insights searches that currently use `Namespace=placeholder`. Set the dropdown to your namespace or replace `placeholder` in the JSON before import.
- **Alerts vs. dashboards**: this file is visualization-only; pair it with alarms (e.g., p99 latency, 5XX spikes, pod restarts) to get notifications.
- **Cost note**: Live data and 1-minute period widgets increase CloudWatch metric read costs. Increase `period` or disable `liveData` if you want cheaper, slower refreshes.

## Quick Start

### Apply Dashboard .json Directly

```json
{
  "variables": [
    {
      "type": "property",
      "property": "region",
      "inputType": "input",
      "id": "region",
      "label": "Region",
      "defaultValue": "us-east-1",
      "visible": true
    },
    {
      "type": "property",
      "property": "Namespace",
      "inputType": "select",
      "id": "Namespace",
      "label": "[EKS] Namespace",
      "defaultValue": "",
      "visible": true,
      "search": "{ContainerInsights,ClusterName,Namespace}",
      "populateFrom": "Namespace"
    }
  ],
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 6,
      "height": 5,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60)",
              "id": "alb_5xx",
              "label": "ALB 5XX",
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60)",
              "id": "nlb_5xx",
              "label": "NLB 5XX",
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApiGateway,ApiId,Stage} MetricName=\"5XXError\"', 'Sum', 60)",
              "id": "apigw_5xx",
              "label": "API GW 5XX",
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/CloudFront,DistributionId,Region} MetricName=\"5xxErrorRate\"', 'p99', 60)",
              "id": "cf_5xx_rate",
              "label": "CloudFront 5XX Rate (%)",
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/VpcLattice,Service,TargetGroup} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60)",
              "id": "lattice_5xx",
              "label": "Lattice 5XX",
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/Lambda,FunctionName} MetricName=\"Errors\"', 'Sum', 60)",
              "id": "lambda_errors",
              "region": "us-east-1",
              "label": "Lambda Errors"
            }
          ]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "title": "🚦 5XX Errors + Lambda Error Rate",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "stat": "p99"
      }
    },
    {
      "type": "metric",
      "x": 14,
      "y": 5,
      "width": 5,
      "height": 5,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,AvailabilityZone,TargetGroup} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60)",
              "id": "alb_5xx_az",
              "label": "ALB 5XX / AZ"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,AvailabilityZone} MetricName=\"HTTPCode_ELB_5XX_Count\"', 'Sum', 60)",
              "id": "alb_elb_5xx_az",
              "label": "ALB ELB 5XX / AZ",
              "color": "#d62728"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,AvailabilityZone} MetricName=\"HTTPCode_ELB_4XX_Count\"', 'Sum', 60)",
              "id": "alb_elb_4xx_az",
              "label": "ALB ELB 4XX / AZ",
              "color": "#ff7f0e"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer,AvailabilityZone,TargetGroup} MetricName=\"TargetConnectionErrorCount\"', 'Sum', 60)",
              "id": "nlb_err_az",
              "label": "NLB Conn Errors / AZ"
            }
          ]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "title": "ALB/NLB Error Count by AZ",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "stat": "Sum"
      }
    },
    {
      "type": "metric",
      "x": 19,
      "y": 5,
      "width": 5,
      "height": 5,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUUtilization\"', 'Maximum', 60)",
              "id": "ec2_cpu_util",
              "label": "EC2 CPU (%)"
            }
          ],
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace} MetricName=\"pod_cpu_utilization\"', 'p99', 60)",
              "id": "eks_pod_cpu",
              "label": "EKS Pod CPU (p99%)"
            }
          ],
          [
            {
              "expression": "SEARCH('{ECS/ContainerInsights,ClusterName,ServiceName,TaskId} MetricName=\"TaskCpuUtilization\"', 'p99', 60)",
              "id": "ecs_task_cpu",
              "label": "ECS Task CPU (p99%)"
            }
          ],
          [
            {
              "expression": "SEARCH('{CWAgent,InstanceId} MetricName=\"mem_used_percent\"', 'Average', 60)",
              "id": "ec2_mem_util",
              "label": "EC2 Mem (%)",
              "color": "#9467bd"
            }
          ],
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace} MetricName=\"pod_memory_utilization\"', 'p99', 60)",
              "id": "eks_pod_mem",
              "label": "EKS Pod Mem (p99%)",
              "color": "#8c564b"
            }
          ],
          [
            {
              "expression": "SEARCH('{ECS/ContainerInsights,ClusterName,ServiceName,TaskId} MetricName=\"TaskMemoryUtilization\"', 'p99', 60)",
              "id": "ecs_task_mem",
              "label": "ECS Task Mem (p99%)",
              "color": "#17becf"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Compute CPU & Memory Utilization (EC2 / EKS Pod / ECS Task)",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "stat": "Average",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Utilization (%)",
            "min": 0,
            "max": 100
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 5,
      "width": 4,
      "height": 5,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_2XX_Count\"', 'Sum', 60))",
              "id": "alb_2xx",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_3XX_Count\"', 'Sum', 60))",
              "id": "alb_3xx",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_4XX_Count\"', 'Sum', 60))",
              "id": "alb_4xx",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60))",
              "id": "alb_5xx_tot",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_4XX_Count\"', 'Sum', 60))",
              "id": "alb_elb_4xx",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_5XX_Count\"', 'Sum', 60))",
              "id": "alb_elb_5xx",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/VpcLattice,Service,TargetGroup} MetricName=\"HTTPCode_Target_2XX_Count\"', 'Sum', 60))",
              "id": "lattice_2xx",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/VpcLattice,Service,TargetGroup} MetricName=\"HTTPCode_Target_4XX_Count\"', 'Sum', 60))",
              "id": "lattice_4xx",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/VpcLattice,Service,TargetGroup} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60))",
              "id": "lattice_5xx_tot",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApiGateway,ApiId,Stage} MetricName=\"Count\"', 'Sum', 60))",
              "id": "apigw_count_tot",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApiGateway,ApiId,Stage} MetricName=\"4XXError\"', 'Sum', 60))",
              "id": "apigw_4xx",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApiGateway,ApiId,Stage} MetricName=\"5XXError\"', 'Sum', 60))",
              "id": "apigw_5xx_tot",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/CloudFront,DistributionId,Region} MetricName=\"Requests\"', 'Sum', 60))",
              "id": "cf_requests_tot",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "AVG(SEARCH('{AWS/CloudFront,DistributionId,Region} MetricName=\"4xxErrorRate\"', 'Average', 60))",
              "id": "cf_4xx_rate",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "AVG(SEARCH('{AWS/CloudFront,DistributionId,Region} MetricName=\"5xxErrorRate\"', 'Average', 60))",
              "id": "cf_5xx_rate",
              "region": "us-east-1",
              "visible": false
            }
          ],
          [
            {
              "expression": "cf_requests_tot*cf_4xx_rate/100",
              "id": "cf_4xx_cnt",
              "visible": false,
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "cf_requests_tot*cf_5xx_rate/100",
              "id": "cf_5xx_cnt",
              "visible": false,
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "cf_requests_tot - cf_4xx_cnt - cf_5xx_cnt",
              "id": "cf_2xx_cnt",
              "visible": false,
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "apigw_count_tot - apigw_4xx - apigw_5xx_tot",
              "id": "apigw_2xx_calc",
              "visible": false,
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "alb_5xx_tot + alb_elb_5xx + lattice_5xx_tot + apigw_5xx_tot + cf_5xx_cnt",
              "label": "5XX",
              "id": "total_5xx",
              "color": "#d62728",
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "alb_4xx + alb_elb_4xx + lattice_4xx + apigw_4xx + cf_4xx_cnt",
              "label": "4XX",
              "id": "total_4xx",
              "color": "#ff7f0e",
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "alb_3xx",
              "label": "3XX",
              "id": "total_3xx",
              "color": "#1f77b4",
              "region": "us-east-1"
            }
          ],
          [
            {
              "expression": "alb_2xx + lattice_2xx + apigw_2xx_calc + cf_2xx_cnt",
              "label": "2XX",
              "id": "total_2xx",
              "color": "#2ca02c",
              "region": "us-east-1"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "us-east-1",
        "title": "All Front Doors: HTTP Status Mix (Stacked)",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "stat": "Sum"
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 0,
      "width": 6,
      "height": 5,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"TargetResponseTime\"', 'p99', 60)*1000",
              "id": "alb_p99",
              "label": "ALB P99 (ms)"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer,TargetGroup} MetricName=\"TargetResponseTime\"', 'p99', 60)*1000",
              "id": "nlb_p99",
              "label": "NLB P99 (ms)"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApiGateway,ApiId,Stage} MetricName=\"Latency\"', 'p99', 60)",
              "id": "apigw_p99",
              "label": "API GW P99 (ms)"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/CloudFront,DistributionId,Region} MetricName=\"OriginLatency\"', 'p99', 60)",
              "id": "cf_p99",
              "label": "CloudFront P99 (ms)"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/VpcLattice,Service,TargetGroup} MetricName=\"RequestTime\"', 'p99', 60)",
              "id": "lattice_p99",
              "label": "Lattice P99 (ms)"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/Lambda,FunctionName} MetricName=\"Duration\"', 'p99', 60)",
              "id": "lambda_duration_p99",
              "label": "Lambda P99 (ms)"
            }
          ]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "title": "⚡ P99 Latency (CF/API GW/ALB/NLB/Lattice/Lambda)",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "stat": "p99"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 6,
      "height": 5,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HealthyHostCount\"', 'p99', 60)",
              "id": "alb_healthy",
              "label": "ALB Healthy"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"UnHealthyHostCount\"', 'p99', 60)",
              "id": "alb_unhealthy",
              "label": "ALB Unhealthy"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer,TargetGroup} MetricName=\"HealthyHostCount\"', 'p99', 60)",
              "id": "nlb_healthy",
              "label": "NLB Healthy"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer,TargetGroup} MetricName=\"UnHealthyHostCount\"', 'p99', 60)",
              "id": "nlb_unhealthy",
              "label": "NLB Unhealthy"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/VpcLattice,Service,TargetGroup} MetricName=\"HealthyHostCount\"', 'Average', 60)",
              "id": "lattice_healthy",
              "label": "Lattice Healthy"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/VpcLattice,Service,TargetGroup} MetricName=\"UnHealthyHostCount\"', 'Average', 60)",
              "id": "lattice_unhealthy",
              "label": "Lattice Unhealthy"
            }
          ]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "title": "🏥 Target Health Status (ALB, NLB, Lattice)",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "stat": "p99"
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 0,
      "width": 6,
      "height": 5,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"RequestCount\"', 'Sum', 60)",
              "id": "alb_req",
              "label": "ALB Requests"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer,TargetGroup} MetricName=\"NewFlowCount\"', 'Sum', 60)",
              "id": "nlb_flows",
              "label": "NLB New Flows"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApiGateway,ApiId,Stage} MetricName=\"Count\"', 'Sum', 60)",
              "id": "apigw_count",
              "label": "API GW Count"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/CloudFront,DistributionId,Region} MetricName=\"Requests\"', 'Sum', 60)",
              "id": "cf_requests",
              "label": "CloudFront Requests"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/VpcLattice,Service,TargetGroup} MetricName=\"RequestCount\"', 'Sum', 60)",
              "id": "lattice_req",
              "label": "Lattice Requests"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/Lambda,FunctionName} MetricName=\"Invocations\"', 'Sum', 60)",
              "id": "lambda_invocations",
              "label": "Lambda Invocations"
            }
          ]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "title": "📊 Traffic/Min (CF/API GW/ALB/NLB/Lattice/Lambda)",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "stat": "Sum"
      }
    },
    {
      "type": "metric",
      "x": 4,
      "y": 5,
      "width": 5,
      "height": 5,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,AvailabilityZone} MetricName=\"RequestCount\"', 'Sum', 60)",
              "id": "alb_req_az",
              "label": "ALB Requests / AZ"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer,AvailabilityZone} MetricName=\"NewFlowCount\"', 'Sum', 60)",
              "id": "nlb_flows_az",
              "label": "NLB New Flows / AZ"
            }
          ]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "title": "ALB/NLB Request Rate by AZ",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "stat": "Sum"
      }
    },
    {
      "type": "metric",
      "x": 9,
      "y": 5,
      "width": 5,
      "height": 5,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,AvailabilityZone} MetricName=\"TargetResponseTime\"', 'p99', 60)*1000",
              "id": "alb_lat_az_p99",
              "label": "ALB P99 / AZ (ms)"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer,AvailabilityZone} MetricName=\"TargetResponseTime\"', 'p99', 60)*1000",
              "id": "nlb_lat_az_p99",
              "label": "NLB P99 / AZ (ms)"
            }
          ]
        ],
        "view": "timeSeries",
        "region": "us-east-1",
        "title": "ALB/NLB P99 Latency by AZ",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "stat": "p99"
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 10,
      "width": 24,
      "height": 1,
      "properties": {
        "markdown": "## 🐳 Container & Orchestration Metrics"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 11,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,ContainerName,FullPodName,Namespace,PodName} Namespace=placeholder MetricName=\"container_cpu_utilization_over_container_limit\"', 'p99', 60)",
              "id": "cpu_p99",
              "label": "P99"
            }
          ],
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,ContainerName,FullPodName,Namespace,PodName} Namespace=placeholder MetricName=\"container_cpu_utilization_over_container_limit\"', 'p99', 60)",
              "id": "cpu_avg",
              "label": "p99"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "CPU Utilization (%)",
            "min": 0,
            "max": 100
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Warning",
              "value": 80,
              "fill": "above",
              "color": "#ff7f0e"
            },
            {
              "label": "Critical",
              "value": 90,
              "fill": "above",
              "color": "#d62728"
            }
          ]
        },
        "title": "[EKS] Container CPU Utilization"
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 11,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,ContainerName,FullPodName,Namespace,PodName} Namespace=placeholder MetricName=\"container_memory_utilization_over_container_limit\"', 'p99', 60)*100",
              "id": "mem_p99",
              "label": "P99"
            }
          ],
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,ContainerName,FullPodName,Namespace,PodName} Namespace=placeholder MetricName=\"container_memory_utilization_over_container_limit\"', 'p99', 60)",
              "id": "mem_avg",
              "label": "p99"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "min": 0,
            "showUnits": false,
            "label": "Memory Utilization (%)",
            "max": 100
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Warning",
              "value": 80,
              "fill": "above",
              "color": "#ff7f0e"
            },
            {
              "label": "Critical",
              "value": 90,
              "fill": "above",
              "color": "#d62728"
            }
          ]
        },
        "title": "[EKS] Container Memory Utilization"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 11,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace} Namespace=placeholder MetricName=\"pod_number_of_container_restarts\"', 'Sum', 300)",
              "id": "restarts",
              "label": "Container Restarts"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 300,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "label": "Restart Count",
            "min": 0
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Alert Threshold",
              "value": 5,
              "fill": "above",
              "color": "#d62728"
            }
          ]
        },
        "title": "[EKS] Pod Restart Events (5m)"
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 11,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace} Namespace=placeholder MetricName=\"pod_cpu_utilization\"', 'p99', 60)",
              "id": "pod_cpu",
              "label": "Pod CPU Usage"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "label": "CPU Utilization (%)",
            "min": 0
          }
        },
        "title": "[EKS] Pod CPU Utilization"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 17,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ECS/ContainerInsights,ClusterName,ServiceName,TaskId} MetricName=\"TaskCpuUtilization\"', 'p99', 60)",
              "id": "task_cpu_p99",
              "label": "P99"
            }
          ],
          [
            {
              "expression": "SEARCH('{ECS/ContainerInsights,ClusterName,ServiceName,TaskId} MetricName=\"TaskCpuUtilization\"', 'p99', 60)",
              "id": "task_cpu_avg",
              "label": "p99"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "[ECS] Task CPU Utilization",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "CPU Utilization (%)",
            "min": 0,
            "max": 100
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Warning",
              "value": 80,
              "fill": "above",
              "color": "#ff7f0e"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 17,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ECS/ContainerInsights,ClusterName,ServiceName,TaskId} MetricName=\"TaskMemoryUtilization\"', 'p99', 60)",
              "id": "task_mem_p99",
              "label": "P99"
            }
          ],
          [
            {
              "expression": "SEARCH('{ECS/ContainerInsights,ClusterName,ServiceName,TaskId} MetricName=\"TaskMemoryUtilization\"', 'p99', 60)",
              "id": "task_mem_avg",
              "label": "p99"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "[ECS] Task Memory Utilization",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Memory Utilization (%)",
            "min": 0,
            "max": 100
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Warning",
              "value": 80,
              "fill": "above",
              "color": "#ff7f0e"
            },
            {
              "label": "Critical",
              "value": 100,
              "color": "#d62728"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 17,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ECS/ManagedScaling,CapacityProviderName,ClusterName} MetricName=\"CapacityProviderReservation\"', 'Maximum', 60)",
              "id": "capacity_reservation"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "title": "[ECS] Capacity Provider Reservation",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Reservation (%)",
            "min": 0,
            "max": 200
          }
        },
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Target",
              "value": 100,
              "color": "#2ca02c"
            },
            {
              "label": "Over-provisioned",
              "value": 150,
              "fill": "above",
              "color": "#ff7f0e"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 23,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_cpu_utilization\"', 'p99', 60)",
              "id": "node_cpu_p99",
              "label": "P99"
            }
          ],
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_cpu_utilization\"', 'p99', 60)",
              "id": "node_cpu_avg",
              "label": "p99"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "yAxis": {
          "left": {
            "label": "CPU Utilization (%)",
            "min": 0,
            "max": 100
          }
        },
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Warning",
              "value": 75,
              "fill": "above",
              "color": "#ff7f0e"
            },
            {
              "label": "Critical",
              "value": 90,
              "fill": "above",
              "color": "#d62728"
            }
          ]
        },
        "title": "Node CPU Utilization"
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 23,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_memory_utilization\"', 'p99', 60)",
              "id": "node_mem_p99",
              "label": "P99"
            }
          ],
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_memory_utilization\"', 'p99', 60)",
              "id": "node_mem_avg",
              "label": "p99"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "yAxis": {
          "left": {
            "label": "Memory Utilization (%)",
            "min": 0,
            "max": 100
          }
        },
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Warning",
              "value": 80,
              "fill": "above",
              "color": "#ff7f0e"
            },
            {
              "label": "Critical",
              "value": 90,
              "fill": "above",
              "color": "#d62728"
            }
          ]
        },
        "title": "Node Memory Utilization"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 23,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_filesystem_utilization\"', 'Maximum', 60)",
              "id": "node_disk"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Maximum",
        "period": 60,
        "yAxis": {
          "left": {
            "label": "Disk Utilization (%)",
            "min": 0,
            "max": 100
          }
        },
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Warning",
              "value": 80,
              "fill": "above",
              "color": "#ff7f0e"
            },
            {
              "label": "Critical",
              "value": 90,
              "fill": "above",
              "color": "#d62728"
            }
          ]
        },
        "title": "Node Disk Utilization"
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 23,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_network_total_bytes\"', 'Sum', 60)/1024/1024",
              "id": "network_total",
              "label": "Total Network (MB)"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "yAxis": {
          "left": {
            "label": "Network Traffic (MB)",
            "min": 0
          }
        },
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "Node Network Traffic"
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 29,
      "width": 24,
      "height": 1,
      "properties": {
        "markdown": "## 🌐 Load Balancer & API Gateway Metrics"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 30,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"RequestCount\"', 'Sum', 60)",
              "id": "alb_requests"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "ALB Request Count",
        "yAxis": {
          "left": {
            "min": 0,
            "label": "Requests",
            "showUnits": false
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 30,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"UnHealthyHostCount\"', 'Maximum', 60))",
              "label": "Unhealthy",
              "id": "unhealthy",
              "color": "#d62728"
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HealthyHostCount\"', 'Maximum', 60))",
              "label": "Healthy",
              "id": "healthy",
              "color": "#2ca02c"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "title": "ALB Target Health",
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 30,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"TargetResponseTime\"', 'p99', 60)*1000",
              "id": "latency_avg",
              "label": "p99"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"TargetResponseTime\"', 'p50', 60)*1000",
              "id": "latency_p50",
              "label": "P50"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"TargetResponseTime\"', 'p99', 60)*1000",
              "id": "latency_p99",
              "label": "P99"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "ALB Response Time",
        "yAxis": {
          "left": {
            "min": 0,
            "label": "Latency (ms)",
            "showUnits": false
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "SLA Target",
              "value": 500,
              "fill": "above",
              "color": "#ff7f0e"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 30,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"ActiveConnectionCount\"', 'Sum', 60)",
              "id": "active_connections",
              "label": "Active Connections"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"NewConnectionCount\"', 'Sum', 60)",
              "id": "new_connections",
              "label": "New Connections"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "title": "ALB Connection Metrics",
        "yAxis": {
          "left": {
            "min": 0,
            "label": "Connections"
          }
        },
        "liveData": true
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 36,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_2XX_Count\"', 'Sum', 60)",
              "label": "2XX",
              "id": "status_2xx",
              "color": "#2ca02c"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_3XX_Count\"', 'Sum', 60)",
              "label": "3XX",
              "id": "status_3xx",
              "color": "#1f77b4"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_4XX_Count\"', 'Sum', 60)",
              "label": "4XX",
              "id": "status_4xx",
              "color": "#ff7f0e"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_Target_5XX_Count\"', 'Sum', 60)",
              "label": "5XX",
              "id": "status_5xx",
              "color": "#d62728"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "label": "Request Count",
            "showUnits": false,
            "min": 0
          }
        },
        "title": "ALB HTTP Status Codes"
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 36,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_ELB_5XX_Count\"', 'Sum', 60)",
              "label": "ELB 5XX",
              "id": "elb_5xx",
              "color": "#d62728"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"HTTPCode_ELB_4XX_Count\"', 'Sum', 60)",
              "label": "ELB 4XX",
              "id": "elb_4xx",
              "color": "#ff7f0e"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"RejectedConnectionCount\"', 'Sum', 60)",
              "label": "Rejected Connections",
              "id": "rejected",
              "color": "#8c564b"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "label": "Error Count",
            "showUnits": false,
            "min": 0
          }
        },
        "title": "ALB Error Metrics"
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 36,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"TargetConnectionErrorCount\"', 'Sum', 60)",
              "label": "Connection Errors",
              "id": "conn_errors"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApplicationELB,LoadBalancer,TargetGroup} MetricName=\"TargetTLSNegotiationErrorCount\"', 'Sum', 60)",
              "label": "TLS Errors",
              "id": "tls_errors"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "label": "Error Count",
            "showUnits": false,
            "min": 0
          }
        },
        "title": "ALB Target Errors"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 42,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer} MetricName=\"ProcessedPackets\"', 'Sum', 60)",
              "id": "nlb_packets"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "title": "NLB Processed Packets",
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "label": "Packets",
            "showUnits": false,
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 42,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SUM(SEARCH('{AWS/NetworkELB,LoadBalancer,TargetGroup} MetricName=\"UnHealthyHostCount\"', 'Maximum', 60))",
              "label": "Unhealthy",
              "id": "nlb_unhealthy",
              "color": "#d62728"
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/NetworkELB,LoadBalancer,TargetGroup} MetricName=\"HealthyHostCount\"', 'Maximum', 60))",
              "label": "Healthy",
              "id": "nlb_healthy",
              "color": "#2ca02c"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "title": "NLB Target Health",
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 42,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer} MetricName=\"ActiveFlowCount\"', 'p99', 60)",
              "id": "active_flows",
              "label": "Active Flows"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/NetworkELB,LoadBalancer} MetricName=\"NewFlowCount\"', 'Sum', 60)",
              "id": "new_flows",
              "label": "New Flows"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "title": "NLB Flow Metrics",
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "min": 0,
            "label": "Flow Count"
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 48,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApiGateway,ApiName,Method,Resource,Stage} MetricName=\"Count\"', 'Sum', 60)",
              "id": "api_requests"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "showUnits": false,
            "min": 0,
            "label": "Request Count"
          }
        },
        "title": "API Gateway Requests"
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 48,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApiGateway,ApiName,Method,Resource,Stage} MetricName=\"Latency\"', 'p99', 60)",
              "label": "p99",
              "id": "api_lat_avg"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/ApiGateway,ApiName,Method,Resource,Stage} MetricName=\"Latency\"', 'p99', 60)",
              "label": "P99",
              "id": "api_lat_p99"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "min": 0,
            "label": "Latency (ms)",
            "showUnits": false
          }
        },
        "title": "API Gateway Latency",
        "annotations": {
          "horizontal": [
            {
              "label": "SLA Target",
              "value": 1000,
              "fill": "above",
              "color": "#ff7f0e"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 48,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApiGateway,ApiName,Method,Resource,Stage} MetricName=\"4XXError\"', 'Sum', 60)",
              "id": "api_4xx",
              "label": "4XX Errors"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "API Gateway 4XX Errors",
        "stat": "Sum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Error Count",
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 48,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/ApiGateway,ApiName,Method,Resource,Stage} MetricName=\"5XXError\"', 'Sum', 60)",
              "id": "api_5xx",
              "label": "5XX Errors"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "API Gateway 5XX Errors",
        "stat": "Sum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Error Count",
            "min": 0
          }
        }
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 54,
      "width": 24,
      "height": 1,
      "properties": {
        "markdown": "## ☁️ CloudFront & VPC Lattice"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 55,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/CloudFront,DistributionId,Region,Region} MetricName=\"Requests\"', 'Sum', 60)",
              "id": "cf_requests"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "CloudFront Requests",
        "stat": "Sum",
        "period": 60,
        "yAxis": {
          "left": {
            "label": "Requests",
            "min": 0,
            "showUnits": false
          }
        },
        "liveData": true
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 55,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/CloudFront,DistributionId,Region,Region} MetricName=\"BytesDownloaded\"', 'Sum', 60)/1024/1024",
              "id": "cf_bytes_down",
              "label": "Downloaded (MB)"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/CloudFront,DistributionId,Region,Region} MetricName=\"BytesUploaded\"', 'Sum', 60)/1024/1024",
              "id": "cf_bytes_up",
              "label": "Uploaded (MB)"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "CloudFront Bandwidth",
        "stat": "Sum",
        "period": 60,
        "yAxis": {
          "left": {
            "label": "Data Transfer (MB)",
            "min": 0,
            "showUnits": false
          }
        },
        "liveData": true
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 55,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/CloudFront,DistributionId,Region,Region} MetricName=\"4xxErrorRate\"', 'p99', 60)",
              "id": "cf_4xx"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "CloudFront 4XX Error Rate",
        "stat": "p99",
        "period": 60,
        "yAxis": {
          "left": {
            "label": "Error Rate (%)",
            "min": 0,
            "showUnits": false,
            "max": 100
          }
        },
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Alert Threshold",
              "value": 5,
              "fill": "above",
              "color": "#ff7f0e"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 55,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/CloudFront,DistributionId,Region,Region} MetricName=\"5xxErrorRate\"', 'p99', 60)",
              "id": "cf_5xx"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "CloudFront 5XX Error Rate",
        "stat": "p99",
        "period": 60,
        "yAxis": {
          "left": {
            "label": "Error Rate (%)",
            "min": 0,
            "showUnits": false,
            "max": 100
          }
        },
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Alert Threshold",
              "value": 1,
              "fill": "above",
              "color": "#d62728"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 61,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/CloudFront,DistributionId,Region,Region} MetricName=\"CacheHitRate\"', 'p99', 60)",
              "id": "cache_hit"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "CloudFront Cache Hit Rate",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "label": "Hit Rate (%)",
            "min": 0,
            "max": 100,
            "showUnits": false
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Target",
              "value": 80,
              "color": "#2ca02c"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 61,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SUM(SEARCH('{AWS/VpcLattice,AvailabilityZone,Service} MetricName=\"TotalRequestCount\"', 'Sum', 60))",
              "id": "lattice_requests"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "title": "VPC Lattice Requests",
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "showUnits": false,
            "min": 0,
            "label": "Requests"
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 61,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SUM(SEARCH('{AWS/VpcLattice,AvailabilityZone,Service} MetricName=\"RequestTime\"', 'p99', 60))",
              "label": "p99",
              "id": "lattice_lat_avg"
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/VpcLattice,AvailabilityZone,Service} MetricName=\"RequestTime\"', 'p99', 60))",
              "label": "P99",
              "id": "lattice_lat_p99"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "title": "VPC Lattice Latency",
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "showUnits": false,
            "min": 0,
            "label": "Latency (ms)"
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 61,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SUM(SEARCH('{AWS/VpcLattice,AvailabilityZone,Service} MetricName=\"HTTPCode_4XX_Count\"', 'Sum', 60))",
              "id": "lattice_4xx",
              "label": "4XX",
              "color": "#ff7f0e"
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/VpcLattice,AvailabilityZone,Service} MetricName=\"HTTPCode_5XX_Count\"', 'Sum', 60))",
              "id": "lattice_5xx",
              "label": "5XX",
              "color": "#d62728"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "us-east-1",
        "stat": "Sum",
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Error Count",
            "min": 0
          }
        },
        "title": "VPC Lattice Errors",
        "period": 60
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 67,
      "width": 24,
      "height": 1,
      "properties": {
        "markdown": "## 💾 Database & Storage Metrics"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 68,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/RDS,DBClusterIdentifier} MetricName=\"DatabaseConnections\"', 'Maximum', 60)",
              "id": "rds_connections"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Maximum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "RDS Database Connections",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Connections",
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 68,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/RDS,DBClusterIdentifier} MetricName=\"Queries\"', 'Sum', 60)",
              "id": "rds_queries"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "title": "RDS Query Count",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Queries",
            "min": 0
          }
        },
        "liveData": true
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 68,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/RDS,DBClusterIdentifier} MetricName=\"CPUUtilization\"', 'p99', 60)",
              "id": "rds_cpu"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "title": "RDS CPU Utilization",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "CPU (%)",
            "min": 0,
            "max": 100
          }
        },
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Warning",
              "value": 70,
              "fill": "above",
              "color": "#ff7f0e"
            },
            {
              "label": "Critical",
              "value": 85,
              "fill": "above",
              "color": "#d62728"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 68,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/RDS,DBClusterIdentifier} MetricName=\"FreeableMemory\"', 'p99', 60)/1024/1024/1024",
              "id": "rds_free_mem",
              "label": "Free Memory (GB)"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "RDS Free Memory",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Memory (GB)",
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 74,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/RDS,DBClusterIdentifier} MetricName=\"ReadLatency\"', 'p99', 60)*1000",
              "id": "read_lat",
              "label": "Read Latency"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/RDS,DBClusterIdentifier} MetricName=\"WriteLatency\"', 'p99', 60)*1000",
              "id": "write_lat",
              "label": "Write Latency"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "RDS I/O Latency",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Latency (ms)",
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 8,
      "y": 74,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/RDS,DBClusterIdentifier} MetricName=\"ReadIOPS\"', 'p99', 60)",
              "id": "read_iops",
              "label": "Read IOPS"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/RDS,DBClusterIdentifier} MetricName=\"WriteIOPS\"', 'p99', 60)",
              "id": "write_iops",
              "label": "Write IOPS"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "title": "RDS IOPS",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "IOPS",
            "min": 0
          }
        },
        "liveData": true
      }
    },
    {
      "type": "metric",
      "x": 16,
      "y": 74,
      "width": 8,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/RDS,DBClusterIdentifier} MetricName=\"AuroraReplicaLag\"', 'Maximum', 60)",
              "id": "replica_lag"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Maximum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "RDS Replica Lag",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Lag (ms)",
            "min": 0
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Alert Threshold",
              "value": 1000,
              "fill": "above",
              "color": "#d62728"
            }
          ]
        }
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 80,
      "width": 24,
      "height": 1,
      "properties": {
        "markdown": "## 🖥️ Compute & Auto Scaling"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 81,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"CPUUtilization\"', 'Maximum', 60)",
              "id": "ec2_cpu"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Maximum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "EC2 CPU Utilization",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "CPU (%)",
            "min": 0,
            "max": 100
          }
        },
        "annotations": {
          "horizontal": [
            {
              "label": "Warning",
              "value": 75,
              "fill": "above",
              "color": "#ff7f0e"
            }
          ]
        }
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 81,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"NetworkIn\"', 'Sum', 60)/1024/1024",
              "id": "net_in",
              "label": "Network In (MB)"
            }
          ],
          [
            {
              "expression": "SEARCH('{AWS/EC2,InstanceId} MetricName=\"NetworkOut\"', 'Sum', 60)/1024/1024",
              "id": "net_out",
              "label": "Network Out (MB)"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Sum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "EC2 Network Traffic",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Data (MB)",
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 81,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SUM(SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupInServiceInstances\"', 'p99', 60))",
              "label": "InService",
              "id": "asg_inservice",
              "color": "#2ca02c"
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupTerminatingCapacity\"', 'p99', 60))",
              "label": "Terminating",
              "id": "asg_terminating",
              "color": "#d62728"
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupPendingCapacity\"', 'p99', 60))",
              "label": "Pending",
              "id": "asg_pending",
              "color": "#c7c7c7"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "us-east-1",
        "stat": "p99",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "yAxis": {
          "left": {
            "showUnits": false,
            "min": 0,
            "label": "Instance Count"
          }
        },
        "title": "ASG Instance Status"
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 81,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [
            {
              "expression": "SUM(SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupTotalCapacity\"', 'Maximum', 60))",
              "label": "Current",
              "id": "asg_current",
              "color": "#1f77b4"
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupDesiredCapacity\"', 'Maximum', 60))",
              "label": "Desired",
              "id": "asg_desired",
              "color": "#ff7f0e"
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupMinSize\"', 'Maximum', 60))",
              "label": "Min",
              "id": "asg_min",
              "color": "#2ca02c"
            }
          ],
          [
            {
              "expression": "SUM(SEARCH('{AWS/AutoScaling,AutoScalingGroupName} MetricName=\"GroupMaxSize\"', 'Maximum', 60))",
              "label": "Max",
              "id": "asg_max",
              "color": "#d62728"
            }
          ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "stat": "Maximum",
        "period": 60,
        "liveData": true,
        "legend": {
          "position": "hidden"
        },
        "title": "ASG Capacity Tracking",
        "yAxis": {
          "left": {
            "min": 0,
            "showUnits": false,
            "label": "Instance Count"
          }
        }
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 87,
      "width": 24,
      "height": 1,
      "properties": {
        "markdown": "## 📋 Application Logs & Insights"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 88,
      "width": 12,
      "height": 6,
      "properties": {
        "query": "SOURCE logGroups(namePrefix: [\"/aws/containerinsights/\"], class: \"STANDARD\")  |\nfields @timestamp, kubernetes.container_name as Container, kubernetes.namespace_name as Namespace, log\n| filter log like /(?i)(error|exception|fatal|critical)/\n| sort @timestamp desc\n| limit 50",
        "queryBy": "logGroupPrefix",
        "logGroupPrefixes": {
          "accountIds": ["All"],
          "logGroupPrefix": ["/aws/containerinsights/"],
          "logClass": "STANDARD"
        },
        "region": "us-east-1",
        "stacked": false,
        "title": "[EKS] Error Logs (Last 50)",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 12,
      "y": 88,
      "width": 12,
      "height": 6,
      "properties": {
        "query": "SOURCE logGroups(namePrefix: [\"/aws/ecs/\"], class: \"STANDARD\")  |\nfields @timestamp, @entity.KeyAttributes.Name as Service, @message\n| filter @message like /(?i)(error|exception|fatal|critical)/\n| filter @log not like /containerinsights/\n| sort @timestamp desc\n| limit 50",
        "queryBy": "logGroupPrefix",
        "logGroupPrefixes": {
          "accountIds": ["All"],
          "logGroupPrefix": ["/aws/ecs/"],
          "logClass": "STANDARD"
        },
        "region": "us-east-1",
        "stacked": false,
        "title": "[ECS] Error Logs (Last 50)",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 94,
      "width": 12,
      "height": 6,
      "properties": {
        "query": "SOURCE logGroups(namePrefix: [\"/aws/containerinsights/\"], class: \"STANDARD\")  |\nfields kubernetes.container_name as Container, log\n| filter not isblank(log)\n| sort @timestamp desc\n| limit 100",
        "queryBy": "logGroupPrefix",
        "logGroupPrefixes": {
          "accountIds": ["All"],
          "logGroupPrefix": ["/aws/containerinsights/"],
          "logClass": "STANDARD"
        },
        "region": "us-east-1",
        "stacked": false,
        "title": "[EKS] Recent Container Logs (Last 100)",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 12,
      "y": 94,
      "width": 12,
      "height": 6,
      "properties": {
        "query": "SOURCE logGroups(namePrefix: [\"/aws/ecs/\"], class: \"STANDARD\")  |\nfields @entity.KeyAttributes.Name as Service, @message\n| sort @timestamp desc\n| filter @log not like /containerinsights/\n| limit 100",
        "queryBy": "logGroupPrefix",
        "logGroupPrefixes": {
          "accountIds": ["All"],
          "logGroupPrefix": ["/aws/ecs/"],
          "logClass": "STANDARD"
        },
        "region": "us-east-1",
        "stacked": false,
        "title": "[ECS] Recent Container Logs (Last 100)",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 100,
      "width": 24,
      "height": 6,
      "properties": {
        "query": "SOURCE logGroups(namePrefix: [\"/aws/lambda/\"], class: \"STANDARD\")  |\nfields @timestamp, @message\n| filter @message like /(?i)(error|exception|timeout|out of memory)/\n| sort @timestamp desc\n| limit 100",
        "queryBy": "logGroupPrefix",
        "logGroupPrefixes": {
          "accountIds": ["All"],
          "logGroupPrefix": ["/aws/lambda/"],
          "logClass": "STANDARD"
        },
        "region": "us-east-1",
        "stacked": false,
        "title": "Lambda Error Logs (Last 100)",
        "view": "table"
      }
    }
  ]
}
```
