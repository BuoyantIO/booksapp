package main

import (
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

// we use http.Transport instead of http.Client to prevent it from automatically
// following redirects, which is required to parse the Location header.
var client = http.Transport{}

func dieIf(err error, msg string) {
	if err == nil {
		return
	}
	fmt.Fprintf(os.Stderr, "%s: %s\n", msg, err)
	os.Exit(1)
}

func locationPath(resp *http.Response) string {
	loc, err := resp.Location()
	dieIf(err, "Failed to get location")

	// if the path is "/", that's an indication that the resource already exists.
	if loc.Path == "/" {
		fmt.Fprintf(os.Stderr,
			"Delete author \"Ernest Cline\" before running this script\n")
		os.Exit(1)
	}
	return loc.Path
}

func authorId(authorPath string) string {
	parts := strings.Split(authorPath, "/")
	return parts[len(parts)-1]
}

func roundTrip(method, urlStr, host string, body io.Reader, prepare func(req *http.Request)) (resp *http.Response, err error) {
	t := time.Now()
	var req *http.Request
	defer func() { drainAndCloseAndLog(method, urlStr, resp, err, t) }()

	req, err = http.NewRequest(method, urlStr, body)
	req.Host = host
	if err == nil {
		prepare(req)
		resp, err = client.RoundTrip(req)
	}

	return
}

func drainAndCloseAndLog(method, urlStr string, resp *http.Response, err error, t time.Time) {
	if resp != nil {
		io.Copy(ioutil.Discard, resp.Body)
		resp.Body.Close()
	}

	if resp == nil || err != nil {
		fmt.Printf("ERR\t%s\t%s\t%v\n", method, urlStr, err)
	} else {
		fmt.Printf("%s\t%d\t%s\t%s\n", time.Since(t), resp.StatusCode, method, urlStr)
	}
}

func main() {
	var err error
	var resp *http.Response
	var authorPath, bookPath string

	var sleep = flag.Duration("sleep", 100*time.Millisecond, "time to sleep between requests")
	var initialDelay = flag.Duration("initial-delay", time.Minute, "time to sleep before starting traffic")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: simulate-traffic [options] <target>\n")
		fmt.Fprintf(os.Stderr, "       where <target> is host:port of web service, and [options] include:\n")
		flag.PrintDefaults()
	}

	flag.Parse()

	if flag.NArg() != 1 {
		flag.Usage()
		os.Exit(1)
	}

	host := "http://" + flag.Arg(0)
	if _, err = url.Parse(host); err != nil {
		fmt.Fprintf(os.Stderr, "Invalid target: %s\n", flag.Arg(0))
		flag.Usage()
		os.Exit(1)
	}

	hostHeader := flag.Arg(0)

	time.Sleep(*initialDelay)

	get := func(path string) (resp *http.Response, err error) {
		resp, err = roundTrip("GET", host+path, hostHeader, nil, func(req *http.Request) {})
		time.Sleep(*sleep)
		return
	}

	// Retries automatically on 5XX errors
	post := func(path string) (resp *http.Response, err error) {
		for {
			resp, err = roundTrip("POST", host+path, hostHeader, nil, func(req *http.Request) {})
			time.Sleep(*sleep)
			if err != nil || resp.StatusCode == http.StatusSeeOther {
				break
			}
		}
		return
	}

	// Retries automatically on 5XX errors
	postForm := func(path string, data url.Values) (resp *http.Response, err error) {
		for {
			resp, err = roundTrip("POST", host+path, hostHeader, strings.NewReader(data.Encode()), func(req *http.Request) {
				req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
			})
			time.Sleep(*sleep)
			if err != nil || resp.StatusCode == http.StatusSeeOther {
				break
			}
		}
		return
	}

	// reset database before starting
	for {
		resp, err = get("/reset")
		if err == nil && resp.StatusCode == http.StatusNoContent {
			break
		}
	}

	// Infinite loop! Just ctrl-C when you've had enough.
	// But don't stop 'til you get enough.
	for {

		// fetch the homepage
		get("/")

		// create an author
		resp, err = postForm("/authors", url.Values{
			"first_name": {"Ernest"},
			"last_name":  {"Cline"},
		})
		dieIf(err, "Failed to create author")
		authorPath = locationPath(resp)

		// get the author
		get(authorPath)

		// create a book
		resp, err = postForm("/books", url.Values{
			"title":     {"Ready Player One"},
			"author_id": {authorId(authorPath)},
			"pages":     {"345"},
		})
		dieIf(err, "Failed to create book")
		bookPath = locationPath(resp)

		// get the book
		get(bookPath)

		// create another book
		resp, err = postForm("/books", url.Values{
			"title":     {"Ready Player Two"},
			"author_id": {authorId(authorPath)},
			"pages":     {"456"},
		})
		dieIf(err, "Failed to create book")
		bookPath = locationPath(resp)

		// get the book
		get(bookPath)

		// edit the book
		resp, err = postForm(bookPath+"/edit", url.Values{
			"title":     {"Ready Player Three"},
			"author_id": {authorId(authorPath)},
			"pages":     {"567"},
		})
		dieIf(err, "Failed to edit book")

		// delete the book
		resp, err = post(bookPath + "/delete")
		dieIf(err, "Failed to delete book")

		// delete the author
		resp, err = post(authorPath + "/delete")
		dieIf(err, "Failed to delete author")
	}
}
