from pyspark.sql import SparkSession
from pyspark.ml import Pipeline
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.regression import DecisionTreeRegressor
from pyspark.ml.evaluation import RegressionEvaluator
import sys

spark = SparkSession.builder.appName("MyApp").getOrCreate()

file_path = sys.argv[1]
df = spark.read.option("header", True).option("inferSchema", True).csv(file_path)

df_filtered = df.select(
    "passenger_count",
    "PULocationID",
    "DOLocationID",
    "total_amount"
)

df_filtered.show(10)

train_df, test_df = df_filtered.randomSplit([0.8,0.2], seed=42)

assembler = VectorAssembler(
    inputCols=["passenger_count",
               "PULocationID",
               "DOLocationID"],
    outputCol="features"
)

dt = DecisionTreeRegressor(featuresCol="features", labelCol="total_amount")

pipeline = Pipeline(stages=[assembler, dt])

model = pipeline.fit(train_df)
predictions = model.transform(test_df)

predictions.select("PULocationID", "DOLocationID", "passenger_count", "prediction").show(10)

evaluator = RegressionEvaluator(
    labelCol="total_amount",
    predictionCol="prediction",
    metricName="rmse"
)

rmse = evaluator.evaluate(predictions)
print(f"rmse: {rmse:.2f}")




