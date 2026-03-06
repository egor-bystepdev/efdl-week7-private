# Week 07: application deployment homework

**Maximum total score**: 11.

Your task here is to implement the toxic text classification service. You can use any pre-trained model, but `unitary/toxic-bert` from huggingface works perfectly fine here. In this task, you are required to use a deep learning model. The quality of the model should pass a simple sanity check with obvious toxic/non-toxic texts.

Your code must be `uv`-installable and the source code must be inside the `src/<package_name>` directory. The package name is up to you.

**[4 points] HTTP endpoint:**
Implement a service which can handle the `POST /predict` query on port `5000`.
Request data is a JSON with the following structure:
```json
{
  "text": "<text_to_classify>"
}
```

Response data is also a JSON with the following structure:
```json
{
    "is_toxic": bool
}
```

Example:
```bash
curl -XPOST http://localhost:5000/predict -H "Content-Type: application/json" -d '{"text": "Thank you very much, have a good day <3"}'
...
{
  "is_toxic": false
}
```


**[4 points] GRPC endpoint:**
Implement a separate [gRPC](https://grpc.io/) service on the `9090` port.
See the `inference.proto` file in the `proto` directory.
The contract is the same as for the HTTP endpoint. Do not modify the protobuf structure.

**[2 points] Pytest:**

Write tests to your solution which cover at least 90% of the code in `src/` directory using pytest. Tests must reside in the `tests/` directory.

**[1 point] Metric endpoint:**
Implement a service which is able to serve its metrics in the [Prometheus format](https://prometheus.io/docs/concepts/data_model/) via `/metrics` on the `5000` port.
The most important metric for us is `app_http_inference_count`, the number of HTTP endpoint invocations.

### How to submit?

* Create a **private** copy of this repository (clone-and-push).
* Install [greater-solution-extractor-59](https://github.com/apps/greater-solution-extractor-59) to your account and authorize it to your newly created repo. **This will allow us to have access and grade your homework.**
* Put `Dockerfile` and `pyproject.toml` in the root of the repository. Dockerfile should install your package and assemble all code in your repo **and the model checkpoint** into the working service.
* When you push commits into the repo, the github actions pipeline starts and evaluates your solution. **You are not allowed to modify this pipeline and helper scripts from the `scripts/ci` folder. Otherwise, your homework would be graded as 0.**
* Any text file or comment with the link to your respository and the hash of your (possibly, partially) working commit is what you submit to LMS.

### Notes

 - You are not limited to running only one process inside docker - use `supervisord` to run as many processes as you want
 - The actual testing pipeline can be found in `.github/workflows`
