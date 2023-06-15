### Stop and Run
```
docker stop rcher && docker rm rcher && docker build -t rcher:1 . && docker run --name rcher -d -p 4000:4000 rcher:1
```

### Run
```
docker build -t rcher:1 . && docker run --name rcher -d -p 4000:4000 rcher:1
```