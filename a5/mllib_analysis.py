from pyspark.sql import SparkSession
from pyspark.ml.feature import VectorAssembler, StringIndexer
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml import Pipeline
from pyspark.ml.evaluation import MulticlassClassificationEvaluator
import sys

# initialize session
spark = SparkSession.builder.appName("StudentDropoutPipeline").getOrCreate()

# 1st arg is csv data file
data_path = sys.argv[1]

# load data
# header = True to skip first row (header)
# inferSchema = True so spark doesnt make everything a string
df = spark.read.option("header", True).option("inferSchema", True).option("delimiter", ";").csv(data_path)

# turns target from dropout/graduate into 1/0 
df = df.withColumn("label", (df["Target"] == "Dropout").cast("int"))


# put all features into a vector
assembler = VectorAssembler(
    inputCols=[
        "Marital status",
        "Application mode",
        "Application order",
        "Course",
        "Daytime/evening attendance	",
        "Previous qualification",
        "Previous qualification (grade)",
        "Nacionality",
        "Mother's qualification",
        "Father's qualification",
        "Mother's occupation",
        "Father's occupation",
        "Admission grade",
        "Displaced",
        "Educational special needs",
        "Debtor",
        "Tuition fees up to date",
        "Gender",
        "Scholarship holder",
        "Age at enrollment",
        "International",
        "Curricular units 1st sem (credited)",
        "Curricular units 1st sem (enrolled)",
        "Curricular units 1st sem (evaluations)",
        "Curricular units 1st sem (approved)",
        "Curricular units 1st sem (grade)",
        "Curricular units 1st sem (without evaluations)",
        "Curricular units 2nd sem (credited)",
        "Curricular units 2nd sem (enrolled)",
        "Curricular units 2nd sem (evaluations)",
        "Curricular units 2nd sem (approved)",
        "Curricular units 2nd sem (grade)",
        "Curricular units 2nd sem (without evaluations)",
        "Unemployment rate",
        "Inflation rate",
        "GDP"
    ],
    outputCol="features"
)

# random forest tree (100 trees)
rf = RandomForestClassifier(labelCol="label", featuresCol="features", numTrees=100)

train_df, test_df = df.randomSplit([0.8, 0.2], seed=42)
print(f"""There are {train_df.count()} rows in the training set, and {test_df.count()} in the test set """)

# pipeline and model with training dataframe
pipeline = Pipeline(stages=[assembler, rf])
model = pipeline.fit(train_df)

#predict with test dataframe
predictions = model.transform(test_df)

# evaluate
evaluator = MulticlassClassificationEvaluator(labelCol="label", predictionCol="prediction", metricName="accuracy")
accuracy = evaluator.evaluate(predictions)

print("\n=== Model Accuracy ===")
print(f"Accuracy: {accuracy:.4f}")

#show importances with last stage in pipeline ([-1])
feature_importances = model.stages[-1].featureImportances
feature_names = assembler.getInputCols()

print("\n=== Feature Importances ===")
for i, name in enumerate(feature_names):
    print(f"{name:60}: {feature_importances[i]:.4f}")

