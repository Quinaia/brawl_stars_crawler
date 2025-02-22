### Ruby
```shell
bundle install
bundle exec ruby main.rb
```

### Docker
```shell
docker build -t brawl-stars .
docker run --rm --name brawl-stars -v $(pwd):/app brawl-stars
```
