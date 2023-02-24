### Build and run this static web site locally

```
git clone --recurse-submodules https://github.com/mathieu-benoit/acm-workshop
cd acm-workshop/app
docker build -t acm-workshop .
docker run -d \
    -p 80:8080 \
    --cap-drop=ALL \
    --read-only \
    --tmpfs /tmp \
    acm-workshop
```
