"""
Glue Job: Staged to Curated - Movie Ratings.

Este job lê dados Delta Lake do S3 Staged (movies e ratings),
realiza agregação e escreve a tabela curated movie_ratings.
"""
import sys

from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.sql import SparkSession
from pyspark.sql.functions import avg


def get_args():
    """Obtém argumentos do Glue Job."""
    return getResolvedOptions(sys.argv, ['staged_bucket', 'curated_bucket'])


def init_spark():
    """Inicializa SparkSession com configurações Delta Lake."""
    spark = (
        SparkSession.builder
        .appName("CuratedLayerMovieRatings")
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

    glue_context = GlueContext(spark.sparkContext)
    return spark, glue_context


def read_delta_tables(spark, movies_path, ratings_path):
    """Lê tabelas Delta de movies e ratings."""
    movies_df = spark.read.format("delta").load(movies_path)
    ratings_df = spark.read.format("delta").load(ratings_path)
    return movies_df, ratings_df


def transform_data(movies_df, ratings_df):
    """Transforma dados agregando ratings por filme."""
    ratings_agg = ratings_df.groupBy("movieid").agg(
        avg("rating").alias("avg_rating")
    )
    return movies_df.join(ratings_agg, on="movieid", how="left")


def write_curated_table(df, output_path):
    """Escreve tabela curated em formato Delta."""
    df.write.format("delta").mode("overwrite").save(output_path)


def main():
    """Função principal do job."""
    args = get_args()

    movies_path = f"s3://{args['staged_bucket']}/movielens_delta_glue/movies/"
    ratings_path = f"s3://{args['staged_bucket']}/movielens_delta_glue/ratings/"
    curated_path = f"s3://{args['curated_bucket']}/movielens_delta_glue/movie_ratings/"

    spark, _ = init_spark()
    movies_df, ratings_df = read_delta_tables(spark, movies_path, ratings_path)
    curated_df = transform_data(movies_df, ratings_df)
    write_curated_table(curated_df, curated_path)

    print("Tabela curated_movie_ratings criada com sucesso!")


if __name__ == "__main__":
    main()
