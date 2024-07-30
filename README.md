# Auto Centrum scraper

This project is designed to scrape car data from the Auto Centrum website, generate reports, and extract links from the reports. The project uses Ruby, HTTParty, Nokogiri, and Concurrent Ruby for HTTP requests, HTML parsing, and concurrency management.

## Getting Started

### Installation

1. Clone the repository to your local machine:

```bash
git clone https://github.com/simonwisniewski/autocentrum-scraper.git
cd autocentrum-scraper
```

2. Install the required gems:

```bash
bundle install
```

### Usage

```bash
ruby main.rb
```

### Tests and Documentation

#### To run tests

```bash
rspec
```

#### To generate documentation

```bash
rdoc --exclude reports
```
