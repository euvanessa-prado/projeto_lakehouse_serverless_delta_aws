"""
Glue Job: Data Quality com Great Expectations.

Este job executa validações de qualidade de dados nas tabelas
curated Delta Lake usando Great Expectations.

Configurações Glue:
--conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension
--conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog
--datalake-formats delta
--additional-python-modules great_expectations[spark]==0.16.5,delta-spark==3.2.1
"""
import sys

import great_expectations as ge
from awsglue.utils import getResolvedOptions
from great_expectations.core.batch import RuntimeBatchRequest
from great_expectations.core.yaml_handler import YAMLHandler
from great_expectations.data_context.types.base import DataContextConfig
from pyspark.sql import SparkSession

yaml = YAMLHandler()

DATASOURCE_YAML = """
name: my_spark_datasource
class_name: Datasource
module_name: great_expectations.datasource
execution_engine:
    module_name: great_expectations.execution_engine
    class_name: SparkDFExecutionEngine
data_connectors:
    my_runtime_data_connector:
        class_name: RuntimeDataConnector
        batch_identifiers:
            - some_key_maybe_pipeline_stage
            - some_other_key_maybe_airflow_run_id
"""

SUITE_NAME_MOVIES = 'suite_tests_movie_ratings'
SUITE_NAME_TAGS = 'suite_tests_user_tags'


def config_data_docs_site(context, output_path):
    """Configura site de Data Docs no S3."""
    data_context_config = DataContextConfig()

    data_context_config["data_docs_sites"] = {
        "s3_site": {
            "class_name": "SiteBuilder",
            "store_backend": {
                "class_name": "TupleS3StoreBackend",
                "bucket": output_path.replace("s3://", "")
            },
            "site_index_builder": {
                "class_name": "DefaultSiteIndexBuilder"
            }
        }
    }

    context._project_config["data_docs_sites"] = (
        data_context_config["data_docs_sites"]
    )


def create_context_ge(output_path):
    """Cria contexto do Great Expectations."""
    context = ge.get_context()
    context.add_expectation_suite(expectation_suite_name=SUITE_NAME_MOVIES)
    context.add_expectation_suite(expectation_suite_name=SUITE_NAME_TAGS)

    context.add_datasource(**yaml.load(DATASOURCE_YAML))
    config_data_docs_site(context, output_path)

    return context


def create_validator(context, suite, df):
    """Cria validator para o DataFrame."""
    runtime_batch_request = RuntimeBatchRequest(
        datasource_name="my_spark_datasource",
        data_connector_name="my_runtime_data_connector",
        data_asset_name="data_asset",
        runtime_parameters={"batch_data": df},
        batch_identifiers={
            "some_key_maybe_pipeline_stage": "ingestion",
            "some_other_key_maybe_airflow_run_id": "run_001",
        },
    )
    return context.get_validator(
        batch_request=runtime_batch_request,
        expectation_suite=suite
    )


def add_tests_movie_ratings(df_validator):
    """Adiciona testes de qualidade para movie_ratings."""
    df_validator.expect_table_columns_to_match_ordered_list([
        "movieid", "title", "genres", "avg_rating"
    ])
    df_validator.expect_column_values_to_be_unique("movieid")
    df_validator.expect_column_values_to_not_be_null("movieid")
    df_validator.expect_column_values_to_be_between(
        "avg_rating",
        min_value=0,
        max_value=5
    )
    df_validator.save_expectation_suite(discard_failed_expectations=False)
    return df_validator


def add_tests_user_tags(df_validator):
    """Adiciona testes de qualidade para user_tags."""
    df_validator.expect_table_columns_to_match_ordered_list([
        "userid", "tag", "tag_count"
    ])
    df_validator.expect_column_values_to_not_be_null("userid")
    df_validator.expect_column_values_to_be_between(
        "tag_count",
        min_value=0,
        max_value=1000
    )
    df_validator.save_expectation_suite(discard_failed_expectations=False)
    return df_validator


def process_suite_ge(spark, input_path, output_path):
    """Processa suites de validação do Great Expectations."""
    context = create_context_ge(output_path)

    # Processando movie_ratings
    df_movie = spark.read.format("delta").load(f'{input_path}/movie_ratings/')
    suite_movies = context.get_expectation_suite(
        expectation_suite_name=SUITE_NAME_MOVIES
    )
    df_validator_movies = create_validator(context, suite_movies, df_movie)
    df_validator_movies = add_tests_movie_ratings(df_validator_movies)
    results_movies = df_validator_movies.validate(expectation_suite=suite_movies)

    # Processando user_tags
    df_tags = spark.read.format("delta").load(f'{input_path}/user_tags/')
    suite_tags = context.get_expectation_suite(
        expectation_suite_name=SUITE_NAME_TAGS
    )
    df_validator_tags = create_validator(context, suite_tags, df_tags)
    df_validator_tags = add_tests_user_tags(df_validator_tags)
    results_tags = df_validator_tags.validate(expectation_suite=suite_tags)

    if results_movies['success'] and results_tags['success']:
        print("Suites de testes executadas com sucesso!")
    else:
        print("Algumas validações falharam. Verifique os Data Docs.")

    # Gerando Data Docs
    context.build_data_docs(site_names=["s3_site"])
    print("Validação finalizada e Data Docs gerados")


def init_spark():
    """Inicializa SparkSession com configurações Delta Lake."""
    return (
        SparkSession.builder
        .appName("CuratedLayerDataQuality")
        .config(
            "spark.sql.extensions",
            "io.delta.sql.DeltaSparkSessionExtension"
        )
        .config(
            "spark.sql.catalog.spark_catalog",
            "org.apache.spark.sql.delta.catalog.DeltaCatalog"
        )
        .getOrCreate()
    )


def main():
    """Função principal do job."""
    args = getResolvedOptions(sys.argv, ['curated_bucket', 'datadocs_bucket'])

    input_path = f"s3://{args['curated_bucket']}/movielens_delta_glue"
    output_path = f"s3://{args['datadocs_bucket']}"

    spark = init_spark()
    process_suite_ge(spark, input_path, output_path)


if __name__ == "__main__":
    main()
