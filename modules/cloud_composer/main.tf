# Google Cloud Monitoringで監視されるプロジェクトを作成
resource "google_monitoring_monitored_project" "projects_monitored" {
  for_each      = toset(["YOUR_PROJECT_TO_MONITOR_1", "YOUR_PROJECT_TO_MONITOR_2", "YOUR_PROJECT_TO_MONITOR_3"]) // 監視対象となるプロジェクトのリストを指定
  metrics_scope = join("", ["locations/global/metricsScopes/", "YOUR_MONITORING_PROJECT"]) // メトリクスのスコープを指定
  name          = each.value // 監視対象プロジェクトの名前を指定
}

# Google Cloud Monitoringでアラートポリシーを作成
resource "google_monitoring_alert_policy" "environment_health" {
  display_name = "Environment Health" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Environment Health" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| {metric 'composer.googleapis.com/environment/dagbag_size'",
        "| group_by 5m, [value_dagbag_size_mean: if(mean(value.dagbag_size) > 0, 1, 0)]",
        "| align mean_aligner(5m)",
        "| group_by [resource.project_id, resource.environment_name],    [value_dagbag_size_mean_aggregate: aggregate(value_dagbag_size_mean)];  ",
        "metric 'composer.googleapis.com/environment/healthy'",
        "| group_by 5m,    [value_sum_signals: aggregate(if(value.healthy,1,0))]",
        "| align mean_aligner(5m)| absent_for 5m }",
        "| outer_join 0",
        "| group_by [resource.project_id, resource.environment_name]",
        "| value val(2)",
        "| align mean_aligner(5m)",
        "| window(5m)",
        "| condition val(0) < 0.9"
      ]) // メモリ使用量を取得するための監視クエリを定義
      duration = "120s" // アラートが発火するまでの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# Google Cloud Monitoringでデータベースの健全性を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "database_health" {
  display_name = "Database Health" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Database Health" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/database_health'",
        "| group_by 5m,",
        "    [value_database_health_fraction_true: fraction_true(value.database_health)]",
        "| every 5m",
        "| group_by 5m,",
        "    [value_database_health_fraction_true_aggregate:",
        "       aggregate(value_database_health_fraction_true)]",
        "| every 5m",
        "| group_by [resource.project_id, resource.environment_name],",
        "    [value_database_health_fraction_true_aggregate_aggregate:",
        "       aggregate(value_database_health_fraction_true_aggregate)]",
      "| condition val() < 0.95"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "120s" // アラートが発火するまでの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# oogle Cloud MonitoringでWebサーバーの健全性を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "webserver_health" {
  display_name = "Web Server Health" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Web Server Health" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/web_server/health'",
        "| group_by 5m, [value_health_fraction_true: fraction_true(value.health)]",
        "| every 5m",
        "| group_by 5m,",
        "    [value_health_fraction_true_aggregate:",
        "       aggregate(value_health_fraction_true)]",
        "| every 5m",
        "| group_by [resource.project_id, resource.environment_name],",
        "    [value_health_fraction_true_aggregate_aggregate:",
        "       aggregate(value_health_fraction_true_aggregate)]",
      "| condition val() < 0.95"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "120s" // アラートが発火するまでの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# Google Cloud Composerのスケジューラーのハートビート回数を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "scheduler_heartbeat" {
  display_name = "Scheduler Heartbeat" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Scheduler Heartbeat" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/scheduler_heartbeat_count'",
        "| group_by 10m,",
        "    [value_scheduler_heartbeat_count_aggregate:",
        "      aggregate(value.scheduler_heartbeat_count)]",
        "| every 10m",
        "| group_by 10m,",
        "    [value_scheduler_heartbeat_count_aggregate_mean:",
        "       mean(value_scheduler_heartbeat_count_aggregate)]",
        "| every 10m",
        "| group_by [resource.project_id, resource.environment_name],",
        "    [value_scheduler_heartbeat_count_aggregate_mean_aggregate:",
        "       aggregate(value_scheduler_heartbeat_count_aggregate_mean)]",
      "| condition val() < 80"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "120s" // アラートが発火するまでの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# Google Cloud ComposerのデータベースのCPU使用率を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "database_cpu" {
  display_name = "Database CPU" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Database CPU" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/database/cpu/utilization'",
        "| group_by 10m, [value_utilization_mean: mean(value.utilization)]",
        "| every 10m",
        "| group_by [resource.project_id, resource.environment_name]",
      "| condition val() > 0.8"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "120s" // アラートが発火するまでの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# Google Cloud Composerのスケジューラ（airflow-scheduler）のCPU使用率を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "scheduler_cpu" {
  display_name = "Scheduler CPU" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Scheduler CPU" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch k8s_container",
        "| metric 'kubernetes.io/container/cpu/limit_utilization'",
        "| filter (resource.pod_name =~ 'airflow-scheduler-.*')",
        "| group_by 10m, [value_limit_utilization_mean: mean(value.limit_utilization)]",
        "| every 10m",
        "| group_by [resource.cluster_name],",
        "    [value_limit_utilization_mean_mean: mean(value_limit_utilization_mean)]",
      "| condition val() > 0.8"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "120s" // アラートが発火するまでの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# Google Cloud Composerのワーカー（airflow-worker）のCPU使用率を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "worker_cpu" {
  display_name = "Worker CPU" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Worker CPU" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch k8s_container",
        "| metric 'kubernetes.io/container/cpu/limit_utilization'",
        "| filter (resource.pod_name =~ 'airflow-worker.*')",
        "| group_by 10m, [value_limit_utilization_mean: mean(value.limit_utilization)]",
        "| every 10m",
        "| group_by [resource.cluster_name],",
        "    [value_limit_utilization_mean_mean: mean(value_limit_utilization_mean)]",
      "| condition val() > 0.8"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "120s" // アラートが発火するまでの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# Google Cloud ComposerのWebサーバー（airflow-webserver）のCPU使用率を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "webserver_cpu" {
  display_name = "Web Server CPU" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Web Server CPU" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch k8s_container",
        "| metric 'kubernetes.io/container/cpu/limit_utilization'",
        "| filter (resource.pod_name =~ 'airflow-webserver.*')",
        "| group_by 10m, [value_limit_utilization_mean: mean(value.limit_utilization)]",
        "| every 10m",
        "| group_by [resource.cluster_name],",
        "    [value_limit_utilization_mean_mean: mean(value_limit_utilization_mean)]",
      "| condition val() > 0.8"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "120s" // アラートが発火するまでの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# Google Cloud ComposerのDAG（Directed Acyclic Graph）のパーシング時間（DAGの処理時間）を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "parsing_time" {
  display_name = "DAG Parsing Time" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "DAG Parsing Time" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/dag_processing/total_parse_time'",
        "| group_by 5m, [value_total_parse_time_mean: mean(value.total_parse_time)]",
        "| every 5m",
        "| group_by [resource.project_id, resource.environment_name]",
      "| condition val(0) > cast_units(30,\"s\")"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "120s" // アラートが発火するまでの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# Google Cloud Composerのデータベースのメモリ利用率を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "database_memory" {
  display_name = "Database Memory" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Database Memory" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/database/memory/utilization'",
        "| group_by 10m, [value_utilization_mean: mean(value.utilization)]",
        "| every 10m",
        "| group_by [resource.project_id, resource.environment_name]",
      "| condition val() > 0.8"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "0s" // アラートの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
}

# Google Cloud Composerのスケジューラーのメモリ利用率を監視するためのアラートポリシーを作成
resource "google_monitoring_alert_policy" "scheduler_memory" {
  display_name = "Scheduler Memory" // アラートポリシーの表示名を指定
  combiner     = "OR" // アラート条件の組み合わせ方法を指定
  conditions {
    display_name = "Scheduler Memory" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch k8s_container",
        "| metric 'kubernetes.io/container/memory/limit_utilization'",
        "| filter (resource.pod_name =~ 'airflow-scheduler-.*')",
        "| group_by 10m, [value_limit_utilization_mean: mean(value.limit_utilization)]",
        "| every 10m",
        "| group_by [resource.cluster_name],",
        "    [value_limit_utilization_mean_mean: mean(value_limit_utilization_mean)]",
      "| condition val() > 0.8"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "0s" // アラートの期間を指定
      trigger {
        count = "1"
      } // アラートのトリガーを指定
    } // アラートの条件式をMonitoring Query Languageで指定
  } // アラートポリシーの条件を定義
  documentation {
    content = join("", [
      "Scheduler Memory exceeds a threshold, summed across all schedulers in the environment. ",
    "Add more schedulers OR increase scheduler's memory OR reduce scheduling load (e.g. through lower parsing frequency or lower number of DAGs/tasks running"])
  } // アラートポリシーのドキュメンテーションを設定
}

# Google Cloud Platform (GCP) の Monitoring サービスを使用して、Kubernetes クラスター上のメモリ使用量がしきい値を超えた場合にアラートを作成
resource "google_monitoring_alert_policy" "worker_memory" {
  display_name = "Worker Memory" // アラートポリシーの表示名を設定
  combiner     = "OR" // アラートの結果を組み合わせる方法を指定
  conditions {
    display_name = "Worker Memory" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch k8s_container",
        "| metric 'kubernetes.io/container/memory/limit_utilization'",
        "| filter (resource.pod_name =~ 'airflow-worker.*')",
        "| group_by 10m, [value_limit_utilization_mean: mean(value.limit_utilization)]",
        "| every 10m",
        "| group_by [resource.cluster_name],",
        "    [value_limit_utilization_mean_mean: mean(value_limit_utilization_mean)]",
      "| condition val() > 0.8"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "0s" // 条件がどれくらいの時間継続する必要があるかを設定
      trigger {
        count = "1"
      } // アラートがトリガーされるためのトリガー条件を設定
    } // 監視クエリ言語を使用して条件を指定
  } // アラートポリシーの条件を定義
}

# Kubernetes クラスター上のメモリ使用量がしきい値を超えた場合にアラートを作成する Terraform の設定
resource "google_monitoring_alert_policy" "webserver_memory" {
  display_name = "Web Server Memory" // アラートポリシーの表示名を設
  combiner     = "OR" // アラートの結果を組み合わせる方法を指定
  conditions {
    display_name = "Web Server Memory" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch k8s_container",
        "| metric 'kubernetes.io/container/memory/limit_utilization'",
        "| filter (resource.pod_name =~ 'airflow-webserver.*')",
        "| group_by 10m, [value_limit_utilization_mean: mean(value.limit_utilization)]",
        "| every 10m",
        "| group_by [resource.cluster_name],",
        "    [value_limit_utilization_mean_mean: mean(value_limit_utilization_mean)]",
      "| condition val() > 0.8"]) // メモリ使用量を取得するための監視クエリを定義
      duration = "0s" // 条件がどれくらいの時間継続する必要があるかを設定
      trigger {
        count = "1"
      } // アラートがトリガーされるためのトリガー条件を設定
    } // 監視クエリ言語を使用して条件を指定
  } // アラートポリシーの条件を定義
}

resource "google_monitoring_alert_policy" "scheduled_tasks_percentage" {
  display_name = "Scheduled Tasks Percentage"
  combiner     = "OR"
  conditions {
    display_name = "Scheduled Tasks Percentage"
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/unfinished_task_instances'",
        "| align mean_aligner(10m)",
        "| every(10m)",
        "| window(10m)",
        "| filter_ratio_by [resource.project_id, resource.environment_name], metric.state = 'scheduled'",
      "| condition val() > 0.80"])
      duration = "300s"
      trigger {
        count = "1"
      }
    }
  }
  # uncomment to set an auto close strategy for the alert
  #alert_strategy {
  #    auto_close = "30m"
  #}
}

# Cloud Composer（旧名：Cloud Dataflow）環境内のスケジュールされたタスクの進捗状況を監視し、タスクの進捗率が特定のしきい値を超えた場合にアラートを作成
resource "google_monitoring_alert_policy" "queued_tasks_percentage" {
  display_name = "Queued Tasks Percentage" // アラートポリシーの表示名を設定
  combiner     = "OR" // アラートの結果を組み合わせる方法を指定
  conditions {
    display_name = "Queued Tasks Percentage" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/unfinished_task_instances'",
        "| align mean_aligner(10m)",
        "| every(10m)",
        "| window(10m)",
        "| filter_ratio_by [resource.project_id, resource.environment_name], metric.state = 'queued'",
        "| group_by [resource.project_id, resource.environment_name]",
      "| condition val() > 0.95"]) // タスクの進捗率を取得するための監視クエリを定義
      duration = "300s" // 条件がどれくらいの時間継続する必要があるかを設定
      trigger {
        count = "1"
      } // アラートがトリガーされるためのトリガー条件を設定
    } // 監視クエリ言語を使用して条件を指定
  } // アラートポリシーの条件を定
}

# Cloud Composer（旧名：Cloud Dataflow）環境内のキューまたはスケジュールされたタスクの進捗状況を監視し、タスクの進捗率が特定のしきい値を超えた場合にアラートを作成する Terraform の設定
resource "google_monitoring_alert_policy" "queued_or_scheduled_tasks_percentage" {
  display_name = "Queued or Scheduled Tasks Percentage" // アラートポリシーの表示名を設定
  combiner     = "OR" // アラートの結果を組み合わせる方法を指定
  conditions {
    display_name = "Queued or Scheduled Tasks Percentage" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/unfinished_task_instances'",
        "| align mean_aligner(10m)",
        "| every(10m)",
        "| window(10m)",
        "| filter_ratio_by [resource.project_id, resource.environment_name], or(metric.state = 'queued', metric.state = 'scheduled' )",
        "| group_by [resource.project_id, resource.environment_name]",
      "| condition val() > 0.80"]) // タスクの進捗率を取得するための監視クエリを定義
      duration = "120s" // 条件がどれくらいの時間継続する必要があるかを設定
      trigger {
        count = "1"
      } // アラートがトリガーされるためのトリガー条件を設定
    } // 監視クエリ言語を使用して条件を指定
  } // アラートポリシーの条件を定義
}


resource "google_monitoring_alert_policy" "workers_above_minimum" {
  display_name = "Workers above minimum (negative = missing workers)" // アラートポリシーの表示名を設定
  combiner     = "OR" // アラートの結果を組み合わせる方法を指定
  conditions {
    display_name = "Workers above minimum" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| { metric 'composer.googleapis.com/environment/num_celery_workers'",
        "| group_by 5m, [value_num_celery_workers_mean: mean(value.num_celery_workers)]",
        "| every 5m",
        "; metric 'composer.googleapis.com/environment/worker/min_workers'",
        "| group_by 5m, [value_min_workers_mean: mean(value.min_workers)]",
        "| every 5m }",
        "| outer_join 0",
        "| sub",
        "| group_by [resource.project_id, resource.environment_name]",
      "| condition val() < 0"]) // ワーカーの数と最小ワーカー数を取得するための監視クエリを定義
      duration = "0s" // 条件がどれくらいの時間継続する必要があるかを設定
      trigger {
        count = "1"
      } // アラートがトリガーされるためのトリガー条件を設定
    } // 監視クエリ言語を使用して条件を指定
  } // アラートポリシーの条件を定義
}

# Cloud Composer（旧名：Cloud Dataflow）環境内のワーカーポッドの削除（eviction）回数を監視し、ポッドの削除が発生した場合にアラートを作成する Terraform の設定
resource "google_monitoring_alert_policy" "pod_evictions" {
  display_name = "Worker pod evictions" // アラートポリシーの表示名を設定
  combiner     = "OR" // アラートの結果を組み合わせる方法を指定
  conditions {
    display_name = "Worker pod evictions" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'composer.googleapis.com/environment/worker/pod_eviction_count'",
        "| align delta(1m)",
        "| every 1m",
        "| group_by [resource.project_id, resource.environment_name]",
      "| condition val() > 0"])
      duration = "60s" // 条件がどれくらいの時間継続する必要があるかを設定
      trigger {
        count = "1"
      } // アラートがトリガーされるためのトリガー条件を設定
    } // 監視クエリ言語を使用して条件を指
  } // アラートポリシーの条件を定義
}

# Cloud Composer（旧名：Cloud Dataflow）環境内のスケジューラに関連するエラーのログエントリ数を監視し、一定回数以上のエラーが発生した場合にアラートを作成
resource "google_monitoring_alert_policy" "scheduler_errors" {
  display_name = "Scheduler Errors" // アラートポリシーの表示名を設定
  combiner     = "OR" // アラートの結果を組み合わせる方法を指定
  conditions {
    display_name = "Scheduler Errors" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'logging.googleapis.com/log_entry_count'",
        "| filter (metric.log == 'airflow-scheduler' && metric.severity == 'ERROR')",
        "| group_by 5m,",
        "    [value_log_entry_count_aggregate: aggregate(value.log_entry_count)]",
        "| every 5m",
        "| group_by [resource.project_id, resource.environment_name],",
        "    [value_log_entry_count_aggregate_max: max(value_log_entry_count_aggregate)]",
      "| condition val() > 50"])
      duration = "300s"
      trigger {
        count = "1"
      } // エラーのログエントリ数を取得するための監視クエリを定義
    } // 監視クエリ言語を使用して条件を指定
  } // アラートポリシーの条件を定義
}

# Cloud Composer（旧名：Cloud Dataflow）環境内のワーカーに関連するエラーのログエントリ数を監視し、一定回数以上のエラーが発生した場合にアラートを作成
resource "google_monitoring_alert_policy" "worker_errors" {
  display_name = "Worker Errors" // アラートポリシーの表示名を設定
  combiner     = "OR" // アラートの結果を組み合わせる方法を指定
  conditions {
    display_name = "Worker Errors" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'logging.googleapis.com/log_entry_count'",
        "| filter (metric.log == 'airflow-worker' && metric.severity == 'ERROR')",
        "| group_by 5m,",
        "    [value_log_entry_count_aggregate: aggregate(value.log_entry_count)]",
        "| every 5m",
        "| group_by [resource.project_id, resource.environment_name],",
        "    [value_log_entry_count_aggregate_max: max(value_log_entry_count_aggregate)]",
      "| condition val() > 50"]) // エラーのログエントリ数を取得するための監視クエリを定義
      duration = "300s" // 条件がどれくらいの時間継続する必要があるかを設定
      trigger {
        count = "1"
      } // アラートがトリガーされるためのトリガー条件を設定
    } // 監視クエリ言語を使用して条件を指定
  } // アラートポリシーの条件を定義
}

# Cloud Composer（旧名：Cloud Dataflow）環境内のWebサーバーに関連するエラーのログエントリ数を監視し、一定回数以上のエラーが発生した場合にアラートを作成
resource "google_monitoring_alert_policy" "webserver_errors" {
  display_name = "Web Server Errors" // アラートポリシーの表示名を設定
  combiner     = "OR" // アラートの結果を組み合わせる方法を指
  conditions {
    display_name = "Web Server Errors" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'logging.googleapis.com/log_entry_count'",
        "| filter (metric.log == 'airflow-webserver' && metric.severity == 'ERROR')",
        "| group_by 5m,",
        "    [value_log_entry_count_aggregate: aggregate(value.log_entry_count)]",
        "| every 5m",
        "| group_by [resource.project_id, resource.environment_name],",
        "    [value_log_entry_count_aggregate_max: max(value_log_entry_count_aggregate)]",
      "| condition val() > 50"]) // エラーのログエントリ数を取得するための監視クエリを定義
      duration = "300s" // 条件がどれくらいの時間継続する必要があるかを設定
      trigger {
        count = "1"
      } // アラートがトリガーされるためのトリガー条件を設定
    } // 監視クエリ言語を使用して条件を指定
  } // アラートポリシーの条件を定義
}

# Cloud Composer（旧名：Cloud Dataflow）環境内のスケジューラ、ワーカー、およびWebサーバーとは関連しないその他のエラーのログエントリ数を監視し、一定回数以上のエラーが発生した場合にアラートを作成
resource "google_monitoring_alert_policy" "other_errors" {
  display_name = "Other Errors" // アラートポリシーの表示名を設定
  combiner     = "OR" // アラートの結果を組み合わせる方法を指定
  conditions {
    display_name = "Other Errors" // 条件の表示名を設定
    condition_monitoring_query_language {
      query = join("", [
        "fetch cloud_composer_environment",
        "| metric 'logging.googleapis.com/log_entry_count'",
        "| filter",
        "    (metric.log !~ 'airflow-scheduler|airflow-worker|airflow-webserver'",
        "     && metric.severity == 'ERROR')",
        "| group_by 5m, [value_log_entry_count_max: max(value.log_entry_count)]",
        "| every 5m",
        "| group_by [resource.project_id, resource.environment_name],",
        "    [value_log_entry_count_max_aggregate: aggregate(value_log_entry_count_max)]",
      "| condition val() > 10"]) // エラーのログエントリ数を取得するための監視クエリを定義
      duration = "300s" // 条件がどれくらいの時間継続する必要があるかを設定
      trigger {
        count = "1"
      } // アラートがトリガーされるためのトリガー条件を設定
    } // 監視クエリ言語を使用して条件を指定
  } // アラートポリシーの条件を定義
}

# Cloud Composer（旧名：Cloud Dataflow）環境のさまざまな健康状態とエラーの監視を行うためのダッシュボードを作成する Terraform の設定
resource "google_monitoring_dashboard" "Composer_Dashboard" {
  dashboard_json = <<EOF
{
  "category": "CUSTOM",
  "displayName": "Cloud Composer - Monitoring Platform",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "height": 1,
        "widget": {
          "text": {
            "content": "",
            "format": "MARKDOWN"
          },
          "title": "Health"
        },
        "width": 12,
        "xPos": 0,
        "yPos": 0
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.environment_health.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 1
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.database_health.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 1
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.webserver_health.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 5
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.scheduler_heartbeat.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 5
      },
      {
        "height": 1,
        "widget": {
          "text": {
            "content": "",
            "format": "RAW"
          },
          "title": "Airflow Task Execution and DAG Parsing"
        },
        "width": 12,
        "xPos": 0,
        "yPos": 9
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.scheduled_tasks_percentage.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 10
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.queued_tasks_percentage.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 10
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.queued_or_scheduled_tasks_percentage.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 14
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.parsing_time.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 14
      },
      {
        "height": 1,
        "widget": {
          "text": {
            "content": "",
            "format": "RAW"
          },
          "title": "Workers presence"
        },
        "width": 12,
        "xPos": 0,
        "yPos": 18
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.workers_above_minimum.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 19
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.pod_evictions.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 19
      },
      {
        "height": 1,
        "widget": {
          "text": {
            "content": "",
            "format": "RAW"
          },
          "title": "CPU Utilization"
        },
        "width": 12,
        "xPos": 0,
        "yPos": 23
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.database_cpu.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 24
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.scheduler_cpu.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 24
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.worker_cpu.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 28
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.webserver_cpu.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 28
      },

      {
        "height": 1,
        "widget": {
          "text": {
            "content": "",
            "format": "RAW"
          },
          "title": "Memory Utilization"
        },
        "width": 12,
        "xPos": 0,
        "yPos": 32
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.database_memory.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 33
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.scheduler_memory.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 33
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.worker_memory.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 37
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.webserver_memory.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 37
      },
      {
        "height": 1,
        "widget": {
          "text": {
            "content": "",
            "format": "RAW"
          },
          "title": "Airflow component errors"
        },
        "width": 12,
        "xPos": 0,
        "yPos": 41
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.scheduler_errors.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 42
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.worker_errors.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 42
      },
            {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.webserver_errors.name}"
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 48
      },
      {
        "height": 4,
        "widget": {
          "alertChart": {
            "name": "${google_monitoring_alert_policy.other_errors.name}"
          }
        },
        "width": 6,
        "xPos": 6,
        "yPos": 48
      },
      {
        "height": 1,
        "widget": {
          "text": {
            "content": "",
            "format": "RAW"
          },
          "title": "Task errors"
        },
        "width": 12,
        "xPos": 0,
        "yPos": 52
      }
    ]
  }
}
EOF
} // ダッシュボードの内容を JSON 形式で指定

# Cloud Composer（旧名：Cloud Dataflow）サービスを有効化するための設定
data "google_project" "project" {
} // Google Cloud プロジェクトの情報を取得するためのデータソースを定義

resource "google_project_service" "composer" {
  project = data.google_project.project.project_id // 有効化するプロジェクトをデータソースから取得したプロジェクトIDとして指定
  service = "composer.googleapis.com" // 有効化するサービスとして、Cloud Composerサービスを指定

  timeouts {
    create = "30m"
    update = "40m"
  } // タイムアウト設定

  disable_dependent_services = true // 依存するサービスの無効化フラグを設定
  disable_on_destroy         = false // リソースの削除時にサービスを無効化するかどうかを指定
}

# Cloud Functionsサービスを有効化するための設定
resource "google_project_service" "cloud_function" {
  project = data.google_project.project.project_id // 有効化するプロジェクトをデータソースから取得したプロジェクトIDとして指定
  service = "cloudfunctions.googleapis.com" // 有効化するサービスとして、Cloud Functionsサービスを指定

  timeouts {
    create = "30m"
    update = "40m"
  } // タイムアウト設定

  disable_dependent_services = true // 依存するサービスの無効化フラグを設定
  disable_on_destroy         = false // リソースの削除時にサービスを無効化するかどうかを指定
}

# Google Cloud Composer環境を定義
resource "google_composer_environment" "new_composer_env" {
  name    = "composer-environment" // Google Cloud Composer環境の名前を指定
  region  = "us-central1" // Composer環境を作成するGCPリージョンを指定
  project = data.google_project.project.project_id // ブロックを通じてGoogle CloudプロジェクトのIDを取得
  config {

    software_config {
      image_version = "composer-2-airflow-2"
    } // 環境にデプロイされるAirflowイメージのバージョンを指定
    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      } // スケジューラのリソース構成を指定
      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      } // Webサーバのリソース構成を指定
      worker {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      } // ワーカーのリソース構成を指定


    } // Composer環境内の各コンポーネント（スケジューラ、Webサーバ、ワーカー）のリソース構成を定義
    environment_size = "ENVIRONMENT_SIZE_SMALL" // Composer環境のサイズを指定

    node_config {
      network         = google_compute_network.composer_network.id // Composer環境が所属するGoogle Compute EngineネットワークのIDを指定
      subnetwork      = google_compute_subnetwork.composer_subnetwork.id // Composer環境が所属するサブネットのIDを指定
      service_account = google_service_account.composer_env_sa.email // Composer環境で使用されるサービスアカウントのメールアドレスを指定
    } // Composer環境のノード設定（ネットワーク、サブネット、サービスアカウントなど）を指定
  } // Composer環境の設定を定義
}

# Compute Engineネットワークを作成
resource "google_compute_network" "composer_network" {
  project                 = data.google_project.project.project_id // ブロックを通じてGoogle CloudプロジェクトのIDを取得
  name                    = "composer-test-network" // ネットワークの名前を指定
  auto_create_subnetworks = false // サブネットの自動作成オプションを指定
}

# Compute Engineサブネットを作成
resource "google_compute_subnetwork" "composer_subnetwork" {
  project       = data.google_project.project.project_id // ブロックを通じてGoogle CloudプロジェクトのIDを取得
  name          = "composer-test-subnet" // サブネットの名前を指
  ip_cidr_range = "10.2.0.0/16" // サブネットのIPアドレス範囲（CIDR形式）を指定
  region        = "us-central1" // サブネットが所属するGCPリージョンを指定
  network       = google_compute_network.composer_network.id // サブネットが所属するCompute EngineネットワークのIDを指定
}

# 新しいサービスアカウントを作成
resource "google_service_account" "composer_env_sa" {
  project      = data.google_project.project.project_id // ブロックを通じてGoogle CloudプロジェクトのIDを取得
  account_id   = "composer-worker-sa" // サービスアカウントのIDを指定
  display_name = "Test Service Account for Composer Environment deployment " // サービスアカウントの表示名を指定
}

# プロジェクトに対して特定のサービスのサービスアカウントを作成するための定義
resource "google_project_service_identity" "composer_sa" {
  provider = google-beta // リソースを作成するためのプロバイダを指定
  project  = data.google_project.project.project_id // ブロックを通じてGoogle CloudプロジェクトのIDを取得
  service  = "composer.googleapis.com" // サービスアカウントを作成する対象のサービスを指定
}

# IAM（Identity and Access Management）ロールのメンバーとしてサービスアカウントを追加
resource "google_project_iam_member" "composer_worker" {
  project = data.google_project.project.project_id //  ブロックを通じてGoogle CloudプロジェクトのIDを取得
  role    = "roles/composer.worker" // IAMメンバーに割り当てるロールを指定
  member  = "serviceAccount:${google_service_account.composer_env_sa.email}" // ロールに割り当てるメンバーを指定
}

# IAM（Identity and Access Management）ロールのメンバーとして別のサービスアカウントを追加
resource "google_service_account_iam_member" "custom_service_account" {
  provider           = google-beta // リソースを作成するためのプロバイダを指定
  service_account_id = google_service_account.composer_env_sa.id // IAMメンバーにロールを割り当てる対象のサービスアカウントのIDを指定
  role               = "roles/composer.ServiceAgentV2Ext" // IAMメンバーに割り当てるロールを指定
  member             = "serviceAccount:${google_project_service_identity.composer_sa.email}" // ロールに割り当てるメンバーを指定
}

# Google Cloud Pub/Subのトピック（Topic）を作成
resource "google_pubsub_topic" "trigger" {
  project                    = data.google_project.project.project_id // data ブロックを通じてGoogle CloudプロジェクトのIDを取得
  name                       = "dag-topic-trigger" // 作成されるPub/Subトピックの名前を指定
  message_retention_duration = "86600s" // メッセージの保持期間を指定
}

# Google Cloud Functionsの関数（Function）を作成するための定義
resource "google_cloudfunctions_function" "pubsub_function" {
  project = data.google_project.project.project_id // data ブロックを通じてGoogle CloudプロジェクトのIDを取得
  name    = "pubsub-publisher" // 作成されるCloud Functions関数の名前を指定
  runtime = "python310" // 関数のランタイム環境を指定
  region  = "us-central1" // 関数がデプロイされるGCPリージョンを指定

  available_memory_mb   = 128 // 関数の実行に割り当てる利用可能なメモリ量（MB単位）を指定
  source_archive_bucket = google_storage_bucket.cloud_function_bucket.name // 関数のソースコードアーカイブが格納されているGCS（Google Cloud Storage）バケットの名前を指定
  source_archive_object = google_storage_bucket_object.cloud_function_source.output_name //  関数のソースコードアーカイブファイル（ZIPなど）のオブジェクトパスを指定
  timeout               = 60 // 関数のタイムアウト時間を秒単位で指定
  entry_point           = "pubsub_publisher" // 関数のエントリーポイント（実行される関数の名前）を指定
  service_account_email = "${data.google_project.project.number}-compute@developer.gserviceaccount.com" // 関数が実行される際に使用されるサービスアカウントのメールアドレスを指定
  trigger_http          = true // 関数がHTTPリクエストをトリガーとして受け入れるかどうかを指定

}

# Google Cloud Storage（GCS）バケットを作成
resource "google_storage_bucket" "cloud_function_bucket" {
  project                     = data.google_project.project.project_id // data ブロックを通じてGoogle CloudプロジェクトのIDを取得
  name                        = "${data.google_project.project.project_id}-cloud-function-source-code" // 作成されるGCSバケットの名前を指定
  location                    = "US" // バケットが作成されるGCPリージョンを指定
  force_destroy               = true // バケット内のデータを削除した際にバケット自体も強制的に削除するかどうかを指定
  uniform_bucket_level_access = true // バケットレベルでの一貫性のあるアクセスを有効にするかどうかを指定
}

# Google Cloud Storage（GCS）バケットにオブジェクト（ファイル）を作成
resource "google_storage_bucket_object" "cloud_function_source" {
  name   = "pubsub-function-zip-file" // 作成されるオブジェクトの名前を指定
  bucket = google_storage_bucket.cloud_function_bucket.name // オブジェクトが作成されるGCSバケットの名前を指定
  content = "Data as string to be uploaded" // オブジェクトのコンテンツを文字列として指定
}

# Google Cloud Storage（GCS）バケットにオブジェクト（ファイル）を作成
resource "google_storage_bucket_object" "composer_dags_source" {
  name   = "dags/dag-pubsub-sensor-py-file" // 作成されるオブジェクトの名前を指定
  bucket = trimprefix(trimsuffix(google_composer_environment.new_composer_env.config[0].dag_gcs_prefix, "/dags"), "gs://") // オブジェクトが作成されるGCSバケットの名前を指定
  source = "./pubsub_trigger_response_dag.py" // ローカルファイルからGCSバケットにアップロードするファイルのパスを指定
}