from concurrent import futures
import grpc
import torch
from flask import Flask, jsonify, request
from prometheus_client import Counter, generate_latest
from transformers import AutoModelForSequenceClassification, AutoTokenizer
import inference_pb2
import inference_pb2_grpc

MODEL_NAME = "unitary/toxic-bert"
TOXIC_LABEL = "toxic"

tokenizer = None
model = None


def get_model():
    global tokenizer, model
    if tokenizer is None:
        tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
        model = AutoModelForSequenceClassification.from_pretrained(MODEL_NAME)
        model.eval()
    return tokenizer, model


def predict_toxic(text: str) -> bool:
    tokenizer, model = get_model()
    toks = tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
    with torch.no_grad():
        logits = model(**toks).logits
    idx = model.config.label2id.get(TOXIC_LABEL, 0)
    return logits[0, idx].item() > 0


app = Flask(__name__)
INFERENCE_COUNT = Counter("app_http_inference_count", "inference count")


@app.route("/predict", methods=["GET", "POST"])
def predict():
    if request.method == "POST":
        text = request.get_json(force=True)["text"]
    else:
        text = request.args["text"]
    result = predict_toxic(text)
    INFERENCE_COUNT.inc()
    return jsonify(is_toxic=result)


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": "text/plain; charset=utf-8"}


def run_http():
    get_model()
    app.run(host="0.0.0.0", port=5000)


class TextClassifierServicer(inference_pb2_grpc.TextClassifierServicer):
    def Predict(self, request, context):
        return inference_pb2.TextClassificationOutput(is_toxic=predict_toxic(request.text))


def run_grpc():
    get_model()
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=4))
    inference_pb2_grpc.add_TextClassifierServicer_to_server(
        TextClassifierServicer(), server
    )
    server.add_insecure_port("[::]:50051")
    server.start()
    server.wait_for_termination()
