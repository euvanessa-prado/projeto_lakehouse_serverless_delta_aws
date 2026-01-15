"""
Glue Job: Raw to Staged Delta Lake.

Este job lê dados Parquet do S3 Raw e escreve em formato Delta Lake
no S3 Staged, realizando merge baseado em chave primária.
"""
import sys

from awsglue.utils import getResolvedOptions
from delta.tables import DeltaTable
from pyspark.sql import SparkSession
from pyspark.sql.functions import col


def get_args():
    """Obtém argumentos do Glue Job."""
    return getResolvedOptions(
        sys.argv,
        ['input_path', 'delta_table_path', 'primary_key']
    )


def init_spark():
    """Inicializa SparkSession com configurações Delta Lake."""
    return (
        SparkSession.builder
        .appName("Glue Delta Merge")
        .getOrCreate()
    )


def read_input_data(spark, input_path):
    """Lê dados Parquet do caminho de entrada."""
    return spark.read.parquet(input_path)


def initialize_delta_table(spark, delta_table_path, input_df):
    """Inicializa tabela Delta se não existir."""
    input_df.write.format("delta").mode("overwrite").save(delta_table_path)
    return DeltaTable.forPath(spark, delta_table_path)


def get_merge_condition(primary_keys):
    """Gera condição de merge baseada nas chaves primárias."""
    return " AND ".join(
        [f"target.{key} = source.{key}" for key in primary_keys]
    )


def perform_merge(spark, input_df, delta_table_path, primary_keys):
    """Executa merge dos dados na tabela Delta."""
    if not DeltaTable.isDeltaTable(spark, delta_table_path):
        return initialize_delta_table(spark, delta_table_path, input_df)

    delta_table = DeltaTable.forPath(spark, delta_table_path)
    input_df = input_df.dropDuplicates(primary_keys)
    merge_condition = get_merge_condition(primary_keys)

    (
        delta_table.alias("target")
        .merge(input_df.alias("source"), merge_condition)
        .whenMatchedUpdate(
            set={c: col(f"source.{c}") for c in input_df.columns}
        )
        .whenNotMatchedInsertAll()
        .execute()
    )


def main():
    """Função principal do job."""
    args = get_args()
    spark = init_spark()
    input_df = read_input_data(spark, args["input_path"])

    primary_keys = [key.strip() for key in args["primary_key"].split(",")]

    perform_merge(spark, input_df, args["delta_table_path"], primary_keys)
    print("Processo concluído com sucesso!")


if __name__ == "__main__":
    main()
