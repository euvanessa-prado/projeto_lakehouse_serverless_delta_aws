"""
Glue Job: Staged to Curated - User Tags.

Este job lê dados Delta Lake do S3 Staged (tags),
realiza agregação e escreve a tabela curated user_tags.
"""
import sys

from awsglue.utils import getResolvedOptions
from pyspark.sql import SparkSession
from pyspark.sql.functions import count


def get_args():
    """Obtém argumentos do Glue Job."""
    return getResolvedOptions(sys.argv, ['staged_bucket', 'curated_bucket'])


def init_spark():
    """Inicializa SparkSession com configurações Delta Lake."""
    return (
        SparkSession.builder
        .appName("CuratedLayerUserTags")
        .config(
            "spark.sql.extensions",
            "io.delta.sql.DeltaSparkSessionExtension"
        )
        .config(
            "spark.sql.catalog.spark_catalog",
            "org.apache.spark.sql.delta.catalog.DeltaCatalog"
        )
        .enableHiveSupport()
        .getOrCreate()
    )


def read_tags_table(spark, tags_path):
    """Lê tabela Delta de tags."""
    return spark.read.format("delta").load(tags_path)


def transform_user_tags(tags_df):
    """Transforma dados agregando tags por usuário."""
    return tags_df.groupBy("userid", "tag").agg(
        count("*").alias("tag_count")
    )


def write_curated_user_tags(df, output_path):
    """Escreve tabela curated em formato Delta."""
    df.write.format("delta").mode("overwrite").save(output_path)


def main():
    """Função principal do job."""
    args = get_args()

    tags_path = f"s3://{args['staged_bucket']}/movielens_delta_glue/tags/"
    curated_path = f"s3://{args['curated_bucket']}/movielens_delta_glue/user_tags/"

    spark = init_spark()
    tags_df = read_tags_table(spark, tags_path)
    user_tags_df = transform_user_tags(tags_df)
    write_curated_user_tags(user_tags_df, curated_path)

    print("Tabela curated_user_tags criada com sucesso!")


if __name__ == "__main__":
    main()
